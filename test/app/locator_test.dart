import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:demo/core/services/go_router_navigation_service.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/features/about/presentation/viewmodels/about_view_model.dart';
import 'package:demo/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  setUp(() async {
    await resetLocator();
    await setupLocator(router: AppRouter.create());
  });

  tearDown(resetLocator);

  group('setupLocator', () {
    test('registers the router, config and navigation service', () {
      expect(locator<GoRouter>(), isA<GoRouter>());
      expect(locator<AppConfig>(), isA<AppConfig>());
      expect(locator<NavigationService>(), isA<GoRouterNavigationService>());
    });

    test('registers ViewModels as factories (new instance per call)', () {
      expect(locator<HomeViewModel>(), isNot(same(locator<HomeViewModel>())));
      expect(locator<AboutViewModel>(), isA<AboutViewModel>());
    });

    test('uses the explicit config when provided', () async {
      await resetLocator();
      const config = AppConfig(
        environment: AppEnvironment.prod,
        apiBaseUrl: 'https://api.test',
        useMockApi: false,
        pinningEnabled: false,
        pinnedSha256: [],
        rootPolicy: SecurityPolicy.block,
      );

      await setupLocator(router: AppRouter.create(), config: config);

      expect(locator<AppConfig>(), same(config));
    });
  });

  group('resetLocator', () {
    test('removes every registration', () async {
      await resetLocator();

      expect(locator.isRegistered<GoRouter>(), isFalse);
    });
  });
}
