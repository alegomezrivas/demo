import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/core/security/biometric_authenticator.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:demo/core/services/go_router_navigation_service.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/utils/logging/app_logger.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/features/about/presentation/viewmodels/about_view_model.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:demo/features/auth/domain/usecases/register_use_case.dart';
import 'package:demo/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:demo/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:demo/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:dio/dio.dart';
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

    test('registers the security services', () {
      expect(locator<TokenStorage>(), isA<TokenStorage>());
      expect(locator<DeviceIntegrityService>(), isA<DeviceIntegrityService>());
      expect(locator<BiometricAuthenticator>(), isA<BiometricAuthenticator>());
      expect(locator<ScreenProtection>(), isA<ScreenProtection>());
      expect(locator<AppLogger>(), isA<AppLogger>());
    });

    test('registers the network stack as singletons', () {
      expect(locator<Dio>(), same(locator<Dio>()));
      expect(
        locator<SessionExpiredNotifier>(),
        same(locator<SessionExpiredNotifier>()),
      );
    });

    test('builds Dio from the configured base URL', () {
      expect(locator<Dio>().options.baseUrl, locator<AppConfig>().apiBaseUrl);
    });

    test('wires the auth feature from repository to use cases', () {
      expect(locator<AuthRepository>(), same(locator<AuthRepository>()));
      expect(locator<LoginUseCase>(), isA<LoginUseCase>());
      expect(locator<RegisterUseCase>(), isA<RegisterUseCase>());
      expect(locator<LogoutUseCase>(), isA<LogoutUseCase>());
      expect(locator<GetCurrentUserUseCase>(), isA<GetCurrentUserUseCase>());
    });

    test('shares one SessionService and uses an injected one', () async {
      expect(locator<SessionService>(), same(locator<SessionService>()));
      await resetLocator();
      final session = SessionService();

      await setupLocator(router: AppRouter.create(), session: session);

      expect(locator<SessionService>(), same(session));
    });

    test('registers the auth ViewModels as factories', () {
      expect(locator<LoginViewModel>(), isNot(same(locator<LoginViewModel>())));
      expect(locator<RegisterViewModel>(), isA<RegisterViewModel>());
    });

    test('registers ViewModels as factories (new instance per call)', () {
      expect(locator<HomeViewModel>(), isNot(same(locator<HomeViewModel>())));
      expect(locator<AboutViewModel>(), isA<AboutViewModel>());
      expect(locator<IntegrityGateViewModel>(), isA<IntegrityGateViewModel>());
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
