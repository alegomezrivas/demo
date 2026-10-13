/// Pure-Dart input rules shared by the use cases and the form validators.
///
/// They mirror the backend contract (`backend/docs/api-contract.md`) so a
/// request that would be rejected is never sent.
abstract final class AuthRules {
  /// Number of digits of the e-mail confirmation code.
  static const int codeLength = 6;

  /// Shortest accepted password.
  static const int minPasswordLength = 8;

  /// Longest accepted password.
  static const int maxPasswordLength = 128;

  /// Shortest accepted username.
  static const int minUsernameLength = 3;

  /// Longest accepted username.
  static const int maxUsernameLength = 30;

  /// Longest accepted display name.
  static const int maxNameLength = 100;

  /// Largest profile picture the server accepts, in bytes.
  static const int maxAvatarBytes = 200 * 1024;

  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?"
    r'(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$',
  );
  static final RegExp _username = RegExp(
    r'^[a-z0-9_][a-z0-9._]{1,28}[a-z0-9_]$',
  );
  static final RegExp _code = RegExp('^[0-9]{$codeLength}\$');

  /// True for a plausible e-mail address (at most 254 characters).
  static bool isValidEmail(String value) =>
      value.length <= 254 && _email.hasMatch(value);

  /// True for a username the server would accept, after lower-casing.
  ///
  /// Letters, digits, dots and underscores; 3-30 characters; no dot at either
  /// end.
  static bool isValidUsername(String value) =>
      _username.hasMatch(value.toLowerCase());

  /// True for exactly [codeLength] digits.
  static bool isValidCode(String value) => _code.hasMatch(value);

  /// Names the password rules that [value] breaks (empty when it is strong).
  static List<String> passwordProblems(String value) => [
    if (value.length < minPasswordLength) 'length',
    if (value.length > maxPasswordLength) 'max_length',
    if (!value.contains(RegExp('[A-Z]'))) 'uppercase',
    if (!value.contains(RegExp('[a-z]'))) 'lowercase',
    if (!value.contains(RegExp('[0-9]'))) 'digit',
    if (!value.contains(RegExp('[^A-Za-z0-9]'))) 'symbol',
  ];
}
