import 'package:demo/features/tasks/domain/entities/task_priority.dart';
import 'package:meta/meta.dart';

/// A to-do item.
@immutable
class TaskItem {
  /// Creates a task.
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.isDone,
    required this.createdAt,
    this.dueDate,
  });

  /// Unique identifier.
  final String id;

  /// Short title.
  final String title;

  /// Longer free text (may be empty).
  final String description;

  /// Importance.
  final TaskPriority priority;

  /// Whether the task is completed.
  final bool isDone;

  /// Creation moment.
  final DateTime createdAt;

  /// Optional deadline.
  final DateTime? dueDate;

  /// Whether the deadline passed while the task is still open.
  bool isOverdue(DateTime now) =>
      !isDone && dueDate != null && dueDate!.isBefore(now);

  /// Returns a copy with the given fields replaced.
  ///
  /// Pass `clearDueDate: true` to remove the deadline.
  TaskItem copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    bool? isDone,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return TaskItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TaskItem &&
      other.id == id &&
      other.title == title &&
      other.description == description &&
      other.priority == priority &&
      other.isDone == isDone &&
      other.createdAt == createdAt &&
      other.dueDate == dueDate;

  @override
  int get hashCode =>
      Object.hash(id, title, description, priority, isDone, createdAt, dueDate);

  @override
  String toString() => 'TaskItem($id)';
}
