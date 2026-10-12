import 'package:demo/core/error/failures.dart';
import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/features/tasks/domain/entities/task_draft.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_query.dart';
import 'package:demo/features/tasks/domain/entities/task_stats.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for managing tasks.
abstract interface class TaskRepository {
  /// Returns one page of tasks matching [query].
  Future<Either<Failure, PagedResult<TaskItem>>> getTasks(TaskQuery query);

  /// Returns the task with [id].
  Future<Either<Failure, TaskItem>> getTask(String id);

  /// Creates a task from [draft].
  Future<Either<Failure, TaskItem>> createTask(TaskDraft draft);

  /// Replaces the editable fields of [task] and returns the stored result.
  Future<Either<Failure, TaskItem>> updateTask(TaskItem task);

  /// Deletes the task with [id].
  Future<Either<Failure, Unit>> deleteTask(String id);

  /// Returns the aggregated statistics.
  Future<Either<Failure, TaskStats>> getStats();
}
