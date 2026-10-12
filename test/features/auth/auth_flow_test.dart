import 'package:demo/app/app.dart';
import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/app/router/auth_guard.dart';
import 'package:demo/app/session_bootstrap.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/features/auth/data/datasources/mock_auth_backend.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/features/tasks/data/datasources/mock_tasks_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/in_memory_secure_storage.dart';
import '../../helpers/mocks.dart';
import 'helpers/auth_mocks.dart';

/// End-to-end flow through the real stack (router, guard, ViewModels, use
/// cases, repository, Dio, auth interceptor and mock backend); only the
/// platform plugins are replaced.
void main() {
  late SessionService session;
  late InMemorySecureStorage storage;

  /// Survives an in-test "app restart"; reset before every test.
  InMemorySecureStorage? persisted;

  const config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://api.test',
    useMockApi: true,
    pinningEnabled: false,
    pinnedSha256: [],
    rootPolicy: SecurityPolicy.warn,
  );

  Future<void> boot(WidgetTester tester) async {
    tester.platformDispatcher.localesTestValue = [const Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await resetLocator();
    storage = persisted ??= InMemorySecureStorage();
    session = SessionService();
    final router = AppRouter.create(
      redirect: AuthGuard(session).redirect,
      refreshListenable: session,
    );
    await setupLocator(
      router: router,
      config: config,
      session: session,
      mockRoutes: [...MockAuthBackend().routes, ...MockTasksBackend().routes],
    );
    locator
      ..unregister<SecureStorage>()
      ..registerSingleton<SecureStorage>(storage)
      ..unregister<ScreenProtection>()
      ..registerSingleton<ScreenProtection>(MockScreenProtection());

    await restoreSession(
      getCurrentUser: locator<GetCurrentUserUseCase>(),
      session: session,
    );

    final integrity = MockDeviceIntegrityService();
    when(integrity.evaluate()).thenAnswer((_) async => IntegrityDecision.allow);
    await tester.pumpWidget(
      App(
        routerConfig: locator<GoRouter>(),
        integrityViewModelBuilder: () => IntegrityGateViewModel(integrity),
        preferences: locator<AppPreferences>(),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() => persisted = null);

  tearDown(resetLocator);

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> signInAsDemo(WidgetTester tester) async {
    await tester.enterText(
      field('Correo electrónico'),
      MockAuthBackend.demoEmail,
    );
    await tester.enterText(field('Contraseña'), MockAuthBackend.demoPassword);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  group('authentication flow', () {
    testWidgets('unauthenticated users land on the login screen', (
      tester,
    ) async {
      await boot(tester);

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(find.text('Inicio'), findsNothing);
    });

    testWidgets(
      'signs in with the demo account, greets the user and signs out',
      (tester) async {
        await boot(tester);

        await signInAsDemo(tester);
        expect(find.text('Hola, Demo User'), findsOneWidget);

        await tester.tap(find.text('Ajustes'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Cerrar sesión'), 200);
        await tester.tap(find.text('Cerrar sesión'));
        await tester.pumpAndSettle();

        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(storage.values, isEmpty);
      },
    );

    testWidgets('wrong credentials show a generic error and stay on login', (
      tester,
    ) async {
      await boot(tester);

      await tester.enterText(
        field('Correo electrónico'),
        MockAuthBackend.demoEmail,
      );
      await tester.enterText(field('Contraseña'), 'wrong-password');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
      expect(find.text('Inicio'), findsNothing);
    });

    testWidgets('registers a new account and lands on home', (tester) async {
      await boot(tester);

      await tester.tap(find.textContaining('Crear cuenta'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Nombre'), 'Lucía Gómez');
      await tester.enterText(field('Correo electrónico'), 'lucia@test.com');
      await tester.enterText(field('Contraseña'), 'Abcdef1!');
      await tester.enterText(field('Confirmar contraseña'), 'Abcdef1!');
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Hola, Lucía Gómez'), findsOneWidget);
    });

    testWidgets('registering the demo e-mail reports it is taken', (
      tester,
    ) async {
      await boot(tester);

      await tester.tap(find.textContaining('Crear cuenta'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Nombre'), 'Alguien');
      await tester.enterText(
        field('Correo electrónico'),
        MockAuthBackend.demoEmail,
      );
      await tester.enterText(field('Contraseña'), 'Abcdef1!');
      await tester.enterText(field('Confirmar contraseña'), 'Abcdef1!');
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
    });

    testWidgets('a stored session is restored on the next launch', (
      tester,
    ) async {
      await boot(tester);
      await signInAsDemo(tester);
      expect(find.text('Hola, Demo User'), findsOneWidget);

      // "Restart" the app with the same secure storage.
      await tester.pumpWidget(const SizedBox());
      await boot(tester);

      expect(find.text('Hola, Demo User'), findsOneWidget);
    });

    testWidgets('an expired session sends the user back to login', (
      tester,
    ) async {
      await boot(tester);
      await signInAsDemo(tester);

      session.markSignedOut();
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
    });
  });
}
