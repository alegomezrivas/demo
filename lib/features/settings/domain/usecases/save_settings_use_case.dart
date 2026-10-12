import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/repositories/settings_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Stores the user preferences.
class SaveSettingsUseCase implements UseCase<Unit, AppSettings> {
  /// Creates the use case.
  const SaveSettingsUseCase(this._repository);

  final SettingsRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(AppSettings params) =>
      _repository.save(params);
}
