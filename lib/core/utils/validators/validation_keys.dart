/// Error keys produced by the validators (shared with the message map).
abstract final class ValidationKeys {
  /// Value is missing.
  static const String required = 'required';

  /// Value is not a valid e-mail address.
  static const String email = 'email';

  /// Password does not satisfy the strength policy.
  static const String strongPassword = 'strongPassword';

  /// Value is shorter than required (reactive_forms built-in).
  static const String minLength = 'minLength';

  /// Value is longer than allowed (reactive_forms built-in).
  static const String maxLength = 'maxLength';

  /// Two controls differ (reactive_forms built-in).
  static const String mustMatch = 'mustMatch';
}
