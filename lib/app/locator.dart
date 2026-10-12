import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/network/dio_client_factory.dart';
import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/core/security/biometric_authenticator.dart';
import 'package:demo/core/security/device_integrity_checker.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/security/flutter_secure_storage_service.dart';
import 'package:demo/core/security/jailbreak_root_integrity_checker.dart';
import 'package:demo/core/security/local_auth_biometric_authenticator.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/security/screen_protector_service.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/secure_token_storage.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:demo/core/services/go_router_navigation_service.dart';
import 'package:demo/core/services/navigation_service.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/utils/logging/app_logger.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/features/about/presentation/viewmodels/about_view_model.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:demo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:demo/features/auth/domain/usecases/register_use_case.dart';
import 'package:demo/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:demo/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:demo/features/home/presentation/viewmodels/home_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:local_auth/local_auth.dart';

/// Global service locator.
final GetIt locator = GetIt.instance;

/// Registers every dependency of the app.
///
/// The [router] is received as a parameter (instead of being built here) so
/// the router, which builds views, and the locator, which views read from,
/// do not depend on each other. Features contribute their [mockRoutes] so the
/// mock backend can serve them while `USE_MOCK_API` is enabled.
Future<void> setupLocator({
  required GoRouter router,
  AppConfig? config,
  List<MockRoute> mockRoutes = const [],
  SessionService? session,
}) async {
  final appConfig = config ?? AppConfig.fromEnvironment();
  locator
    ..registerSingleton<AppConfig>(appConfig)
    ..registerSingleton<AppLogger>(ConsoleAppLogger.forMode())
    ..registerSingleton<GoRouter>(router)
    ..registerSingleton<SessionService>(session ?? SessionService())
    ..registerLazySingleton<NavigationService>(
      () => GoRouterNavigationService(locator<GoRouter>()),
    )
    // Security.
    ..registerLazySingleton<SecureStorage>(
      () => const FlutterSecureStorageService(FlutterSecureStorage()),
    )
    ..registerLazySingleton<TokenStorage>(
      () => SecureTokenStorage(locator<SecureStorage>()),
    )
    ..registerLazySingleton<DeviceIntegrityChecker>(
      () => JailbreakRootIntegrityChecker(JailbreakRootDetection.instance),
    )
    ..registerLazySingleton<DeviceIntegrityService>(
      () => DeviceIntegrityService(
        locator<DeviceIntegrityChecker>(),
        appConfig.rootPolicy,
      ),
    )
    ..registerLazySingleton<BiometricAuthenticator>(
      () => LocalAuthBiometricAuthenticator(LocalAuthentication()),
    )
    ..registerLazySingleton<ScreenProtection>(ScreenProtectorService.new)
    // Network.
    ..registerLazySingleton<SessionExpiredNotifier>(SessionExpiredNotifier.new)
    ..registerLazySingleton<Dio>(
      () => DioClientFactory(
        config: appConfig,
        tokenStorage: locator<TokenStorage>(),
        sessionNotifier: locator<SessionExpiredNotifier>(),
        logger: locator<AppLogger>(),
        mockRoutes: mockRoutes,
      ).create(),
    )
    // Auth feature.
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(locator<Dio>()),
    )
    ..registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        locator<TokenStorage>(),
        locator<SecureStorage>(),
      ),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remote: locator<AuthRemoteDataSource>(),
        local: locator<AuthLocalDataSource>(),
      ),
    )
    ..registerFactory<LoginUseCase>(
      () => LoginUseCase(locator<AuthRepository>()),
    )
    ..registerFactory<RegisterUseCase>(
      () => RegisterUseCase(locator<AuthRepository>()),
    )
    ..registerFactory<LogoutUseCase>(
      () => LogoutUseCase(locator<AuthRepository>()),
    )
    ..registerFactory<GetCurrentUserUseCase>(
      () => GetCurrentUserUseCase(locator<AuthRepository>()),
    )
    // ViewModels.
    ..registerFactory<LoginViewModel>(
      () => LoginViewModel(
        login: locator<LoginUseCase>(),
        navigation: locator<NavigationService>(),
        session: locator<SessionService>(),
        screenProtection: locator<ScreenProtection>(),
      ),
    )
    ..registerFactory<RegisterViewModel>(
      () => RegisterViewModel(
        register: locator<RegisterUseCase>(),
        navigation: locator<NavigationService>(),
        session: locator<SessionService>(),
        screenProtection: locator<ScreenProtection>(),
      ),
    )
    ..registerFactory<IntegrityGateViewModel>(
      () => IntegrityGateViewModel(locator<DeviceIntegrityService>()),
    )
    ..registerFactory<HomeViewModel>(
      () => HomeViewModel(
        navigation: locator<NavigationService>(),
        getCurrentUser: locator<GetCurrentUserUseCase>(),
        logout: locator<LogoutUseCase>(),
        session: locator<SessionService>(),
      ),
    )
    ..registerFactory<AboutViewModel>(
      () => AboutViewModel(locator<NavigationService>()),
    );
}

/// Removes every registration; intended for tests.
Future<void> resetLocator() => locator.reset();
