import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/utils/validators/app_validators.dart';
import 'package:demo/features/auth/domain/usecases/register_use_case.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:stacked/stacked.dart';

/// ViewModel of the sign-up screen.
class RegisterViewModel extends BaseViewModel {
  /// Creates the ViewModel with its dependencies.
  RegisterViewModel({
    required this._register,
    required this._navigation,
    required this._session,
    required this._screenProtection,
  });

  /// Name of the display-name control.
  static const String nameField = 'name';

  /// Name of the e-mail control.
  static const String emailField = 'email';

  /// Name of the phone control.
  static const String phoneField = 'phone';

  /// Name of the password control.
  static const String passwordField = 'password';

  /// Name of the password confirmation control.
  static const String confirmPasswordField = 'confirmPassword';

  /// Minimum length of the display name.
  static const int minNameLength = 2;

  final RegisterUseCase _register;
  final NavigationService _navigation;
  final SessionService _session;
  final ScreenProtection _screenProtection;

  /// The sign-up form.
  late final FormGroup form = FormGroup(
    {
      nameField: FormControl<String>(
        validators: [
          AppValidators.required,
          Validators.minLength(minNameLength),
        ],
      ),
      emailField: FormControl<String>(
        validators: [AppValidators.required, AppValidators.email],
      ),
      phoneField: FormControl<String>(validators: [AppValidators.phone]),
      passwordField: FormControl<String>(
        validators: [AppValidators.required, AppValidators.strongPassword],
      ),
      confirmPasswordField: FormControl<String>(
        validators: [AppValidators.required],
      ),
    },
    validators: [AppValidators.mustMatch(passwordField, confirmPasswordField)],
  );

  bool _obscurePassword = true;
  Failure? _failure;

  /// Whether the password fields are hidden.
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

  /// Shows or hides the password fields.
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Validates the form and creates the account.
  Future<void> submit() async {
    if (isBusy) return;
    if (form.invalid) {
      form.markAllAsTouched();
      notifyListeners();
      return;
    }

    _failure = null;
    setBusy(true);
    final result = await _register(
      RegisterParams(
        name: _value(nameField),
        email: _value(emailField),
        password: _value(passwordField),
        phone: _value(phoneField).isEmpty ? null : _value(phoneField),
      ),
    );
    setBusy(false);

    result.fold((failure) {
      _failure = failure;
      notifyListeners();
    }, (_) => _onSignedIn());
  }

  /// Returns to the sign-in screen.
  void goToLogin() {
    if (_navigation.canPop) {
      _navigation.pop<void>();
    } else {
      _navigation.go(AppRoutes.login);
    }
  }

  String _value(String field) => form.control(field).value?.toString() ?? '';

  void _onSignedIn() {
    _session.markSignedIn();
    _navigation.go(AppRoutes.home);
  }

  @override
  void dispose() {
    unawaited(_screenProtection.disable().catchError((Object _) {}));
    form.dispose();
    super.dispose();
  }
}
