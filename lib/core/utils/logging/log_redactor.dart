/// Removes sensitive values from text before it reaches the logs.
abstract final class LogRedactor {
  /// Replacement used for hidden values.
  static const String mask = '***';

  static final RegExp _bearer = RegExp(
    r'(bearer\s+)[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  static final RegExp _keyValue = RegExp(
    '(password|passwd|token|secret|authorization|refreshToken|accessToken|'
    r'apikey|api_key)(["\x27]?\s*[:=]\s*["\x27]?)[^"\x27,\s}&]+',
    caseSensitive: false,
  );

  /// Masks bearer tokens and `key: value` pairs of sensitive keys in [text].
  static String redact(String text) {
    return text
        .replaceAllMapped(_bearer, (m) => '${m[1]}$mask')
        .replaceAllMapped(_keyValue, (m) => '${m[1]}${m[2]}$mask');
  }
}
