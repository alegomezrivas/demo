import 'package:demo/features/settings/data/models/settings_dto.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsDto', () {
    test('round-trips the domain settings', () {
      const settings = AppSettings(
        themeMode: AppThemeMode.dark,
        language: AppLanguage.english,
        biometricConfirmation: true,
      );

      final dto = SettingsDto.fromEntity(settings);

      expect(dto.toJson(), {
        'themeMode': 'dark',
        'language': 'english',
        'biometricConfirmation': true,
      });
      expect(SettingsDto.fromJson(dto.toJson()).toEntity(), settings);
    });

    test('uses defaults for missing keys', () {
      expect(SettingsDto.fromJson(const {}).toEntity(), AppSettings.defaults);
    });

    test('falls back to safe values for unknown names', () {
      final settings = SettingsDto.fromJson({
        'themeMode': 'neon',
        'language': 'xx',
      }).toEntity();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.language, AppLanguage.system);
    });
  });
}
