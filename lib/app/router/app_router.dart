import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/about/presentation/views/about_view.dart';
import 'package:demo/features/home/presentation/views/home_view.dart';
import 'package:go_router/go_router.dart';

/// Builds the application [GoRouter].
abstract final class AppRouter {
  /// Creates the router.
  ///
  /// [redirect] is the hook for route guards (for example, sending
  /// unauthenticated users to the login screen).
  static GoRouter create({
    String initialLocation = AppRoutes.home,
    GoRouterRedirect? redirect,
  }) {
    return GoRouter(
      initialLocation: initialLocation,
      redirect: redirect,
      routes: <RouteBase>[
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeView(),
        ),
        GoRoute(
          path: AppRoutes.about,
          builder: (context, state) => const AboutView(),
        ),
      ],
    );
  }
}
