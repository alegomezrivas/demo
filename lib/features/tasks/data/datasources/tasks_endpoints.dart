/// Paths of the tasks API.
abstract final class TasksEndpoints {
  /// `GET` list, `POST` create.
  static const String tasks = '/tasks';

  /// `GET` aggregated statistics.
  static const String stats = '/tasks/stats';

  /// `GET`, `PUT` and `DELETE` one task.
  static String task(String id) => '/tasks/${Uri.encodeComponent(id)}';

  /// Route pattern used by the mock backend.
  static const String taskPattern = '/tasks/:id';
}
