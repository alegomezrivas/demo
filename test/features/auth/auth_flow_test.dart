import 'package:demo/app/app.dart';
import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/app/router/app_routes.dart';
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
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
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
  late SignUpProgress progress;
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
    progress = SignUpProgress();
    final router = AppRouter.create(
      redirect: AuthGuard(session, signUpProgress: progress).redirect,
      refreshListenable: session,
    );
    await setupLocator(
      router: router,
      config: config,
      session: session,
      signUpProgress: progress,
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

  Future<void> openLogin(WidgetTester tester) async {
    await tester.tap(find.text('Ya tengo cuenta'));
    await tester.pumpAndSettle();
  }

  Future<void> signInAsDemo(WidgetTester tester) async {
    await openLogin(tester);
    await tester.enterText(
      field('Correo electrónico'),
      MockAuthBackend.demoEmail,
    );
    await tester.enterText(field('Contraseña'), MockAuthBackend.demoPassword);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  group('authentication flow', () {
    testWidgets('unauthenticated users land on the welcome screen', (
      tester,
    ) async {
      await boot(tester);

      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
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

        // Signing out returns to the sign-in screen.
        expect(find.text('Iniciar sesión'), findsOneWidget);
        expect(storage.values, isEmpty);
      },
    );

    testWidgets('wrong credentials show a generic error and stay on login', (
      tester,
    ) async {
      await boot(tester);
      await openLogin(tester);

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

      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
    });
  });

  group('sign-up flow', () {
    Finder otp() => find.byType(EditableText);

    /// Stops the resend countdown of an unfinished flow, which is a live
    /// timer the test framework would flag.
    void abandonFlow() => locator<SignUpFlowViewModel>().reset();

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
    }

    Future<void> enterEmail(WidgetTester tester, String email) async {
      await tester.enterText(field('Correo electrónico'), email);
      await tapText(tester, 'Siguiente');
    }

    Future<void> enterCode(WidgetTester tester, String code) async {
      await tester.enterText(otp(), code);
      await tester.pumpAndSettle();
    }

    Future<void> enterPassword(
      WidgetTester tester, {
      bool remember = true,
    }) async {
      await tester.enterText(field('Contraseña'), 'Abcdef1!');
      if (!remember) await tester.tap(find.text('Recordar sesión'));
      await tapText(tester, 'Siguiente');
    }

    Future<void> enterName(WidgetTester tester) async {
      await tester.enterText(field('Nombre completo'), 'Lucía Gómez');
      await tapText(tester, 'Siguiente');
    }

    Future<void> enterUsername(WidgetTester tester, String username) async {
      await tester.enterText(field('Nombre de usuario'), username);
      // The check waits for the typing to pause, then asks the backend.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tapText(tester, 'Siguiente');
    }

    Future<void> reachTerms(
      WidgetTester tester, {
      bool remember = true,
    }) async {
      await boot(tester);
      await tapText(tester, 'Empezar');
      await enterEmail(tester, 'lucia@test.com');
      await enterCode(tester, MockAuthBackend.confirmationCode);
      await enterPassword(tester, remember: remember);
      await enterName(tester);
      await enterUsername(tester, 'lucia');
    }

    testWidgets('creates an account through every screen and lands on home', (
      tester,
    ) async {
      await boot(tester);
      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);

      await tapText(tester, 'Empezar');
      expect(find.text('¿Cuál es tu correo electrónico?'), findsOneWidget);
      await enterEmail(tester, 'lucia@test.com');
      expect(find.text('Escribe el código de confirmación'), findsOneWidget);
      await enterCode(tester, MockAuthBackend.confirmationCode);
      expect(find.text('Crea una contraseña'), findsOneWidget);
      await enterPassword(tester);
      expect(find.text('¿Cómo te llamas?'), findsOneWidget);
      await enterName(tester);
      expect(find.text('Elige un nombre de usuario'), findsOneWidget);
      await enterUsername(tester, 'lucia');
      expect(find.text('Acepta los términos y políticas'), findsOneWidget);
      await tapText(tester, 'Acepto');
      expect(find.text('Agrega una foto de perfil'), findsOneWidget);
      await tapText(tester, 'Omitir');
      expect(find.text('Te damos la bienvenida, @lucia'), findsOneWidget);
      await tapText(tester, 'Continuar');

      expect(find.text('Hola, Lucía Gómez'), findsOneWidget);
      expect(storage.values['auth.user'], isNotNull);
    });

    testWidgets('the new account can sign in again', (tester) async {
      await reachTerms(tester);
      await tapText(tester, 'Acepto');
      await tapText(tester, 'Omitir');
      await tapText(tester, 'Continuar');
      await tester.tap(find.text('Ajustes'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Cerrar sesión'), 200);
      await tapText(tester, 'Cerrar sesión');

      await tester.enterText(
        field('Correo electrónico'),
        'lucia@test.com',
      );
      await tester.enterText(field('Contraseña'), 'Abcdef1!');
      await tapText(tester, 'Entrar');

      expect(find.text('Hola, Lucía Gómez'), findsOneWidget);
    });

    testWidgets('an unchecked "remember me" leaves nothing on the device', (
      tester,
    ) async {
      await reachTerms(tester, remember: false);
      await tapText(tester, 'Acepto');
      await tapText(tester, 'Omitir');
      await tapText(tester, 'Continuar');

      expect(find.text('Hola, Lucía Gómez'), findsOneWidget);
      expect(storage.values, isEmpty);

      // "Restart" the app: the session is gone.
      await tester.pumpWidget(const SizedBox());
      await boot(tester);
      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
    });

    testWidgets('a registered e-mail is refused on the first step', (
      tester,
    ) async {
      await boot(tester);
      await tapText(tester, 'Empezar');

      await enterEmail(tester, MockAuthBackend.demoEmail);

      expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
      expect(find.text('¿Cuál es tu correo electrónico?'), findsOneWidget);
    });

    testWidgets('a wrong code is refused and can be retyped', (tester) async {
      await boot(tester);
      await tapText(tester, 'Empezar');
      await enterEmail(tester, 'lucia@test.com');

      await enterCode(tester, '000000');
      expect(find.text('El código no es correcto'), findsOneWidget);
      expect(find.text('Escribe el código de confirmación'), findsOneWidget);

      await enterCode(tester, MockAuthBackend.confirmationCode);
      expect(find.text('Crea una contraseña'), findsOneWidget);
      abandonFlow();
    });

    testWidgets('a taken username is refused before continuing', (
      tester,
    ) async {
      await boot(tester);
      await tapText(tester, 'Empezar');
      await enterEmail(tester, 'lucia@test.com');
      await enterCode(tester, MockAuthBackend.confirmationCode);
      await enterPassword(tester);
      await enterName(tester);

      await enterUsername(tester, MockAuthBackend.demoUsername);

      expect(find.text('Ese nombre de usuario ya está en uso'), findsOneWidget);
      expect(find.text('Elige un nombre de usuario'), findsOneWidget);
      abandonFlow();
    });

    testWidgets('the arrow goes back and keeps what was typed', (tester) async {
      await boot(tester);
      await tapText(tester, 'Empezar');
      await enterEmail(tester, 'lucia@test.com');
      await enterCode(tester, MockAuthBackend.confirmationCode);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(find.text('¿Cuál es tu correo electrónico?'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(
              find.descendant(
                of: field('Correo electrónico'),
                matching: find.byType(EditableText),
              ),
            )
            .controller
            .text,
        'lucia@test.com',
      );
      // Returning to a confirmed address does not ask for another code.
      await tapText(tester, 'Siguiente');
      expect(find.text('Escribe el código de confirmación'), findsOneWidget);
      abandonFlow();
    });

    testWidgets('"Ya tengo cuenta" leaves the sign-up for the sign-in', (
      tester,
    ) async {
      await boot(tester);
      await tapText(tester, 'Empezar');

      await tapText(tester, 'Ya tengo cuenta');

      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('the sign-in offers to create an account', (tester) async {
      await boot(tester);
      await openLogin(tester);

      await tapText(tester, '¿No tienes cuenta? Crear cuenta');

      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
    });

    testWidgets('the terms text opens from the terms step', (tester) async {
      await reachTerms(tester);

      await tapText(tester, 'Leer los términos y políticas');

      expect(find.text('Términos y políticas'), findsOneWidget);
      expect(find.textContaining('No es un documento legal'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();
      expect(find.text('Acepta los términos y políticas'), findsOneWidget);
      abandonFlow();
    });

    testWidgets('deep links cannot skip steps', (tester) async {
      await boot(tester);

      locator<GoRouter>().go(AppRoutes.signUpTerms);
      await tester.pumpAndSettle();

      expect(find.text('Organiza tus tareas, sin ruido'), findsOneWidget);
    });
  });
}
