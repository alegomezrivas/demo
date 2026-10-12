import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/services/go_router_navigation_service.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/features/about/presentation/viewmodels/about_view_model.dart';
import 'package:demo/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

/// Global service locator.
final GetIt locator = GetIt.instance;

/// Registers every dependency of the app.
///
/// The [router] is received as a parameter (instead of being built here) so
/// the router, which builds views, and the locator, which views read from,
/// do not depend on each other.
Future<void> setupLocator({required GoRouter router, AppConfig? config}) async {
  locator
    ..registerSingleton<AppConfig>(config ?? AppConfig.fromEnvironment())
    ..registerSingleton<GoRouter>(router)
    ..registerLazySingleton<NavigationService>(
      () => GoRouterNavigationService(locator<GoRouter>()),
    )
    ..registerFactory<HomeViewModel>(
      () => HomeViewModel(locator<NavigationService>()),
    )
    ..registerFactory<AboutViewModel>(
      () => AboutViewModel(locator<NavigationService>()),
    );
}

/// Removes every registration; intended for tests.
Future<void> resetLocator() => locator.reset();
