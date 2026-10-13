import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Validators specific to the sign-up steps; like the shared ones, an empty
/// value is valid so they combine with `AppValidators.required`.
abstract final class SignUpValidators {
  /// Fails unless the value is exactly six digits (the e-mail code).
  static final Validator<dynamic> code = Validators.delegate((control) {
    final value = _text(control);
    if (value.isEmpty) return null;
    return AuthRules.isValidCode(value) ? null : {ValidationKeys.code: true};
  });

  /// Fails when the value is not an acceptable username.
  static final Validator<dynamic> username = Validators.delegate((control) {
    final value = _text(control);
    if (value.isEmpty) return null;
    return AuthRules.isValidUsername(value)
        ? null
        : {ValidationKeys.username: true};
  });

  static String _text(AbstractControl<dynamic> control) {
    final value = control.value;
    return value is String ? value.trim() : '';
  }
}
