import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Deletes a task by id.
class DeleteTaskUseCase implements UseCase<Unit, String> {
  /// Creates the use case.
  const DeleteTaskUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(String params) async {
    if (params.trim().isEmpty) {
      return left(const ValidationFailure('empty_id'));
    }
    return _repository.deleteTask(params);
  }
}
