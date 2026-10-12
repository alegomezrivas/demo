/// Theme preference, independent from Flutter.
enum AppThemeMode {
  /// Follow the operating system.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark;

  /// Parses a stored name; unknown values fall back to [system].
  static AppThemeMode parse(String value) => AppThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AppThemeMode.system,
  );
}
