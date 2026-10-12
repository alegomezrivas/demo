import 'package:demo/core/error/exceptions.dart';
import 'package:demo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:demo/features/settings/data/models/settings_dto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Future<SettingsLocalDataSourceImpl> build([
    Map<String, Object> initial = const {},
  ]) async {
    SharedPreferences.setMockInitialValues(initial);
    return SettingsLocalDataSourceImpl(await SharedPreferences.getInstance());
  }

  group('SettingsLocalDataSourceImpl', () {
    test('returns null when nothing was saved', () async {
      expect(await (await build()).read(), isNull);
    });

    test('persists and reads settings back', () async {
      final source = await build();
      const dto = SettingsDto(
        themeMode: 'dark',
        language: 'spanish',
        biometricConfirmation: true,
      );

      await source.write(dto);

      expect(await source.read(), dto);
    });

    test('overwrites the previous value', () async {
      final source = await build();

      await source.write(const SettingsDto(themeMode: 'dark'));
      await source.write(const SettingsDto(themeMode: 'light'));

      expect((await source.read())?.themeMode, 'light');
    });

    test('raises CacheException for corrupted JSON', () async {
      final source = await build({'settings.v1': '{broken'});

      await expectLater(
        source.read(),
        throwsA(
          isA<CacheException>().having(
            (e) => e.code,
            'code',
            'invalid_settings',
          ),
        ),
      );
    });

    test('raises CacheException for JSON of the wrong shape', () async {
      final source = await build({'settings.v1': '{"themeMode": 5}'});

      await expectLater(source.read(), throwsA(isA<CacheException>()));
    });
  });
}
