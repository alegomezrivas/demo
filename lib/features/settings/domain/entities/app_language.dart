/// Language preference.
enum AppLanguage {
  /// Follow the device language (Spanish when unsupported).
  system(null),

  /// Spanish.
  spanish('es'),

  /// English.
  english('en');

  AppLanguage(this.code);

  /// ISO 639-1 code, or null to follow the system.
  final String? code;

  /// Parses a stored name; unknown values fall back to [system].
  static AppLanguage parse(String value) => AppLanguage.values.firstWhere(
    (language) => language.name == value,
    orElse: () => AppLanguage.system,
  );
}
