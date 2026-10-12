import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failure_mapper.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/core/utils/input_sanitizer.dart';
import 'package:demo/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:demo/features/tasks/data/models/task_dto.dart';
import 'package:demo/features/tasks/data/models/task_input_dto.dart';
import 'package:demo/features/tasks/data/models/task_page_dto.dart';
import 'package:demo/features/tasks/data/models/task_stats_dto.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:fpdart/fpdart.dart';

/// [TaskRepository] backed by the remote API.
///
/// Free text is sanitized right before it is sent to the backend.
class TaskRepositoryImpl implements TaskRepository {
  /// Creates the repository.
  const TaskRepositoryImpl({required this._remote});

  static const int _maxTitle = 120;
  static const int _maxDescription = 1000;
  static const int _maxSearch = 100;

  final TasksRemoteDataSource _remote;

  @override
  Future<Either<Failure, PagedResult<TaskItem>>> getTasks(TaskQuery query) {
    return _guard(() async {
      final page = await _remote.getTasks(
        query.copyWith(
          search: InputSanitizer.text(query.search, maxLength: _maxSearch),
        ),
      );
      return page.toEntity();
    });
  }

  @override
  Future<Either<Failure, TaskItem>> getTask(String id) {
    return _guard(() async => (await _remote.getTask(id)).toEntity());
  }

  @override
  Future<Either<Failure, TaskItem>> createTask(TaskDraft draft) {
    return _guard(() async {
      final input = TaskInputDto.fromDraft(
        draft,
        title: InputSanitizer.text(draft.title, maxLength: _maxTitle),
        description: InputSanitizer.text(
          draft.description,
          maxLength: _maxDescription,
        ),
      );
      return (await _remote.createTask(input)).toEntity();
    });
  }

  @override
  Future<Either<Failure, TaskItem>> updateTask(TaskItem task) {
    return _guard(() async {
      final input = TaskInputDto.fromItem(
        task,
        title: InputSanitizer.text(task.title, maxLength: _maxTitle),
        description: InputSanitizer.text(
          task.description,
          maxLength: _maxDescription,
        ),
      );
      return (await _remote.updateTask(task.id, input)).toEntity();
    });
  }

  @override
  Future<Either<Failure, Unit>> deleteTask(String id) {
    return _guard(() async {
      await _remote.deleteTask(id);
      return unit;
    });
  }

  @override
  Future<Either<Failure, TaskStats>> getStats() {
    return _guard(() async => (await _remote.getStats()).toEntity());
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } on AppException catch (error) {
      return left(FailureMapper.fromError(error));
    } on Exception catch (error) {
      // Includes FormatException from malformed dates in a response.
      return left(FailureMapper.fromError(error));
    }
  }
}
