import 'package:demo/core/error/failures.dart';
import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Lists tasks with search, filters and pagination.
class GetTasksUseCase implements UseCase<PagedResult<TaskItem>, TaskQuery> {
  /// Creates the use case.
  const GetTasksUseCase(this._repository);

  final TaskRepository _repository;

  @override
  Future<Either<Failure, PagedResult<TaskItem>>> call(TaskQuery params) async {
    if (params.page < 1 || params.pageSize < 1) {
      return left(const ValidationFailure('invalid_pagination'));
    }
    return _repository.getTasks(params);
  }
}
