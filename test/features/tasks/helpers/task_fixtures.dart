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
