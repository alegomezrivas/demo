import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:meta/meta.dart';

/// User preferences.
@immutable
class AppSettings {
  /// Creates settings.
  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.language = AppLanguage.system,
    this.biometricConfirmation = false,
  });

  /// Settings used before the user changes anything.
  static const AppSettings defaults = AppSettings();

  /// Light / dark / system.
  final AppThemeMode themeMode;

  /// Interface language.
  final AppLanguage language;

  /// Whether sensitive actions require biometric confirmation.
  final bool biometricConfirmation;

  /// Returns a copy with the given fields replaced.
  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    bool? biometricConfirmation,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      biometricConfirmation:
          biometricConfirmation ?? this.biometricConfirmation,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AppSettings &&
      other.themeMode == themeMode &&
      other.language == language &&
      other.biometricConfirmation == biometricConfirmation;

  @override
  int get hashCode => Object.hash(themeMode, language, biometricConfirmation);
}
