import 'package:demo/app/locator.dart';
import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/register_use_case.dart';
import 'package:demo/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:demo/features/auth/presentation/views/register_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../helpers/auth_mocks.dart';

void main() {
  late MockRegisterUseCase register;
  late MockNavigationService navigation;
  late SessionService session;

  setUp(() async {
    await resetLocator();
    register = MockRegisterUseCase();
    navigation = MockNavigationService();
    session = SessionService();
    locator.registerFactory<RegisterViewModel>(
      () => RegisterViewModel(
        register: register,
        navigation: navigation,
        session: session,
        screenProtection: MockScreenProtection(),
      ),
    );
  });

  tearDown(resetLocator);

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> pumpView(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpLocalized(tester, const RegisterView());
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(
    WidgetTester tester, {
    String password = 'Abcdef1!',
    String confirm = 'Abcdef1!',
    String phone = '',
  }) async {
    await tester.enterText(field('Nombre'), 'Ana Pérez');
    await tester.enterText(field('Correo electrónico'), 'ana@test.com');
    await tester.enterText(field('Teléfono (opcional)'), phone);
    await tester.enterText(field('Contraseña'), password);
    await tester.enterText(field('Confirmar contraseña'), confirm);
  }

  group('RegisterView', () {
    testWidgets('renders every field', (tester) async {
      await pumpView(tester);

      for (final label in [
        'Nombre',
        'Correo electrónico',
        'Teléfono (opcional)',
        'Contraseña',
        'Confirmar contraseña',
      ]) {
        expect(field(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('shows validation messages for an empty submit', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio'), findsWidgets);
      verifyZeroInteractions(register);
    });

    testWidgets('explains weak passwords and mismatches', (tester) async {
      await pumpView(tester);

      await fillForm(tester, password: 'abc', confirm: 'xyz');
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.textContaining('al menos 8 caracteres'), findsOneWidget);
      expect(find.text('Los valores no coinciden'), findsOneWidget);
      verifyZeroInteractions(register);
    });

    testWidgets('rejects an invalid phone number', (tester) async {
      await pumpView(tester);

      await fillForm(tester, phone: 'abc');
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un teléfono válido'), findsOneWidget);
    });

    testWidgets('registers and goes home with valid data', (tester) async {
      when(register(any)).thenAnswer(
        (_) async => right(
          const User(id: '1', name: 'Ana Pérez', email: 'ana@test.com'),
        ),
      );
      await pumpView(tester);

      await fillForm(tester, phone: '3001234567');
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      final params =
          verify(register(captureAny)).captured.single as RegisterParams;
      expect(params.name, 'Ana Pérez');
      expect(params.phone, '3001234567');
      expect(session.isAuthenticated, isTrue);
      verify(navigation.go(AppRoutes.home)).called(1);
    });

    testWidgets('shows a specific message when the e-mail is taken', (
      tester,
    ) async {
      when(register(any))
          .thenAnswer((_) async => left(const ServerFailure('email_taken')));
      await pumpView(tester);

      await fillForm(tester);
      await tester.tap(find.text('Registrarme'));
      await tester.pumpAndSettle();

      expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
      expect(session.isAuthenticated, isFalse);
    });

    testWidgets('goes back to login from the back button and the link', (
      tester,
    ) async {
      when(navigation.canPop).thenReturn(true);
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.tap(find.textContaining('Iniciar sesión').last);
      await tester.pump();

      verify(navigation.pop<void>()).called(2);
    });
  });
}
