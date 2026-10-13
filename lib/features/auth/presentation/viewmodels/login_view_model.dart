import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/utils/validators/app_validators.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the sign-in screen.
class LoginViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  LoginViewModel({
    required LoginUseCase login,
    required NavigationService navigation,
    required SessionService session,
    required ScreenProtection screenProtection,
  }) : _login = login,
       _navigation = navigation,
       _session = session,
       _screenProtection = screenProtection;

  /// Name of the e-mail control.
  static const String emailField = 'email';

  /// Name of the password control.
  static const String passwordField = 'password';

  /// Name of the "remember me" control.
  static const String rememberField = 'rememberSession';

  final LoginUseCase _login;
  final NavigationService _navigation;
  final SessionService _session;
  final ScreenProtection _screenProtection;

  final FormControl<String> _email = FormControl<String>(
    validators: [AppValidators.required, AppValidators.email],
  );
  final FormControl<String> _password = FormControl<String>(
    validators: [AppValidators.required],
  );

  /// The sign-in form.
  late final FormGroup form = FormGroup({
    emailField: _email,
    passwordField: _password,
    rememberField: FormControl<bool>(value: true),
  });

  bool _obscurePassword = true;
  Failure? _failure;

  /// Whether the password is hidden.
  bool get obscurePassword => _obscurePassword;

  /// Last failure returned by the backend, if any.
  Failure? get failure => _failure;

  /// Protects the screen from captures while credentials are typed.
  Future<void> init() async {
    try {
      await _screenProtection.enable();
    } on Exception {
      // Protection is best effort; the screen must stay usable without it.
    }
  }

  /// Shows or hides the password.
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Validates the form and signs in.
  Future<void> submit() async {
    if (isBusy) return;
    if (form.invalid) {
      form.markAllAsTouched();
      notifyListeners();
      return;
    }

    _failure = null;
    setBusy(true);
    final remember = form.control(rememberField).value;
    final rememberSession = remember is bool && remember;
    final result = await _login(
      LoginParams(
        email: _email.value ?? '',
        password: _password.value ?? '',
        rememberSession: rememberSession,
      ),
    );
    setBusy(false);

    result.fold((failure) {
      _failure = failure;
      notifyListeners();
    }, (_) => _onSignedIn(persistent: rememberSession));
  }

  /// Opens the welcome screen, where an account can be created.
  void goToWelcome() => _navigation.go(AppRoutes.welcome);

  void _onSignedIn({required bool persistent}) {
    _session.markSignedIn(persistent: persistent);
    _navigation.go(AppRoutes.home);
  }

  @override
  void dispose() {
    unawaited(_screenProtection.disable().catchError((Object _) {}));
    form.dispose();
    super.dispose();
  }
}
