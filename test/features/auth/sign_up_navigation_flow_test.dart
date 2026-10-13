import 'dart:async';

import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/app/router/auth_guard.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/network/mock/mock_api_interceptor.dart';
import 'package:demo/core/security/screen_protection.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/data/datasources/mock_auth_backend.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:demo/features/auth/presentation/models/username_status.dart';
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:demo/features/tasks/data/datasources/mock_tasks_backend.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/in_memory_secure_storage.dart';
import 'helpers/auth_mocks.dart';

/// The ViewModel, the route guard, the progress tracker, the real router and
/// the data stack (with the in-app mock backend, answering instantly) working
/// together. The step screens are never built: the tests read the router's
/// location.
void main() {
  late SessionService session;
  late SignUpProgress progress;
  late InMemorySecureStorage storage;
  late GoRouter router;
  late SignUpFlowViewModel flow;
  late WidgetTester tester;

  const config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://api.test',
    useMockApi: true,
    pinningEnabled: false,
    pinnedSha256: [],
    rootPolicy: SecurityPolicy.warn,
  );

  Future<void> boot() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await resetLocator();
    storage = InMemorySecureStorage();
    session = SessionService();
    progress = SignUpProgress();
    Widget page(String name) => Text(name);
    router = GoRouter(
      initialLocation: AppRoutes.welcome,
      redirect: AuthGuard(
        session,
        signUpProgress: progress,
        signedOutLocation: AppRoutes.welcome,
      ).redirect,
      refreshListenable: session,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => page('home')),
        GoRoute(path: AppRoutes.welcome, builder: (_, _) => page('welcome')),
        GoRoute(path: AppRoutes.login, builder: (_, _) => page('login')),
        GoRoute(path: AppRoutes.terms, builder: (_, _) => page('terms-text')),
        for (final step in SignUpStep.values)
          GoRoute(path: step.route, builder: (_, _) => page(step.name)),
      ],
    );
    final backend = MockAuthBackend();
    await setupLocator(
      router: router,
      config: config,
      session: session,
      signUpProgress: progress,
      mockRoutes: [...backend.routes, ...MockTasksBackend().routes],
    );
    locator
      ..unregister<SecureStorage>()
      ..registerSingleton<SecureStorage>(storage)
      ..unregister<ScreenProtection>()
      ..registerSingleton<ScreenProtection>(MockScreenProtection())
      // Same mock backend, but without the artificial latency.
      ..unregister<Dio>()
      ..registerLazySingleton<Dio>(
        () => Dio(BaseOptions(baseUrl: config.apiBaseUrl))
          ..interceptors.add(
            MockApiInterceptor(
              routes: backend.routes,
              settings: const MockApiSettings(latency: Duration.zero),
            ),
          ),
      );
    flow = locator<SignUpFlowViewModel>();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
  }

  void flowTest(String name, Future<void> Function() body) {
    testWidgets(name, (t) async {
      tester = t;
      await boot();
      await body();
    });
  }

  /// Runs [action] with real time (the mock backend awaits timers) and then
  /// lets the router apply the navigation it requested.
  Future<void> act(FutureOr<void> Function() action) async {
    await tester.runAsync(() async => action());
    await tester.pumpAndSettle();
  }

  tearDown(resetLocator);

  String location() =>
      router.routerDelegate.currentConfiguration.last.matchedLocation;

  void type(FormGroup group, String field, Object? value) =>
      group.control(field).value = value;

  /// Lets the form's asynchronous change events reach the ViewModel.
  Future<void> pumpEvents() async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  }

  Future<void> submitEmail([String email = 'lucia@test.com']) async {
    type(flow.forms.email, SignUpForms.emailField, email);
    await act(flow.submitEmail);
  }

  Future<void> submitCode() async {
    type(
      flow.forms.code,
      SignUpForms.codeField,
      MockAuthBackend.confirmationCode,
    );
    await act(flow.submitCode);
  }

  Future<void> reachTerms({
    String username = 'lucia',
    bool remember = true,
  }) async {
    await act(flow.start);
    await submitEmail();
    await submitCode();
    type(flow.forms.password, SignUpForms.passwordField, 'Abcdef1!');
    type(flow.forms.password, SignUpForms.rememberField, remember);
    await act(flow.submitPassword);
    type(flow.forms.name, SignUpForms.nameField, 'Lucía Gómez');
    await act(flow.submitName);
    type(flow.forms.username, SignUpForms.usernameField, username);
    await pumpEvents();
    await act(flow.submitUsername);
  }

  /// Creates [username] through the API, as another person would.
  Future<void> registerSomeoneElse(String username) async {
    final dio = locator<Dio>();
    const email = 'other@test.com';
    await dio.post<void>(AuthEndpoints.signUpEmail, data: {'email': email});
    final verified = await dio.post<Map<String, dynamic>>(
      AuthEndpoints.signUpVerify,
      data: {'email': email, 'code': MockAuthBackend.confirmationCode},
    );
    await dio.post<void>(
      AuthEndpoints.register,
      data: {
        'verificationToken': verified.data?['verificationToken'],
        'name': 'Other',
        'username': username,
        'password': 'Abcdef1!',
      },
    );
  }

  flowTest('walks every step, in order, and enters the app', () async {
    expect(location(), AppRoutes.welcome);

    await act(flow.start);
    expect(location(), AppRoutes.signUpEmail);

    await submitEmail();
    expect(location(), AppRoutes.signUpCode);

    await submitCode();
    expect(location(), AppRoutes.signUpPassword);

    type(flow.forms.password, SignUpForms.passwordField, 'Abcdef1!');
    await act(flow.submitPassword);
    expect(location(), AppRoutes.signUpName);

    type(flow.forms.name, SignUpForms.nameField, 'Lucía Gómez');
    await act(flow.submitName);
    expect(location(), AppRoutes.signUpUsername);

    type(flow.forms.username, SignUpForms.usernameField, 'lucia');
    await pumpEvents();
    await act(flow.submitUsername);
    expect(flow.state.usernameStatus, UsernameStatus.available);
    expect(location(), AppRoutes.signUpTerms);

    await act(flow.acceptTerms);
    expect(location(), AppRoutes.signUpAvatar);
    expect(session.isAuthenticated, isFalse);
    expect(flow.state.user?.username, 'lucia');

    await act(flow.skipAvatar);
    expect(location(), AppRoutes.signUpDone);

    await act(flow.finish);
    expect(location(), AppRoutes.home);
    expect(session.isAuthenticated, isTrue);
    expect(session.isPersistent, isTrue);
  });

  flowTest(
    'back goes to the previous step and forward does not resend',
    () async {
      await act(flow.start);
      await submitEmail();

      await act(flow.back);
      expect(location(), AppRoutes.signUpEmail);

      await act(flow.submitEmail);
      expect(location(), AppRoutes.signUpCode);
    },
  );

  flowTest('the guard refuses to skip ahead with a deep link', () async {
    await act(flow.start);

    router.go(AppRoutes.signUpTerms);
    await tester.pumpAndSettle();

    expect(location(), AppRoutes.signUpEmail);
  });

  flowTest('steps are closed before the flow starts', () async {
    router.go(AppRoutes.signUpPassword);
    await tester.pumpAndSettle();

    expect(location(), AppRoutes.welcome);
  });

  flowTest('a wrong code keeps the person on the code step', () async {
    await act(flow.start);
    await submitEmail();

    type(flow.forms.code, SignUpForms.codeField, '000000');
    await act(flow.submitCode);

    expect(location(), AppRoutes.signUpCode);
    expect(flow.failure?.code, 'invalid_code');
  });

  flowTest('a registered e-mail keeps the person on the e-mail step', () async {
    await act(flow.start);

    await submitEmail(MockAuthBackend.demoEmail);

    expect(location(), AppRoutes.signUpEmail);
    expect(flow.failure?.code, 'email_taken');
  });

  flowTest(
    'a username taken meanwhile sends the person back to that step',
    () async {
      await reachTerms();
      expect(location(), AppRoutes.signUpTerms);
      await tester.runAsync(() => registerSomeoneElse('lucia'));

      await act(flow.acceptTerms);

      expect(location(), AppRoutes.signUpUsername);
      expect(flow.state.usernameStatus, UsernameStatus.taken);
      expect(session.isAuthenticated, isFalse);

      // Picking another name lets the same confirmation finish the sign-up.
      type(flow.forms.username, SignUpForms.usernameField, 'lucia2');
      await pumpEvents();
      await act(flow.submitUsername);
      await act(flow.acceptTerms);
      expect(location(), AppRoutes.signUpAvatar);
    },
  );

  flowTest('after the account exists the earlier steps stay closed', () async {
    await reachTerms();
    await act(flow.acceptTerms);

    router.go(AppRoutes.signUpTerms);
    await tester.pumpAndSettle();

    expect(location(), AppRoutes.signUpAvatar);
  });

  flowTest('a session that is not remembered leaves nothing behind', () async {
    await reachTerms(remember: false);
    await act(flow.acceptTerms);
    await act(flow.skipAvatar);

    await act(flow.finish);

    expect(session.isAuthenticated, isTrue);
    expect(session.isPersistent, isFalse);
    expect(storage.values, isEmpty);
  });

  flowTest('a remembered session is persisted', () async {
    await reachTerms();

    await act(flow.acceptTerms);

    expect(storage.values['auth.user'], isNotNull);
  });

  flowTest('starting again forgets the previous attempt', () async {
    await reachTerms();

    await act(flow.start);

    expect(location(), AppRoutes.signUpEmail);
    expect(flow.state.email, isEmpty);
    router.go(AppRoutes.signUpTerms);
    await tester.pumpAndSettle();
    expect(location(), AppRoutes.signUpEmail);
  });
}
