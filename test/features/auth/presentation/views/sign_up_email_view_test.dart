import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/widgets/email_suffix_suggestions.dart';
import 'package:demo/features/auth/domain/usecases/send_confirmation_code_use_case.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/views/sign_up_email_view.dart';
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
    harness.flow.start();
    clearInteractions(harness.navigation);
  });

  tearDown(() async {
    harness.flow.dispose();
    await harness.dispose();
  });

  Finder field() => find.widgetWithText(TextField, 'Correo electrónico');

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    await harness.pump(
      tester,
      const SignUpEmailView(),
      locale: locale,
      dark: dark,
    );
  }

  group('SignUpEmailView', () {
    testWidgets('shows the question, the field and the actions', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('¿Cuál es tu correo electrónico?'), findsOneWidget);
      expect(find.textContaining('Te enviaremos un código'), findsOneWidget);
      expect(field(), findsOneWidget);
      expect(find.text('Siguiente'), findsOneWidget);
      expect(find.text('Ya tengo cuenta'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    });

    testWidgets('asks for an e-mail keyboard and autofill', (tester) async {
      await pumpView(tester);

      final input = tester.widget<EditableText>(
        find.descendant(of: field(), matching: find.byType(EditableText)),
      );

      expect(input.keyboardType, TextInputType.emailAddress);
      expect(input.autofillHints, contains(AutofillHints.email));
      expect(input.focusNode.hasFocus, isTrue);
    });

    testWidgets('a malformed address shows the error and sends nothing', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.enterText(field(), 'nope');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresa un correo electrónico válido'), findsOneWidget);
      verifyZeroInteractions(harness.sendCode);
    });

    testWidgets('an empty field is required', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.text('Este campo es obligatorio'), findsOneWidget);
    });

    testWidgets('sends the code and moves to the code step', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'lucia@test.com');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      final params =
          verify(harness.sendCode(captureAny)).captured.single
              as SendCodeParams;
      expect(params.email, 'lucia@test.com');
      verify(harness.navigation.push<void>(AppRoutes.signUpCode)).called(1);
      // The resend countdown is a live timer; stop it before the test ends.
      harness.flow.reset();
    });

    testWidgets('submits from the keyboard action', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'lucia@test.com');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pumpAndSettle();

      verify(harness.sendCode(any)).called(1);
      harness.flow.reset();
    });

    testWidgets('shows a spinner in the button while sending', (tester) async {
      await pumpView(tester);
      await tester.enterText(field(), 'lucia@test.com');
      final pending = Completer<Either<Failure, Unit>>();
      when(harness.sendCode(any)).thenAnswer((_) => pending.future);

      await tester.tap(find.text('Siguiente'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Siguiente'), findsNothing);

      pending.complete(right(unit));
      await tester.pumpAndSettle();
      harness.flow.reset();
    });

    testWidgets('a registered address shows a specific message', (
      tester,
    ) async {
      when(harness.sendCode(any)).thenAnswer(
        (_) async => left(const ServerFailure('email_taken')),
      );
      await pumpView(tester);

      await tester.enterText(field(), 'lucia@test.com');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('step_error')), findsOneWidget);
      expect(find.text('Ya existe una cuenta con ese correo'), findsOneWidget);
      verifyNever(harness.navigation.push<void>(AppRoutes.signUpCode));
    });

    testWidgets('a network failure shows the generic offline message', (
      tester,
    ) async {
      when(
        harness.sendCode(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await pumpView(tester);

      await tester.enterText(field(), 'lucia@test.com');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay conexión. Revisa tu red e inténtalo de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('the arrow goes back and the link opens sign-in', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pump();
      verify(harness.navigation.pop<Object?>()).called(1);

      await tester.tap(find.text('Ya tengo cuenta'));
      await tester.pump();
      verify(harness.navigation.go(AppRoutes.login)).called(1);
    });

    testWidgets('suggests domains above the keyboard and applies one', (
      tester,
    ) async {
      openKeyboard(tester);
      await pumpView(tester);

      await tester.enterText(field(), 'lucia');
      await tester.pump();

      expect(find.byType(EmailSuffixSuggestions), findsOneWidget);
      expect(find.text('@gmail.com'), findsOneWidget);

      await tester.tap(find.text('@gmail.com'));
      await tester.pump();

      expect(
        SignUpForms.textOf(harness.flow.forms.email, SignUpForms.emailField),
        'lucia@gmail.com',
      );
    });

    testWidgets('hides the sign-in link while the keyboard is open', (
      tester,
    ) async {
      openKeyboard(tester);
      await pumpView(tester);

      expect(find.text('Ya tengo cuenta'), findsNothing);
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      expect(find.text("What's your e-mail address?"), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('I already have an account'), findsOneWidget);
    });
  });
}
