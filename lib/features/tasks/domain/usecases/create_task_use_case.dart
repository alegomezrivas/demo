import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Creates a task.
class CreateTaskUseCase implements UseCase<TaskItem, TaskDraft> {
  /// Creates the use case.
  const CreateTaskUseCase(this._repository);

  /// Longest accepted title.
  static const int maxTitleLength = 120;

  final TaskRepository _repository;

  @override
  Future<Either<Failure, TaskItem>> call(TaskDraft params) async {
    final title = params.title.trim();
    if (title.isEmpty || title.length > maxTitleLength) {
      return left(const ValidationFailure('invalid_title'));
    }
    return _repository.createTask(params);
  }
}
