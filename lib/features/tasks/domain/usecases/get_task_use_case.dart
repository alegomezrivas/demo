import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Loads one task by id.
class GetTaskUseCase implements UseCase<TaskItem, String> {
  /// Creates the use case.
  const GetTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, TaskItem>> call(String params) async {
    if (params.trim().isEmpty) {
      return left(const ValidationFailure('empty_id'));
    }
    return _repository.getTask(params);
  }
}
