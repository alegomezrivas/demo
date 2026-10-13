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

  /// Welcome screen with the sign-up and sign-in entry points (public).
  static const String welcome = '/welcome';

  /// Sign-up step: e-mail address (public).
  static const String signUpEmail = '/signup/email';

  /// Sign-up step: confirmation code (public).
  static const String signUpCode = '/signup/code';

  /// Sign-up step: password (public).
  static const String signUpPassword = '/signup/password';

  /// Sign-up step: full name (public).
  static const String signUpName = '/signup/name';

  /// Sign-up step: username (public).
  static const String signUpUsername = '/signup/username';

  /// Sign-up step: terms and policies (public).
  static const String signUpTerms = '/signup/terms';

  /// Sign-up step: profile picture (public, the account already exists).
  static const String signUpAvatar = '/signup/avatar';

  /// Sign-up step: final welcome (public).
  static const String signUpDone = '/signup/done';

  /// Full text of the terms and policies (public).
  static const String terms = '/terms';

  /// Sign-in screen (public).
  static const String login = '/login';

  /// About screen.
  static const String about = '/about';
}
