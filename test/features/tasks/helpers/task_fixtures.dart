import 'package:demo/core/pagination/paged_result.dart';
import 'package:demo/features/tasks/domain/entities/task_item.dart';
import 'package:demo/features/tasks/domain/entities/task_priority.dart';

final DateTime fixtureNow = DateTime.utc(2026, 1, 15, 12);

TaskItem buildTask({
  String id = 't1',
  String title = 'Write tests',
  String description = '',
  TaskPriority priority = TaskPriority.medium,
  bool isDone = false,
  DateTime? dueDate,
}) {
  return TaskItem(
    id: id,
    title: title,
    description: description,
    priority: priority,
    isDone: isDone,
    createdAt: DateTime.utc(2026, 1, 10),
    dueDate: dueDate,
  );
}

/// Builds a page of tasks for use-case stubs.
PagedResult<TaskItem> buildPage(
  List<TaskItem> items, {
  int page = 1,
  int pageSize = 10,
  int? total,
}) {
  return PagedResult<TaskItem>(
    items: items,
    page: page,
    pageSize: pageSize,
    total: total ?? items.length,
  );
}

/// Generates [count] distinct tasks with ids `start`..`start + count - 1`.
List<TaskItem> buildTasks(int count, {int start = 0}) => [
  for (var i = start; i < start + count; i++)
    buildTask(id: 't$i', title: 'Task $i'),
];
