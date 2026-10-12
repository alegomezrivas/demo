import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:flutter/material.dart';

/// Live preferences: the app rebuilds when they change.
class AppPreferences extends ChangeNotifier {
  /// Creates the holder with [initial] settings.
  AppPreferences([AppSettings initial = AppSettings.defaults])
    : _settings = initial;

  AppSettings _settings;

  /// Current settings.
  AppSettings get settings => _settings;

  /// Theme mode for `MaterialApp`.
  ThemeMode get themeMode => switch (_settings.themeMode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };

  /// Forced locale, or null to follow the device.
  Locale? get locale {
    final code = _settings.language.code;
    return code == null ? null : Locale(code);
  }

  /// Whether sensitive actions need biometric confirmation.
  bool get biometricConfirmation => _settings.biometricConfirmation;

  /// Replaces the settings and notifies listeners when they changed.
  void apply(AppSettings next) {
    if (next == _settings) return;
    _settings = next;
    notifyListeners();
  }
}
