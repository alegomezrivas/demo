import 'package:demo/core/utils/validators/app_validators.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_validators.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// One `FormGroup` per sign-up step, created together and disposed together.
class SignUpForms {
  /// Creates the forms, all empty ("remember me" starts checked).
  SignUpForms();

  /// Name of the e-mail control.
  static const String emailField = 'email';

  /// Name of the code control.
  static const String codeField = 'code';

  /// Name of the password control.
  static const String passwordField = 'password';

  /// Name of the "remember me" control.
  static const String rememberField = 'rememberSession';

  /// Name of the full-name control.
  static const String nameField = 'name';

  /// Name of the username control.
  static const String usernameField = 'username';

  /// Step: e-mail address.
  final FormGroup email = FormGroup({
    emailField: FormControl<String>(
      validators: [AppValidators.required, AppValidators.email],
    ),
  });

  /// Step: six-digit code.
  final FormGroup code = FormGroup({
    codeField: FormControl<String>(
      validators: [AppValidators.required, SignUpValidators.code],
    ),
  });

  /// Step: password and "remember me".
  final FormGroup password = FormGroup({
    passwordField: FormControl<String>(
      validators: [AppValidators.required, AppValidators.strongPassword],
    ),
    rememberField: FormControl<bool>(value: true),
  });

  /// Step: full name.
  final FormGroup name = FormGroup({
    nameField: FormControl<String>(
      validators: [
        AppValidators.required,
        Validators.maxLength(AuthRules.maxNameLength),
      ],
    ),
  });

  /// Step: username.
  final FormGroup username = FormGroup({
    usernameField: FormControl<String>(
      validators: [AppValidators.required, SignUpValidators.username],
    ),
  });

  /// Typed text of [group]'s [field], or an empty string.
  static String textOf(FormGroup group, String field) {
    final value = group.control(field).value;
    return value is String ? value : '';
  }

  /// Releases the controls.
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    name.dispose();
    username.dispose();
  }
}
