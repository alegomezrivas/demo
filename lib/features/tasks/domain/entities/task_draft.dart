import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:meta/meta.dart';

/// Data needed to create or fully update a task.
@immutable
class TaskDraft {
  /// Creates a draft.
  const TaskDraft({
    required this.title,
    required this.priority,
    this.description = '',
    this.isDone = false,
    this.dueDate,
  });

  /// Short title.
  final String title;

  /// Longer free text.
  final String description;

  /// Importance.
  final TaskPriority priority;

  /// Completion flag.
  final bool isDone;

  /// Optional deadline.
  final DateTime? dueDate;
}
