import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/app/shell/main_shell.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/theme/app_theme.dart';
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
import 'package:flutter/widgets.dart';
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
          pageBuilder: (context, state) =>
              _stepPage(context, state, const WelcomeView()),
        ),
        GoRoute(
          path: AppRoutes.login,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const LoginView()),
        ),
        GoRoute(
          path: AppRoutes.signUpEmail,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpEmailView()),
        ),
        GoRoute(
          path: AppRoutes.signUpCode,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpCodeView()),
        ),
        GoRoute(
          path: AppRoutes.signUpPassword,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpPasswordView()),
        ),
        GoRoute(
          path: AppRoutes.signUpName,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpNameView()),
        ),
        GoRoute(
          path: AppRoutes.signUpUsername,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpUsernameView()),
        ),
        GoRoute(
          path: AppRoutes.signUpTerms,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpTermsView()),
        ),
        GoRoute(
          path: AppRoutes.signUpAvatar,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpAvatarView()),
        ),
        GoRoute(
          path: AppRoutes.signUpDone,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const SignUpDoneView()),
        ),
        GoRoute(
          path: AppRoutes.terms,
          pageBuilder: (context, state) =>
              _stepPage(context, state, const TermsView()),
        ),
        GoRoute(
          path: AppRoutes.about,
          builder: (context, state) => const AboutView(),
        ),
      ],
    );
  }

  /// Page with the shared step transition: a short slide and fade.
  ///
  /// It collapses to no animation when the system asks to reduce motion.
  static Page<void> _stepPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) {
    final motion = context.motion;
    final duration = context.motionDuration(motion.normal);
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondary, page) {
        final curved = CurvedAnimation(parent: animation, curve: motion.curve);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).animate(curved),
            child: page,
          ),
        );
      },
    );
  }
}
