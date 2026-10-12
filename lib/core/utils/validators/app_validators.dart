import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:reactive_forms/reactive_forms.dart';

/// Reusable validators for `reactive_forms`.
///
/// Every validator treats an empty value as valid (combine with [required]),
/// so optional fields can reuse them.
abstract final class AppValidators {
  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );
  static final RegExp _phoneSeparators = RegExp(r'[\s\-().]');
  static final RegExp _phone = RegExp(r'^\+?[0-9]{7,15}$');

  /// Minimum password length enforced by [strongPassword].
  static const int minPasswordLength = 8;

  /// Fails when the value is null, blank or an empty collection.
  static final Validator<dynamic> required = Validators.delegate((control) {
    final value = control.value;
    final isEmpty =
        value == null ||
        (value is String && value.trim().isEmpty) ||
        (value is Iterable<dynamic> && value.isEmpty);
    return isEmpty ? {ValidationKeys.required: true} : null;
  });

  /// Fails when the value is not a syntactically valid e-mail address.
  static final Validator<dynamic> email = Validators.delegate((control) {
    final value = _text(control);
    if (value.isEmpty) return null;
    final valid = value.length <= 254 && _email.hasMatch(value);
    return valid ? null : {ValidationKeys.email: true};
  });

  /// Fails unless the password has 8+ chars, upper, lower, digit and symbol.
  static final Validator<dynamic> strongPassword = Validators.delegate((
    control,
  ) {
    final value = control.value;
    if (value is! String || value.isEmpty) return null;
    final missing = <String>[
      if (value.length < minPasswordLength) 'length',
      if (!value.contains(RegExp('[A-Z]'))) 'uppercase',
      if (!value.contains(RegExp('[a-z]'))) 'lowercase',
      if (!value.contains(RegExp('[0-9]'))) 'digit',
      if (!value.contains(RegExp('[^A-Za-z0-9]'))) 'symbol',
    ];
    return missing.isEmpty ? null : {ValidationKeys.strongPassword: missing};
  });

  /// Fails when the value is not a 7-15 digit phone number (optional `+`).
  static final Validator<dynamic> phone = Validators.delegate((control) {
    final value = _text(control).replaceAll(_phoneSeparators, '');
    if (value.isEmpty) return null;
    return _phone.hasMatch(value) ? null : {ValidationKeys.phone: true};
  });

  /// Fails when two controls of a group differ; the error lands on [matchName].
  static Validator<dynamic> mustMatch(String controlName, String matchName) =>
      Validators.mustMatch(controlName, matchName);

  static String _text(AbstractControl<dynamic> control) {
    final value = control.value;
    return value is String ? value.trim() : '';
  }
}
