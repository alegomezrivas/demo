import 'package:demo/app/preferences_bootstrap.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../features/settings/helpers/settings_mocks.dart';

void main() {
  late MockGetSettingsUseCase getSettings;
  late AppPreferences preferences;

  setUp(() {
    getSettings = MockGetSettingsUseCase();
    preferences = AppPreferences();
  });

  group('loadPreferences', () {
    test('applies the stored settings', () async {
      when(getSettings(any)).thenAnswer(
        (_) async => right(const AppSettings(themeMode: AppThemeMode.dark)),
      );

      await loadPreferences(getSettings: getSettings, preferences: preferences);

      expect(preferences.settings.themeMode, AppThemeMode.dark);
    });

    test('keeps the defaults when loading fails', () async {
      when(getSettings(any))
          .thenAnswer((_) async => left(const CacheFailure()));

      await loadPreferences(getSettings: getSettings, preferences: preferences);

      expect(preferences.settings, AppSettings.defaults);
    });
  });
}
