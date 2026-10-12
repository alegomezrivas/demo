import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/settings/data/models/settings_dto.dart';
import 'package:demo/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/settings_mocks.dart';

void main() {
  late MockSettingsLocalDataSource local;
  late SettingsRepositoryImpl repository;

  setUp(() {
    local = MockSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(local: local);
  });

  group('load', () {
    test('maps the stored DTO to settings', () async {
      when(local.read()).thenAnswer(
        (_) async => const SettingsDto(
          themeMode: 'dark',
          language: 'english',
          biometricConfirmation: true,
        ),
      );

      expect(
        await repository.load(),
        right<Failure, AppSettings>(
          const AppSettings(
            themeMode: AppThemeMode.dark,
            language: AppLanguage.english,
            biometricConfirmation: true,
          ),
        ),
      );
    });

    test('returns the defaults when nothing is stored', () async {
      when(local.read()).thenAnswer((_) async => null);

      expect(
        await repository.load(),
        right<Failure, AppSettings>(AppSettings.defaults),
      );
    });

    test('maps storage errors to failures', () async {
      when(local.read()).thenThrow(const CacheException('invalid_settings'));

      expect(
        (await repository.load()).getLeft().toNullable(),
        const CacheFailure('invalid_settings'),
      );
    });
  });

  group('save', () {
    test('writes the DTO', () async {
      const settings = AppSettings(themeMode: AppThemeMode.light);

      expect(await repository.save(settings), right<Failure, Unit>(unit));

      verify(local.write(SettingsDto.fromEntity(settings))).called(1);
    });

    test('maps write errors to failures', () async {
      when(
        local.write(any),
      ).thenThrow(const CacheException('settings_not_saved'));

      expect(
        (await repository.save(AppSettings.defaults)).getLeft().toNullable(),
        const CacheFailure('settings_not_saved'),
      );
    });
  });
}
