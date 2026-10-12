import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:demo/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/settings_mocks.dart';

void main() {
  late MockSettingsRepository repository;
  const settings = AppSettings(themeMode: AppThemeMode.dark);

  setUp(() => repository = MockSettingsRepository());

  group('GetSettingsUseCase', () {
    test('returns the stored settings', () async {
      when(repository.load()).thenAnswer((_) async => right(settings));

      expect(
        await GetSettingsUseCase(repository)(const NoParams()),
        right<Failure, AppSettings>(settings),
      );
    });

    test('forwards failures', () async {
      when(repository.load())
          .thenAnswer((_) async => left(const CacheFailure()));

      expect(
        (await GetSettingsUseCase(repository)(const NoParams())).isLeft(),
        isTrue,
      );
    });
  });

  group('SaveSettingsUseCase', () {
    test('saves the settings', () async {
      when(repository.save(any)).thenAnswer((_) async => right(unit));

      expect(
        await SaveSettingsUseCase(repository)(settings),
        right<Failure, Unit>(unit),
      );
      verify(repository.save(settings)).called(1);
    });

    test('forwards failures', () async {
      when(repository.save(any))
          .thenAnswer((_) async => left(const CacheFailure()));

      expect(
        (await SaveSettingsUseCase(repository)(settings)).isLeft(),
        isTrue,
      );
    });
  });
}
