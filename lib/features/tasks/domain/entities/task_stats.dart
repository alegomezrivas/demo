import 'package:meta/meta.dart';

/// Aggregated numbers shown on the dashboard.
@immutable
class TaskStats {
  /// Creates the statistics.
  const TaskStats({
    required this.total,
    required this.done,
    required this.overdue,
    required this.highPriorityPending,
  });

  /// All tasks.
  final int total;

  /// Completed tasks.
  final int done;

  /// Open tasks whose deadline passed.
  final int overdue;

  /// Open tasks with high priority.
  final int highPriorityPending;

  /// Open tasks.
  int get pending => total - done;

  /// Share of completed tasks between 0 and 1 (0 when there are none).
  double get completionRate => total == 0 ? 0 : done / total;

  @override
  bool operator ==(Object other) =>
      other is TaskStats &&
      other.total == total &&
      other.done == done &&
      other.overdue == overdue &&
      other.highPriorityPending == highPriorityPending;

  @override
  int get hashCode => Object.hash(total, done, overdue, highPriorityPending);
}
