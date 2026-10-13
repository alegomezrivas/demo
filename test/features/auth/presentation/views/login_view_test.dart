import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:demo/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:demo/features/auth/presentation/views/login_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../helpers/auth_mocks.dart';

void main() {
  late MockLoginUseCase login;
  late MockNavigationService navigation;
  late MockScreenProtection protection;
  late SessionService session;

  setUp(() async {
    await resetLocator();
    login = MockLoginUseCase();
    navigation = MockNavigationService();
    protection = MockScreenProtection();
    session = SessionService();
    locator.registerFactory<LoginViewModel>(
      () => LoginViewModel(
        login: login,
        navigation: navigation,
        session: session,
        screenProtection: protection,
      ),
    );
  });

  tearDown(resetLocator);

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
  }) async {
    await pumpLocalized(tester, const LoginView(), locale: locale);
    await tester.pumpAndSettle();
  }

  group('LoginView', () {
    testWidgets('shows the localized form and protects the screen', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('Iniciar sesión'), findsOneWidget);
      expect(field('Correo electrónico'), findsOneWidget);
      expect(field('Contraseña'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      verify(protection.enable()).called(1);
    });

    testWidgets('offers "remember me", checked by default', (tester) async {
      await pumpView(tester);

      expect(find.text('Recordar sesión'), findsOneWidget);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    });

    testWidgets('unchecking "remember me" signs in without remembering', (
      tester,
    ) async {
      when(login(any)).thenAnswer(
        (_) async => right(
          const User(
            id: '1',
            name: 'Ana',
            email: 'ana@test.com',
            username: 'ana',
          ),
        ),
      );
      await pumpView(tester);

      await tester.tap(find.text('Recordar sesión'));
      await tester.enterText(field('Correo electrónico'), 'ana@test.com');
      await tester.enterText(field('Contraseña'), 'secret');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      final params = verify(login(captureAny)).captured.single as LoginParams;
      expect(params.rememberSession, isFalse);
      expect(session.isPersistent, isFalse);
    });

    testWidgets('the link and the arrow lead to the welcome screen', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.textContaining('Crear cuenta'));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      verify(navigation.go(AppRoutes.welcome)).called(2);
    });

    testWidgets('is available in English', (tester) async {
      await pumpView(tester, locale: const Locale('en'));

      expect(field('Email'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
    });

    testWidgets('shows required errors and does not call the use case', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio'), findsNWidgets(2));
      verifyZeroInteractions(login);
    });

    testWidgets('shows the e-mail format error', (tester) async {
      await pumpView(tester);

      await tester.enterText(field('Correo electrónico'), 'nope');
      await tester.enterText(field('Contraseña'), 'pw');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
      verifyZeroInteractions(login);
    });

    testWidgets('submits valid credentials and goes home', (tester) async {
      when(login(any)).thenAnswer(
        (_) async => right(
          const User(
            id: '1',
            name: 'Ana',
            email: 'ana@test.com',
            username: 'ana',
          ),
        ),
      );
      await pumpView(tester);

      await tester.enterText(field('Correo electrónico'), 'ana@test.com');
      await tester.enterText(field('Contraseña'), 'secret');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      final params = verify(login(captureAny)).captured.single as LoginParams;
      expect(params.email, 'ana@test.com');
      expect(params.password, 'secret');
      expect(session.isAuthenticated, isTrue);
      verify(navigation.go(AppRoutes.home)).called(1);
    });

    testWidgets('shows a generic message for invalid credentials', (
      tester,
    ) async {
      when(
        login(any),
      ).thenAnswer((_) async => left(const UnauthorizedFailure()));
      await pumpView(tester);

      await tester.enterText(field('Correo electrónico'), 'ana@test.com');
      await tester.enterText(field('Contraseña'), 'wrong');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('step_error')), findsOneWidget);
      expect(find.text('Correo o contraseña incorrectos'), findsOneWidget);
    });

    testWidgets('submits from the keyboard action of the password field', (
      tester,
    ) async {
      when(login(any)).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);

      await tester.enterText(field('Correo electrónico'), 'ana@test.com');
      await tester.enterText(field('Contraseña'), 'pw');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(login(any)).called(1);
      expect(
        find.text('No hay conexión. Revisa tu red e inténtalo de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('toggles password visibility', (tester) async {
      await pumpView(tester);
      bool obscured() => tester
          .widget<EditableText>(
            find.descendant(
              of: field('Contraseña'),
              matching: find.byType(EditableText),
            ),
          )
          .obscureText;

      expect(obscured(), isTrue);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(obscured(), isFalse);
    });
  });
}
