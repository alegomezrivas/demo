import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppSettings', () {
    test('defaults follow the system and keep biometrics off', () {
      expect(AppSettings.defaults.themeMode, AppThemeMode.system);
      expect(AppSettings.defaults.language, AppLanguage.system);
      expect(AppSettings.defaults.biometricConfirmation, isFalse);
    });

    test('copyWith replaces only the given fields', () {
      final next = AppSettings.defaults.copyWith(themeMode: AppThemeMode.dark);

      expect(next.themeMode, AppThemeMode.dark);
      expect(next.language, AppLanguage.system);
      expect(
        AppSettings.defaults
            .copyWith(biometricConfirmation: true)
            .biometricConfirmation,
        isTrue,
      );
      expect(
        AppSettings.defaults.copyWith(language: AppLanguage.english).language,
        AppLanguage.english,
      );
    });

    test('has value equality', () {
      expect(AppSettings.defaults, AppSettings.defaults.copyWith());
      expect(
        AppSettings.defaults.hashCode,
        AppSettings.defaults.copyWith().hashCode,
      );
      expect(
        AppSettings.defaults,
        isNot(const AppSettings(biometricConfirmation: true)),
      );
    });
  });

  group('AppThemeMode.parse', () {
    test('parses names and falls back to system', () {
      expect(AppThemeMode.parse('dark'), AppThemeMode.dark);
      expect(AppThemeMode.parse('light'), AppThemeMode.light);
      expect(AppThemeMode.parse('neon'), AppThemeMode.system);
    });
  });

  group('AppLanguage', () {
    test('exposes ISO codes, null for system', () {
      expect(AppLanguage.system.code, isNull);
      expect(AppLanguage.spanish.code, 'es');
      expect(AppLanguage.english.code, 'en');
    });

    test('parses names and falls back to system', () {
      expect(AppLanguage.parse('english'), AppLanguage.english);
      expect(AppLanguage.parse('klingon'), AppLanguage.system);
    });
  });
}
