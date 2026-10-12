import 'package:demo/core/error/failures.dart';
import 'package:demo/features/settings/domain/entities/app_settings.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for persisting user preferences.
abstract interface class SettingsRepository {
  /// Returns the stored settings, or the defaults when none were saved.
  Future<Either<Failure, AppSettings>> load();

  /// Stores [settings].
  Future<Either<Failure, Unit>> save(AppSettings settings);
}
