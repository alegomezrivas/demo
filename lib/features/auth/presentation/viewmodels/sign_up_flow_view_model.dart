import 'dart:async';
import 'dart:typed_data';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:demo/features/auth/domain/usecases/check_username_availability_use_case.dart';
import 'package:demo/features/auth/domain/usecases/complete_sign_up_use_case.dart';
import 'package:demo/features/auth/domain/usecases/send_confirmation_code_use_case.dart';
import 'package:demo/features/auth/domain/usecases/upload_avatar_use_case.dart';
import 'package:demo/features/auth/domain/usecases/verify_confirmation_code_use_case.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/models/sign_up_state.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:demo/features/auth/presentation/models/username_status.dart';
import 'package:demo/features/auth/presentation/services/resend_countdown.dart';
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// ViewModel shared by every sign-up step.
///
/// One instance lives for the whole flow (the views do not dispose it): the
/// text being typed sits in [forms], everything else in the immutable [state],
/// and the work is done by use cases. It only moves forward through
/// [SignUpProgress], which the route guard also reads.
class SignUpFlowViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  ///
  /// The durations are parameters so tests do not have to wait.
  SignUpFlowViewModel({
    required SendConfirmationCodeUseCase sendCode,
    required VerifyConfirmationCodeUseCase verifyCode,
    required CheckUsernameAvailabilityUseCase checkUsername,
    required CompleteSignUpUseCase completeSignUp,
    required UploadAvatarUseCase uploadAvatar,
    required NavigationService navigation,
    required SessionService session,
    required SignUpProgress progress,
    required ScreenProtection screenProtection,
    this.usernameDebounce = defaultUsernameDebounce,
    int resendCooldownSeconds = defaultResendCooldownSeconds,
    Duration resendTick = const Duration(seconds: 1),
  }) : _sendCode = sendCode,
       _verifyCode = verifyCode,
       _checkUsername = checkUsername,
       _completeSignUp = completeSignUp,
       _uploadAvatar = uploadAvatar,
       _navigation = navigation,
       _session = session,
       _progress = progress,
       _screenProtection = screenProtection {
    _countdown = ResendCountdown(
      onChanged: notifyListeners,
      seconds: resendCooldownSeconds,
      tick: resendTick,
    );
    _forms = _createForms();
  }

  /// Wait after the last keystroke before asking whether a username is free.
  static const Duration defaultUsernameDebounce = Duration(milliseconds: 500);

  /// Wait before a new code can be requested; matches the server.
  static const int defaultResendCooldownSeconds = 30;

  /// Wait after the last keystroke before checking the username.
  final Duration usernameDebounce;

  final SendConfirmationCodeUseCase _sendCode;
  final VerifyConfirmationCodeUseCase _verifyCode;
  final CheckUsernameAvailabilityUseCase _checkUsername;
  final CompleteSignUpUseCase _completeSignUp;
  final UploadAvatarUseCase _uploadAvatar;
  final NavigationService _navigation;
  final SessionService _session;
  final SignUpProgress _progress;
  final ScreenProtection _screenProtection;

  late final ResendCountdown _countdown;
  late SignUpForms _forms;
  SignUpState _state = const SignUpState();
  Timer? _usernameTimer;
  StreamSubscription<Object?>? _usernameSubscription;
  int _usernameRequest = 0;
  String _lastUsername = '';
  bool _rememberSession = true;

  /// The forms of the steps.
  SignUpForms get forms => _forms;

  /// Shared, immutable state.
  SignUpState get state => _state;

  /// Last failure of the current step, if any.
  Failure? get failure => _state.failure;

  /// Seconds before a new code can be requested (zero when it can).
  int get resendSecondsLeft => _countdown.secondsLeft;

  /// Whether a new code can be requested now.
  bool get canResendCode => !_countdown.isActive && !isBusy;

  // ---- Flow control -------------------------------------------------------

  /// Starts a fresh sign-up and opens the first step.
  void start() {
    reset();
    _progress.unlock(SignUpStep.email);
    unawaited(_navigation.push<void>(SignUpStep.email.route));
  }

  /// Forgets everything typed or confirmed so far.
  void reset() {
    _usernameTimer?.cancel();
    _usernameRequest++;
    _lastUsername = '';
    _countdown.cancel();
    unawaited(_usernameSubscription?.cancel());
    _forms.dispose();
    _forms = _createForms();
    _state = const SignUpState();
    _rememberSession = true;
    _progress.clear();
    notifyListeners();
  }

  /// Goes back one step.
  void back() => _navigation.pop();

  /// Opens the sign-in screen.
  void goToLogin() => _navigation.go(AppRoutes.login);

  /// Opens the terms and policies text.
  void openTerms() => unawaited(_navigation.push<void>(AppRoutes.terms));

  /// Hides the screen from captures while the password is typed.
  Future<void> protectScreen({required bool enabled}) async {
    try {
      await (enabled
          ? _screenProtection.enable()
          : _screenProtection.disable());
    } on Exception {
      // Protection is best effort; the step must stay usable without it.
    }
  }

  // ---- Steps --------------------------------------------------------------

  /// Step 1: sends the confirmation code.
  Future<void> submitEmail() async {
    if (isBusy || !_validate(_forms.email)) return;
    final email = SignUpForms.textOf(
      _forms.email,
      SignUpForms.emailField,
    ).trim();

    // Coming back to a confirmed step with the same address needs no new code.
    if (email == _state.email && _progress.canEnter(SignUpStep.code)) {
      _advance(SignUpStep.code);
      return;
    }

    final failed = await _run(() async {
      final result = await _sendCode(SendCodeParams(email: email));
      return result.fold((failure) => failure, (_) => null);
    });
    if (failed != null) return;

    _state = _state.copyWith(
      email: email,
      clearVerificationToken: true,
      clearFailure: true,
    );
    _forms.code.reset();
    _progress.rewindTo(SignUpStep.email);
    _countdown.start();
    _advance(SignUpStep.code);
  }

  /// Step 2: checks the code. Also called when the sixth digit is typed.
  Future<void> submitCode() async {
    if (isBusy || !_validate(_forms.code)) return;
    final code = SignUpForms.textOf(_forms.code, SignUpForms.codeField);

    String? token;
    final failed = await _run(() async {
      final result = await _verifyCode(
        VerifyCodeParams(email: _state.email, code: code),
      );
      return result.fold((failure) => failure, (value) {
        token = value;
        return null;
      });
    });
    if (failed != null) {
      // A wrong code is not worth keeping; the person types it again.
      _forms.code.reset();
      return;
    }

    _state = _state.copyWith(verificationToken: token, clearFailure: true);
    _advance(SignUpStep.password);
  }

  /// "I did not get the code": asks for a new one once the wait is over.
  Future<void> resendCode() async {
    if (!canResendCode) return;
    final failed = await _run(() async {
      final result = await _sendCode(
        SendCodeParams(email: _state.email, isResend: true),
      );
      return result.fold((failure) => failure, (_) => null);
    });
    if (failed != null) {
      // The server may still be counting (e.g. after a restart): wait again.
      if (failed.code == 'resend_too_soon') _countdown.start();
      return;
    }
    _forms.code.reset();
    _state = _state.copyWith(clearFailure: true);
    _countdown.start();
  }

  /// Step 3: keeps the password (in memory only) and asks for the name.
  void submitPassword() {
    if (isBusy || !_validate(_forms.password)) return;
    final remember = _forms.password.control(SignUpForms.rememberField).value;
    _rememberSession = remember is! bool || remember;
    _advance(SignUpStep.name);
  }

  /// Step 4: keeps the name and asks for the username.
  void submitName() {
    if (isBusy || !_validate(_forms.name)) return;
    _advance(SignUpStep.username);
  }

  /// Step 5: needs a username that is not known to be taken.
  Future<void> submitUsername() async {
    if (isBusy || !_validate(_forms.username)) return;
    _usernameTimer?.cancel();
    if (_state.usernameStatus != UsernameStatus.available &&
        _state.usernameStatus != UsernameStatus.unknown) {
      await _checkNow();
    }
    final status = _state.usernameStatus;
    // `unknown` (the check failed) is allowed through: registration enforces
    // uniqueness anyway and reports `username_taken`.
    if (status == UsernameStatus.available ||
        status == UsernameStatus.unknown) {
      _advance(SignUpStep.terms);
    }
  }

  /// Step 6: accepting the terms creates the account and signs in.
  Future<void> acceptTerms() async {
    if (isBusy) return;
    final token = _state.verificationToken;
    if (token == null) {
      _restartFromEmail(const ServerFailure('invalid_verification_token'));
      return;
    }

    final failed = await _run(() async {
      final result = await _completeSignUp(
        CompleteSignUpParams(
          verificationToken: token,
          name: SignUpForms.textOf(_forms.name, SignUpForms.nameField),
          username: SignUpForms.textOf(
            _forms.username,
            SignUpForms.usernameField,
          ),
          password: SignUpForms.textOf(
            _forms.password,
            SignUpForms.passwordField,
          ),
          rememberSession: _rememberSession,
        ),
      );
      return result.fold((failure) => failure, (user) {
        _state = _state.copyWith(user: user);
        return null;
      });
    });
    if (failed != null) {
      _onAccountFailure(failed);
      return;
    }

    // The password and the proof are no longer needed: drop them right away.
    _forms.password.control(SignUpForms.passwordField).value = null;
    _state = _state.copyWith(clearVerificationToken: true, clearFailure: true);
    _progress
      ..lockBeforeAvatar()
      ..unlock(SignUpStep.avatar);
    // `go` replaces the stack: there is nothing to come back to.
    _navigation.go(SignUpStep.avatar.route);
    notifyListeners();
  }

  /// Step 7: uploads the (already cropped and compressed) picture.
  Future<void> submitAvatar(Uint8List jpeg) async {
    if (isBusy) return;
    final failed = await _run(() async {
      final result = await _uploadAvatar(jpeg);
      return result.fold((failure) => failure, (user) {
        _state = _state.copyWith(user: user);
        return null;
      });
    });
    if (failed != null) return;
    _goToDone();
  }

  /// Step 7 alternative: continue without a picture.
  void skipAvatar() => _goToDone();

  /// Last step: enters the app.
  void finish() {
    _session.markSignedIn(persistent: _rememberSession);
    _navigation.go(AppRoutes.home);
    reset();
  }

  // ---- Username check -----------------------------------------------------

  /// Re-evaluates the username after the text changed (debounced).
  void onUsernameChanged(String? value) {
    final text = (value ?? '').trim();
    // The form reports changes asynchronously; one already handled (for
    // example by `submitUsername`) must not cancel its own check.
    if (text == _lastUsername) return;
    _lastUsername = text;
    _usernameTimer?.cancel();
    // Any answer still on its way belongs to text that is gone.
    _usernameRequest++;
    if (text.isEmpty) {
      _setUsernameStatus(UsernameStatus.idle);
      return;
    }
    if (!AuthRules.isValidUsername(text)) {
      _setUsernameStatus(UsernameStatus.invalid);
      return;
    }
    _setUsernameStatus(UsernameStatus.checking);
    _usernameTimer = Timer(usernameDebounce, () => unawaited(_checkNow()));
  }

  Future<void> _checkNow() async {
    final text = SignUpForms.textOf(
      _forms.username,
      SignUpForms.usernameField,
    ).trim();
    if (!AuthRules.isValidUsername(text)) {
      _setUsernameStatus(UsernameStatus.invalid);
      return;
    }
    _lastUsername = text;
    final request = ++_usernameRequest;
    _setUsernameStatus(UsernameStatus.checking);
    final result = await _checkUsername(text);
    // An answer for text that is no longer in the field must be ignored.
    if (request != _usernameRequest) return;
    _setUsernameStatus(
      result.fold(
        (_) => UsernameStatus.unknown,
        (available) =>
            available ? UsernameStatus.available : UsernameStatus.taken,
      ),
    );
  }

  void _setUsernameStatus(UsernameStatus status) {
    if (status != UsernameStatus.checking) _usernameRequest++;
    if (_state.usernameStatus == status) return;
    _state = _state.copyWith(usernameStatus: status);
    notifyListeners();
  }

  // ---- Helpers ------------------------------------------------------------

  SignUpForms _createForms() {
    final forms = SignUpForms();
    _usernameSubscription = forms.username
        .control(SignUpForms.usernameField)
        .valueChanges
        .listen((value) => onUsernameChanged(value as String?));
    return forms;
  }

  bool _validate(FormGroup group) {
    if (group.valid) return true;
    group.markAllAsTouched();
    notifyListeners();
    return false;
  }

  /// Runs [action] with the busy flag on; returns its failure, if any, after
  /// storing it in the state.
  Future<Failure?> _run(Future<Failure?> Function() action) async {
    _state = _state.copyWith(clearFailure: true);
    setBusy(true);
    final failure = await action();
    if (failure != null) _state = _state.copyWith(failure: failure);
    setBusy(false);
    return failure;
  }

  void _advance(SignUpStep step) {
    _progress.unlock(step);
    unawaited(_navigation.push<void>(step.route));
    notifyListeners();
  }

  void _goToDone() {
    _progress.unlock(SignUpStep.done);
    _navigation.go(SignUpStep.done.route);
    notifyListeners();
  }

  void _onAccountFailure(Failure failure) {
    switch (failure.code) {
      case 'username_taken':
        _state = _state.copyWith(usernameStatus: UsernameStatus.taken);
        // The terms step sits on top of the username step.
        _navigation.pop();
        notifyListeners();
      case 'invalid_verification_token' || 'email_taken':
        _restartFromEmail(failure);
      default:
        notifyListeners();
    }
  }

  /// The confirmation is gone (expired or the address got registered): the
  /// person has to confirm an e-mail again.
  void _restartFromEmail(Failure failure) {
    _state = _state.copyWith(clearVerificationToken: true, failure: failure);
    _progress.rewindTo(SignUpStep.email);
    _navigation.go(SignUpStep.email.route);
    notifyListeners();
  }

  @override
  void dispose() {
    _usernameTimer?.cancel();
    _countdown.cancel();
    unawaited(_usernameSubscription?.cancel());
    _forms.dispose();
    super.dispose();
  }
}
