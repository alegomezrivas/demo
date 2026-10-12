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
import 'package:demo/core/security/sensitive_action_guard.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:demo/core/services/data_change_notifier.dart';
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
import 'package:demo/features/dashboard/presentation/viewmodels/dashboard_view_model.dart';
import 'package:demo/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:demo/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:demo/features/settings/domain/repositories/settings_repository.dart';
import 'package:demo/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:demo/features/settings/domain/usecases/save_settings_use_case.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/features/settings/presentation/viewmodels/settings_view_model.dart';
import 'package:demo/features/tasks/data/datasources/tasks_remote_data_source.dart';
import 'package:demo/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:demo/features/tasks/domain/repositories/task_repository.dart';
import 'package:demo/features/tasks/domain/usecases/create_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/delete_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_stats_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_task_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/get_tasks_use_case.dart';
import 'package:demo/features/tasks/domain/usecases/update_task_use_case.dart';
import 'package:demo/features/tasks/presentation/viewmodels/task_form_view_model.dart';
import 'package:demo/features/tasks/presentation/viewmodels/tasks_view_model.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:jailbreak_root_detection/jailbreak_root_detection.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    ..registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    )
    ..registerSingleton<AppPreferences>(AppPreferences())
    ..registerSingleton<GoRouter>(router)
    ..registerSingleton<DataChangeNotifier>(DataChangeNotifier())
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
    // Tasks feature.
    ..registerLazySingleton<TasksRemoteDataSource>(
      () => TasksRemoteDataSourceImpl(locator<Dio>()),
    )
    ..registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(remote: locator<TasksRemoteDataSource>()),
    )
    ..registerFactory<GetTasksUseCase>(
      () => GetTasksUseCase(locator<TaskRepository>()),
    )
    ..registerFactory<GetTaskUseCase>(
      () => GetTaskUseCase(locator<TaskRepository>()),
    )
    ..registerFactory<CreateTaskUseCase>(
      () => CreateTaskUseCase(locator<TaskRepository>()),
    )
    ..registerFactory<UpdateTaskUseCase>(
      () => UpdateTaskUseCase(locator<TaskRepository>()),
    )
    ..registerFactory<DeleteTaskUseCase>(
      () => DeleteTaskUseCase(locator<TaskRepository>()),
    )
    ..registerFactory<GetTaskStatsUseCase>(
      () => GetTaskStatsUseCase(locator<TaskRepository>()),
    )
    // Settings feature.
    ..registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(locator<SharedPreferences>()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(local: locator<SettingsLocalDataSource>()),
    )
    ..registerFactory<GetSettingsUseCase>(
      () => GetSettingsUseCase(locator<SettingsRepository>()),
    )
    ..registerFactory<SaveSettingsUseCase>(
      () => SaveSettingsUseCase(locator<SettingsRepository>()),
    )
    ..registerLazySingleton<SensitiveActionGuard>(
      () => SensitiveActionGuard(
        authenticator: locator<BiometricAuthenticator>(),
        isEnabled: () => locator<AppPreferences>().biometricConfirmation,
      ),
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
    ..registerFactory<DashboardViewModel>(
      () => DashboardViewModel(
        getCurrentUser: locator<GetCurrentUserUseCase>(),
        getStats: locator<GetTaskStatsUseCase>(),
        navigation: locator<NavigationService>(),
        changes: locator<DataChangeNotifier>(),
      ),
    )
    ..registerFactory<TasksViewModel>(
      () => TasksViewModel(
        getTasks: locator<GetTasksUseCase>(),
        updateTask: locator<UpdateTaskUseCase>(),
        deleteTask: locator<DeleteTaskUseCase>(),
        guard: locator<SensitiveActionGuard>(),
        navigation: locator<NavigationService>(),
        changes: locator<DataChangeNotifier>(),
      ),
    )
    ..registerFactory<TaskFormViewModel>(
      () => TaskFormViewModel(
        getTask: locator<GetTaskUseCase>(),
        createTask: locator<CreateTaskUseCase>(),
        updateTask: locator<UpdateTaskUseCase>(),
        navigation: locator<NavigationService>(),
        changes: locator<DataChangeNotifier>(),
      ),
    )
    ..registerFactory<SettingsViewModel>(
      () => SettingsViewModel(
        getCurrentUser: locator<GetCurrentUserUseCase>(),
        saveSettings: locator<SaveSettingsUseCase>(),
        logout: locator<LogoutUseCase>(),
        preferences: locator<AppPreferences>(),
        authenticator: locator<BiometricAuthenticator>(),
        guard: locator<SensitiveActionGuard>(),
        navigation: locator<NavigationService>(),
        session: locator<SessionService>(),
      ),
    )
    ..registerFactory<AboutViewModel>(
      () => AboutViewModel(locator<NavigationService>()),
    );
}

/// Removes every registration; intended for tests.
Future<void> resetLocator() => locator.reset();
