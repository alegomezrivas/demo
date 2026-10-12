import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/repositories/settings_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Loads the user preferences.
class GetSettingsUseCase implements UseCase<AppSettings, NoParams> {
  /// Creates the use case.
  const GetSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, AppSettings>> call(NoParams params) =>
      _repository.load();
}
