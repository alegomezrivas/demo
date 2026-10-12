/// Route path constants; never hardcode paths elsewhere.
abstract final class AppRoutes {
  /// Dashboard tab.
  static const String home = '/';

  /// Task list tab.
  static const String tasks = '/tasks';

  /// Create-task form.
  static const String taskNew = '/tasks/new';

  /// Edit-task form pattern.
  static const String taskPattern = '/tasks/:id';

  /// Settings tab.
  static const String settings = '/settings';

  /// Path of the edit form for the task with [id].
  static String task(String id) => '/tasks/${Uri.encodeComponent(id)}';

  /// Sign-in screen (public).
  static const String login = '/login';

  /// Sign-up screen (public).
  static const String register = '/register';

  /// About screen.
  static const String about = '/about';
}
