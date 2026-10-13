import 'dart:typed_data';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/views/sign_up_done_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
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

  /// Creates the account through the flow so the greeting has a username.
  Future<void> reachDone({Uint8List? picture}) async {
    final flow = harness.flow..start();
    flow.forms.email.control(SignUpForms.emailField).value = 'lucia@test.com';
    await flow.submitEmail();
    flow.forms.code.control(SignUpForms.codeField).value = '123456';
    await flow.submitCode();
    flow.forms.password.control(SignUpForms.passwordField).value =
        'Str0ng!Pass';
    flow.submitPassword();
    flow.forms.name.control(SignUpForms.nameField).value = 'Lucía Gómez';
    flow.submitName();
    flow.forms.username.control(SignUpForms.usernameField).value = 'lucia';
    await flow.submitUsername();
    await flow.acceptTerms();
    if (picture != null) {
      await flow.submitAvatar(picture);
    } else {
      flow.skipAvatar();
    }
    clearInteractions(harness.navigation);
  }

  Future<void> pumpView(
    WidgetTester tester, {
    Uint8List? picture,
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    usePhone(tester);
    await reachDone(picture: picture);
    await harness.pump(
      tester,
      const SignUpDoneView(),
      locale: locale,
      dark: dark,
    );
  }

  group('SignUpDoneView', () {
    testWidgets('greets the new username and has no back arrow', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.text('Te damos la bienvenida, @lucia'), findsOneWidget);
      expect(
        find.text('Tu cuenta está lista. Empieza a organizar tus tareas.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
      harness.flow.reset();
    });

    testWidgets('shows the placeholder when the picture was skipped', (
      tester,
    ) async {
      await pumpView(tester);

      expect(find.byIcon(Icons.person), findsOneWidget);
      harness.flow.reset();
    });

    testWidgets('shows the uploaded picture', (tester) async {
      final png = Uint8List.fromList(
        img.encodePng(
          img.Image(width: 20, height: 20)..clear(img.ColorRgb8(9, 9, 9)),
        ),
      );
      await pumpView(tester, picture: png);

      expect(find.byType(Image), findsOneWidget);
      harness.flow.reset();
    });

    testWidgets('"Continuar" signs in and enters the app', (tester) async {
      await pumpView(tester);

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(harness.session.isAuthenticated, isTrue);
      verify(harness.navigation.go(AppRoutes.home)).called(1);
    });

    testWidgets('the greeting is a header for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpView(tester);

      expect(
        tester.getSemantics(find.text('Te damos la bienvenida, @lucia')),
        matchesSemantics(
          isHeader: true,
          label: 'Te damos la bienvenida, @lucia',
        ),
      );
      handle.dispose();
      harness.flow.reset();
    });

    testWidgets('is available in English and in dark mode', (tester) async {
      await pumpView(tester, locale: const Locale('en'), dark: true);

      expect(find.text('Welcome, @lucia'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      harness.flow.reset();
    });
  });
}
