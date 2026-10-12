import 'package:demo/app/app.dart';
import 'package:demo/app/locator.dart';
import 'package:demo/app/preferences_bootstrap.dart';
import 'package:demo/app/router/app_router.dart';
import 'package:demo/app/router/auth_guard.dart';
import 'package:demo/app/session_bootstrap.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/security/biometric_authenticator.dart';
import 'package:demo/core/security/device_integrity_service.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/widgets/integrity_gate/integrity_gate_view_model.dart';
import 'package:demo/features/auth/data/datasources/mock_auth_backend.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/settings/domain/entities/app_language.dart';
import 'package:demo/features/settings/domain/entities/app_theme_mode.dart';
import 'package:demo/features/settings/domain/usecases/get_settings_use_case.dart';
import 'package:demo/features/settings/presentation/app_preferences.dart';
import 'package:demo/features/tasks/data/datasources/mock_tasks_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/in_memory_secure_storage.dart';
import '../../helpers/mocks.dart';
import '../auth/helpers/auth_mocks.dart';

class FakeBiometricAuthenticator implements BiometricAuthenticator {
  bool available = true;
  bool accept = true;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({required String reason}) async {
    prompts++;
    return accept;
  }
}

/// End-to-end flows over the real stack (router, shell, ViewModels, use cases,
/// repositories, Dio, mock backends, preferences); only platform plugins are
/// replaced.
void main() {
  late InMemorySecureStorage storage;
  late FakeBiometricAuthenticator biometrics;

  const config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://api.test',
    useMockApi: true,
    pinningEnabled: false,
    pinnedSha256: [],
    rootPolicy: SecurityPolicy.warn,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    storage = InMemorySecureStorage();
    biometrics = FakeBiometricAuthenticator();
  });

  tearDown(resetLocator);

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localesTestValue = [const Locale('es')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await resetLocator();

    final session = SessionService();
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
      ..registerSingleton<ScreenProtection>(MockScreenProtection())
      ..unregister<BiometricAuthenticator>()
      ..registerSingleton<BiometricAuthenticator>(biometrics);

    await loadPreferences(
      getSettings: locator<GetSettingsUseCase>(),
      preferences: locator<AppPreferences>(),
    );
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

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder listScrollable() => find.descendant(
    of: find.byType(ListView),
    matching: find.byType(Scrollable),
  );

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(
      field('Correo electrónico'),
      MockAuthBackend.demoEmail,
    );
    await tester.enterText(field('Contraseña'), MockAuthBackend.demoPassword);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
  }

  /// Lets background reloads (mock latency) finish before the test ends.
  Future<void> idle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> bootSignedIn(WidgetTester tester) async {
    await boot(tester);
    await signIn(tester);
  }

  group('dashboard', () {
    testWidgets('shows the statistics of the mock backend', (tester) async {
      await bootSignedIn(tester);

      expect(find.text('Hola, Demo User'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
      expect(find.textContaining('% completado'), findsOneWidget);
    });

    testWidgets('quick actions open the tasks tab and the creation form', (
      tester,
    ) async {
      await bootSignedIn(tester);

      await tester.tap(find.text('Ver tareas'));
      await tester.pumpAndSettle();
      expect(find.text('Buscar tareas'), findsOneWidget);

      await openTab(tester, 'Inicio');
      await tester.tap(find.widgetWithText(OutlinedButton, 'Nueva tarea'));
      await tester.pumpAndSettle();
      expect(field('Título'), findsOneWidget);
    });
  });

  group('tasks', () {
    testWidgets('lists the first page and loads the next one on scroll', (
      tester,
    ) async {
      await bootSignedIn(tester);
      await openTab(tester, 'Tareas');

      expect(find.text('Escribir pruebas unitarias #3'), findsOneWidget);
      expect(find.text('Planificar el sprint'), findsNothing);

      await tester.scrollUntilVisible(
        find.text('Preparar la demo'),
        300,
        scrollable: listScrollable(),
      );
      await tester.pumpAndSettle();

      expect(find.text('Preparar la demo'), findsOneWidget);
    });

    testWidgets('searches by text and shows the empty-filter state', (
      tester,
    ) async {
      await bootSignedIn(tester);
      await openTab(tester, 'Tareas');

      await tester.enterText(field('Buscar tareas'), 'seguridad');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Auditar la seguridad #2'), findsOneWidget);
      expect(find.text('Auditar la seguridad'), findsOneWidget);
      expect(find.text('Preparar la demo #3'), findsNothing);

      await tester.enterText(field('Buscar tareas'), 'zzz-nothing');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(
        find.text('Ninguna tarea coincide con los filtros'),
        findsOneWidget,
      );
    });

    testWidgets('filters by completion status', (tester) async {
      await bootSignedIn(tester);
      await openTab(tester, 'Tareas');

      await tester.tap(find.widgetWithText(ChoiceChip, 'Completadas'));
      await tester.pumpAndSettle();

      final checkboxes = tester.widgetList<Checkbox>(find.byType(Checkbox));
      expect(checkboxes, isNotEmpty);
      expect(checkboxes.every((c) => c.value ?? false), isTrue);
    });

    testWidgets(
      'creates a task that shows up first and updates the dashboard',
      (tester) async {
        await bootSignedIn(tester);
        await openTab(tester, 'Tareas');

        await tester.tap(find.text('Nueva tarea'));
        await tester.pumpAndSettle();
        await tester.enterText(field('Título'), 'Brand new task');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(find.text('Brand new task'), findsOneWidget);

        await openTab(tester, 'Inicio');
        expect(find.text('24'), findsOneWidget);
      },
    );

    testWidgets('edits a task through the form', (tester) async {
      await bootSignedIn(tester);
      await openTab(tester, 'Tareas');

      await tester.tap(find.text('Escribir pruebas unitarias #3'));
      await tester.pumpAndSettle();
      expect(find.text('Editar tarea'), findsOneWidget);
      await tester.enterText(field('Título'), 'Renamed task');
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      expect(find.text('Renamed task'), findsOneWidget);
      await idle(tester);

      expect(find.text('Escribir pruebas unitarias #3'), findsNothing);
    });

    testWidgets('completes a task with the checkbox', (tester) async {
      await bootSignedIn(tester);
      await openTab(tester, 'Tareas');
      bool firstDone() =>
          tester.widgetList<Checkbox>(find.byType(Checkbox)).first.value ??
          false;
      final before = firstDone();

      await tester.tap(find.byType(Checkbox).first);
      await tester.pumpAndSettle();

      await idle(tester);

      expect(firstDone(), !before);
    });

    testWidgets('deletes a task after confirmation', (tester) async {
      await bootSignedIn(tester);
      await openTab(tester, 'Tareas');

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      await idle(tester);

      expect(find.text('Escribir pruebas unitarias #3'), findsNothing);
      expect(biometrics.prompts, 0);
    });
  });

  group('settings', () {
    testWidgets(
      'switching to dark mode and English applies immediately and is saved',
      (tester) async {
        await bootSignedIn(tester);
        await openTab(tester, 'Ajustes');

        await tester.tap(
          find.byType(DropdownButton<AppThemeMode>),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Oscuro').last);
        await tester.pumpAndSettle();

        expect(
          Theme.of(tester.element(find.byType(NavigationBar))).brightness,
          Brightness.dark,
        );

        await tester.tap(
          find.byType(DropdownButton<AppLanguage>),
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('English').last);
        await tester.pumpAndSettle();

        expect(find.text('Settings'), findsWidgets);
        expect(find.text('Tasks'), findsOneWidget);

        final prefs = await SharedPreferences.getInstance();
        expect(
          prefs.getString('settings.v1'),
          allOf(contains('dark'), contains('english')),
        );
      },
    );

    testWidgets('saved preferences are restored on the next launch', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'settings.v1': '{"themeMode":"dark","language":"english","biometricConfirmation":false}',
      });

      await boot(tester);

      expect(find.text('Sign in'), findsWidgets);
      expect(
        Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
        Brightness.dark,
      );
    });

    testWidgets(
      'with biometric confirmation on, deleting requires authentication',
      (tester) async {
        await bootSignedIn(tester);
        await openTab(tester, 'Ajustes');
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(biometrics.prompts, 1);

        await openTab(tester, 'Tareas');
        biometrics.accept = false;
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Eliminar'));
        await tester.pumpAndSettle();

        expect(biometrics.prompts, 2);
        expect(find.text('Escribir pruebas unitarias #3'), findsOneWidget);

        biometrics.accept = true;
        await idle(tester);
        await tester.tap(find.byIcon(Icons.delete_outline).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Eliminar'));
        await idle(tester);

        expect(find.text('Escribir pruebas unitarias #3'), findsNothing);
      },
    );

    testWidgets(
      'the biometric switch stays off on devices without authentication',
      (tester) async {
        biometrics.available = false;
        await bootSignedIn(tester);
        await openTab(tester, 'Ajustes');

        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();

        expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
        expect(find.byKey(const Key('biometric_unavailable')), findsOneWidget);
      },
    );

    testWidgets('shows the about screen and returns', (tester) async {
      await bootSignedIn(tester);
      await openTab(tester, 'Ajustes');

      await tester.scrollUntilVisible(find.text('Acerca de'), 200);
      await tester.tap(find.text('Acerca de'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Aplicación de demostración'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.text('Cerrar sesión'), findsOneWidget);
    });
  });
}
