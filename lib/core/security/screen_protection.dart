/// Hides sensitive content from screenshots and the app-switcher preview.
abstract interface class ScreenProtection {
  /// Turns protection on (call when a sensitive screen appears).
  Future<void> enable();

  /// Turns protection off (call when leaving the sensitive screen).
  Future<void> disable();
}
