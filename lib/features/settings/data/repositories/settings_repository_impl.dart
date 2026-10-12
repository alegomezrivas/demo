import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failure_mapper.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:demo/features/settings/data/models/settings_dto.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:demo/features/settings/domain/repositories/settings_repository.dart';
import 'package:fpdart/fpdart.dart';

/// [SettingsRepository] backed by local storage.
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates the repository.
  const SettingsRepositoryImpl({required this._local});

  final SettingsLocalDataSource _local;

  @override
  Future<Either<Failure, AppSettings>> load() async {
    try {
      final stored = await _local.read();
      return right(stored?.toEntity() ?? AppSettings.defaults);
    } on AppException catch (error) {
      return left(FailureMapper.fromError(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> save(AppSettings settings) async {
    try {
      await _local.write(SettingsDto.fromEntity(settings));
      return right(unit);
    } on AppException catch (error) {
      return left(FailureMapper.fromError(error));
    }
  }
}
