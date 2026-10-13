import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/views/sign_up_password_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  Finder field() => find.widgetWithText(TextField, 'Contraseña');

  Future<void> pumpView(
    WidgetTester tester, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    await harness.pump(
      tester,
      const SignUpPasswordView(),
      locale: locale,
      dark: dark,
    );
  }

  bool obscured(WidgetTester tester) => tester
      .widget<EditableText>(
        find.descendant(of: field(), matching: find.byType(EditableText)),
      )
      .obscureText;

  group('SignUpPasswordView', () {
    testWidgets('shows the rules and the "remember me" option', (tester) async {
      await pumpView(tester);

      expect(find.text('Crea una contraseña'), findsOneWidget);
      expect(find.textContaining('al menos 8 caracteres'), findsOneWidget);
      expect(find.text('Recordar sesión'), findsOneWidget);
      expect(
        find.text(
          'Si lo desactivas, tendrás que iniciar sesión cada vez que abras la app.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('hides the screen from captures only while it is open', (
      tester,
    ) async {
      await pumpView(tester);
      verify(harness.protection.enable()).called(1);

      await tester.pumpWidget(const SizedBox());

      verify(harness.protection.disable()).called(1);
    });

    testWidgets('the password is hidden and can be revealed', (tester) async {
      await pumpView(tester);
      expect(obscured(tester), isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(obscured(tester), isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('asks the password manager for a new password', (tester) async {
      await pumpView(tester);

      final input = tester.widget<EditableText>(
        find.descendant(of: field(), matching: find.byType(EditableText)),
      );

      expect(input.autofillHints, contains(AutofillHints.newPassword));
    });

    testWidgets('a weak password shows the rule and does not advance', (
      tester,
    ) async {
      await pumpView(tester);

      await tester.enterText(field(), 'weak');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Usa al menos 8 caracteres con mayúscula, minúscula, número y símbolo',
        ),
        findsOneWidget,
      );
      verifyNever(harness.navigation.push<void>(AppRoutes.signUpName));
    });

    testWidgets('a strong password opens the name step', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'Str0ng!Pass');
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      verify(harness.navigation.push<void>(AppRoutes.signUpName)).called(1);
    });

    testWidgets('submits from the keyboard action', (tester) async {
      await pumpView(tester);

      await tester.enterText(field(), 'Str0ng!Pass');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(harness.navigation.push<void>(AppRoutes.signUpName)).called(1);
    });

    testWidgets('"remember me" starts checked and toggles on tap', (
      tester,
    ) async {
      await pumpView(tester);
      bool checked() => tester.widget<Checkbox>(find.byType(Checkbox)).value!;
      expect(checked(), isTrue);

      await tester.tap(find.text('Recordar sesión'));
      await tester.pump();

      expect(checked(), isFalse);
      expect(
        harness.flow.forms.password.control(SignUpForms.rememberField).value,
        isFalse,
      );
    });

    testWidgets('the whole option row is a labelled checkbox', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpView(tester);

      expect(
        find.bySemanticsLabel('Recordar sesión'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      expect(find.text('Create a password'), findsOneWidget);
      expect(find.text('Remember me'), findsOneWidget);
    });
  });
}
