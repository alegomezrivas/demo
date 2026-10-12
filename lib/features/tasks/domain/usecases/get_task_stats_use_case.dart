import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Loads the dashboard statistics.
class GetTaskStatsUseCase implements UseCase<TaskStats, NoParams> {
  /// Creates the use case.
  const GetTaskStatsUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, TaskStats>> call(NoParams params) async =>
      await _repository.getStats();
}
