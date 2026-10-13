import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/usecases/send_confirmation_code_use_case.dart';
import 'package:demo/features/auth/domain/usecases/verify_confirmation_code_use_case.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/views/sign_up_code_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import 'sign_up_harness.dart';

void main() {
  late SignUpHarness harness;

  setUp(() async {
    harness = SignUpHarness();
    await harness.register();
  });

  tearDown(() async {
    harness.flow.dispose();
    await harness.dispose();
  });

  /// Gets the flow to the code step, as if the e-mail had just been sent.
  Future<void> reachCodeStep() async {
    harness.flow.start();
    harness.flow.forms.email.control(SignUpForms.emailField).value =
        'lucia@test.com';
    await harness.flow.submitEmail();
    clearInteractions(harness.navigation);
    clearInteractions(harness.sendCode);
  }

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    await reachCodeStep();
    await harness.pump(
      tester,
      const SignUpCodeView(),
      locale: locale,
      dark: dark,
    );
  }

  /// Types into the hidden field of the code input.
  Future<void> typeCode(WidgetTester tester, String digits) async {
    await tester.enterText(find.byType(EditableText), digits);
    await tester.pump();
  }

  group('SignUpCodeView', () {
    testWidgets('names the address the code was sent to', (tester) async {
      await pumpView(tester);

      expect(find.text('Escribe el código de confirmación'), findsOneWidget);
      expect(
        find.text(
          'Ingresa el código de 6 dígitos que enviamos a lucia@test.com.',
        ),
        findsOneWidget,
      );
      harness.flow.reset();
    });

    testWidgets('announces the code input as one text field', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpView(tester);

      expect(
        find.bySemanticsLabel('Código de confirmación, 0 de 6 dígitos'),
        findsOneWidget,
      );
      handle.dispose();
      harness.flow.reset();
    });

    testWidgets('the sixth digit verifies the code and moves on', (
      tester,
    ) async {
      await pumpView(tester);

      await typeCode(tester, '123456');
      await tester.pumpAndSettle();

      final params =
          verify(harness.verifyCode(captureAny)).captured.single
              as VerifyCodeParams;
      expect(params.email, 'lucia@test.com');
      expect(params.code, '123456');
      verify(harness.navigation.push<void>(AppRoutes.signUpPassword)).called(1);
      harness.flow.reset();
    });

    testWidgets('fewer than six digits do not submit by themselves', (
      tester,
    ) async {
      await pumpView(tester);

      await typeCode(tester, '123');
      await tester.pumpAndSettle();

      verifyZeroInteractions(harness.verifyCode);
      harness.flow.reset();
    });

    testWidgets('the button reports an incomplete code', (tester) async {
      await pumpView(tester);
      await typeCode(tester, '123');

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      verifyZeroInteractions(harness.verifyCode);
      harness.flow.reset();
    });

    testWidgets('a wrong code shows the error and clears the boxes', (
      tester,
    ) async {
      when(harness.verifyCode(any)).thenAnswer(
        (_) async => left(const ServerFailure('invalid_code')),
      );
      await pumpView(tester);

      await typeCode(tester, '000000');
      await tester.pumpAndSettle();

      expect(find.text('El código no es correcto'), findsOneWidget);
      expect(
        SignUpForms.textOf(harness.flow.forms.code, SignUpForms.codeField),
        isEmpty,
      );
      verifyNever(harness.navigation.push<void>(AppRoutes.signUpPassword));
      harness.flow.reset();
    });

    testWidgets('an expired code explains it', (tester) async {
      when(harness.verifyCode(any)).thenAnswer(
        (_) async => left(const ServerFailure('code_expired')),
      );
      await pumpView(tester);

      await typeCode(tester, '123456');
      await tester.pumpAndSettle();

      expect(find.text('El código caducó. Pide uno nuevo.'), findsOneWidget);
      harness.flow.reset();
    });

    testWidgets('too many attempts asks for a new code', (tester) async {
      when(harness.verifyCode(any)).thenAnswer(
        (_) async => left(const ServerFailure('too_many_attempts')),
      );
      await pumpView(tester);

      await typeCode(tester, '123456');
      await tester.pumpAndSettle();

      expect(
        find.text('Demasiados intentos. Pide un código nuevo.'),
        findsOneWidget,
      );
      harness.flow.reset();
    });

    testWidgets('the resend button counts down and stays disabled', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('Podrás pedir otro código en 30 s'), findsOneWidget);
      expect(
        tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull,
      );

      await tester.pump(const Duration(seconds: 10));
      expect(find.text('Podrás pedir otro código en 20 s'), findsOneWidget);
      harness.flow.reset();
    });

    testWidgets('after the wait the button asks for a new code', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.pump(const Duration(seconds: 30));
      expect(find.text('No recibí el código'), findsOneWidget);
      await tester.tap(find.text('No recibí el código'));
      await tester.pumpAndSettle();

      final params =
          verify(harness.sendCode(captureAny)).captured.single
              as SendCodeParams;
      expect(params.isResend, isTrue);
      expect(find.text('Podrás pedir otro código en 30 s'), findsOneWidget);
      harness.flow.reset();
    });

    testWidgets('the arrow goes back to change the address', (tester) async {
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();

      verify(harness.navigation.pop<Object?>()).called(1);
      harness.flow.reset();
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      expect(find.text('Enter the confirmation code'), findsOneWidget);
      expect(
        find.text('Enter the 6-digit code we sent to lucia@test.com.'),
        findsOneWidget,
      );
      expect(find.text('You can request another code in 30 s'), findsOneWidget);
      harness.flow.reset();
    });
  });
}
