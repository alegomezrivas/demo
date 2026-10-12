import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/features/settings/presentation/utils/settings_labels.dart';
import 'package:demo/l10n/app_localizations_en.dart';
import 'package:demo/l10n/app_localizations_es.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppPreferences', () {
    test('starts with the given settings', () {
      final preferences = AppPreferences(
        const AppSettings(
          themeMode: AppThemeMode.dark,
          language: AppLanguage.english,
        ),
      );

      expect(preferences.themeMode, ThemeMode.dark);
      expect(preferences.locale, const Locale('en'));
    });

    test('follows the system by default', () {
      final preferences = AppPreferences();

      expect(preferences.themeMode, ThemeMode.system);
      expect(preferences.locale, isNull);
      expect(preferences.biometricConfirmation, isFalse);
    });

    test('maps every theme mode', () {
      final preferences = AppPreferences()
        ..apply(const AppSettings(themeMode: AppThemeMode.light));
      expect(preferences.themeMode, ThemeMode.light);
      preferences.apply(AppSettings.defaults);
      expect(preferences.themeMode, ThemeMode.system);
    });

    test('notifies only when the settings actually change', () {
      var notified = 0;
      final preferences = AppPreferences()
        ..addListener(() => notified++)
        ..apply(AppSettings.defaults)
        ..apply(const AppSettings(biometricConfirmation: true))
        ..apply(const AppSettings(biometricConfirmation: true));

      expect(notified, 1);
      expect(preferences.biometricConfirmation, isTrue);
    });
  });

  group('settings labels', () {
    test('localize every theme mode and language', () {
      final es = AppLocalizationsEs();
      final en = AppLocalizationsEn();

      expect(AppThemeMode.dark.label(es), 'Oscuro');
      expect(AppThemeMode.light.label(en), 'Light');
      expect(AppThemeMode.system.label(es), 'Sistema');
      expect(AppLanguage.spanish.label(en), 'Español');
      expect(AppLanguage.english.label(es), 'English');
      expect(AppLanguage.system.label(en), 'System');
    });
  });
}
