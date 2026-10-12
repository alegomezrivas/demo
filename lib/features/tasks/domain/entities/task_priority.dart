/// Importance of a task.
enum TaskPriority {
  /// Can wait.
  low,

  /// Normal importance.
  medium,

  /// Needs attention first.
  high
  ;

  /// Parses a wire value; unknown values fall back to [medium].
  static TaskPriority parse(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.name == value,
      orElse: () => TaskPriority.medium,
    );
  }
}
