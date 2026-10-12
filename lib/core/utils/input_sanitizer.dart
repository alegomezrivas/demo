/// Cleans user input before it is sent to the backend.
///
/// Sanitizing complements (never replaces) form validation and server-side checks.
abstract final class InputSanitizer {
  static final RegExp _controlChars = RegExp(
    r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]',
  );
  static final RegExp _htmlTags = RegExp('<[^>]*>');
  static final RegExp _nonPhone = RegExp('[^0-9+]');

  /// Trims [input], drops control characters and HTML tags and caps its length.
  static String text(String input, {int maxLength = 500}) {
    final cleaned = input
        .replaceAll(_controlChars, '')
        .replaceAll(_htmlTags, '')
        .trim();
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  /// Lower-cases and trims an e-mail address.
  static String email(String input) =>
      text(input, maxLength: 254).toLowerCase();

  /// Keeps digits and a single leading `+`.
  static String phone(String input) {
    final stripped = input.replaceAll(_nonPhone, '');
    final hasPlus = stripped.startsWith('+');
    final digits = stripped.replaceAll('+', '');
    return hasPlus ? '+$digits' : digits;
  }
}
