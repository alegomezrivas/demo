import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:meta/meta.dart';

/// Completion filter of a task listing.
enum TaskStatusFilter {
  /// Pending and done.
  all,

  /// Only open tasks.
  pending,

  /// Only completed tasks.
  done,
}

/// Search, filter and pagination parameters of a task listing.
@immutable
class TaskQuery {
  /// Creates a query for the first page without filters by default.
  const TaskQuery({
    this.page = 1,
    this.pageSize = defaultPageSize,
    this.search = '',
    this.status = TaskStatusFilter.all,
    this.priority,
  });

  /// Default number of items per page.
  static const int defaultPageSize = 10;

  /// 1-based page number.
  final int page;

  /// Items per page.
  final int pageSize;

  /// Text matched against title and description.
  final String search;

  /// Completion filter.
  final TaskStatusFilter status;

  /// Priority filter; null means any.
  final TaskPriority? priority;

  /// Returns a copy; use [clearPriority] to drop the priority filter.
  TaskQuery copyWith({
    int? page,
    int? pageSize,
    String? search,
    TaskStatusFilter? status,
    TaskPriority? priority,
    bool clearPriority = false,
  }) {
    return TaskQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      status: status ?? this.status,
      priority: clearPriority ? null : (priority ?? this.priority),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TaskQuery &&
      other.page == page &&
      other.pageSize == pageSize &&
      other.search == search &&
      other.status == status &&
      other.priority == priority;

  @override
  int get hashCode => Object.hash(page, pageSize, search, status, priority);
}
