import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/app/shell/main_shell.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/features/about/presentation/views/about_view.dart';
import 'package:demo/features/auth/presentation/views/login_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_avatar_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_code_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_done_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_email_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_name_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_password_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_terms_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_username_view.dart';
import 'package:demo/features/auth/presentation/views/terms_view.dart';
import 'package:demo/features/auth/presentation/views/welcome_view.dart';
import 'package:demo/features/dashboard/presentation/views/dashboard_view.dart';
import 'package:demo/features/settings/presentation/views/settings_view.dart';
import 'package:demo/features/tasks/presentation/views/task_form_view.dart';
import 'package:demo/features/tasks/presentation/views/tasks_view.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Builds the application [GoRouter].
abstract final class AppRouter {
  /// Creates the router.
  ///
  /// [redirect] is the hook for route guards (for example, sending
  /// unauthenticated users to the login screen) and [refreshListenable]
  /// re-runs it when the session changes.
  static GoRouter create({
    String initialLocation = AppRoutes.home,
    GoRouterRedirect? redirect,
    Listenable? refreshListenable,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      redirect: redirect,
      refreshListenable: refreshListenable,
      routes: <RouteBase>[
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => MainShell(
            navigationShell: navigationShell,
            screenProtection: locator<ScreenProtection>(),
            protectScreens: locator<AppConfig>().protectScreens,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.home,
                  builder: (context, state) => const DashboardView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.tasks,
                  builder: (context, state) => const TasksView(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.settings,
                  builder: (context, state) => const SettingsView(),
                ),
              ],
            ),
          ],
        ),
        // Full-screen routes (no bottom navigation). `new` must precede `:id`.
        GoRoute(
          path: AppRoutes.taskNew,
          builder: (context, state) => const TaskFormView(),
        ),
        GoRoute(
          path: AppRoutes.taskPattern,
          builder: (context, state) =>
              TaskFormView(taskId: state.pathParameters['id']),
        ),
        GoRoute(
          path: AppRoutes.welcome,
          builder: (context, state) => const WelcomeView(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginView(),
        ),
        GoRoute(
          path: AppRoutes.signUpEmail,
          builder: (context, state) => const SignUpEmailView(),
        ),
        GoRoute(
          path: AppRoutes.signUpCode,
          builder: (context, state) => const SignUpCodeView(),
        ),
        GoRoute(
          path: AppRoutes.signUpPassword,
          builder: (context, state) => const SignUpPasswordView(),
        ),
        GoRoute(
          path: AppRoutes.signUpName,
          builder: (context, state) => const SignUpNameView(),
        ),
        GoRoute(
          path: AppRoutes.signUpUsername,
          builder: (context, state) => const SignUpUsernameView(),
        ),
        GoRoute(
          path: AppRoutes.signUpTerms,
          builder: (context, state) => const SignUpTermsView(),
        ),
        GoRoute(
          path: AppRoutes.signUpAvatar,
          builder: (context, state) => const SignUpAvatarView(),
        ),
        GoRoute(
          path: AppRoutes.signUpDone,
          builder: (context, state) => const SignUpDoneView(),
        ),
        GoRoute(
          path: AppRoutes.terms,
          builder: (context, state) => const TermsView(),
        ),
        GoRoute(
          path: AppRoutes.about,
          builder: (context, state) => const AboutView(),
        ),
      ],
    );
  }
}
