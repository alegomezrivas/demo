import 'package:demo/app/locator.dart';
import 'package:demo/core/services/image_processor.dart';
import 'package:demo/core/services/image_source_service.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/viewmodels/avatar_step_view_model.dart';
import 'package:demo/features/auth/presentation/views/sign_up_avatar_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_code_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_done_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_email_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_name_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_password_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_terms_view.dart';
import 'package:demo/features/auth/presentation/views/sign_up_username_view.dart';
import 'package:demo/features/auth/presentation/views/terms_view.dart';
import 'package:demo/features/auth/presentation/views/welcome_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import 'sign_up_harness.dart';

/// Every step on small and large phones, with large text, the keyboard open,
/// in both themes and both languages: nothing may overflow or throw.
void main() {
  late SignUpHarness harness;

  setUp(() async {
    harness = SignUpHarness();
    await harness.register();
    final source = MockImageSourceService();
    final processor = MockImageProcessor();
    locator
      ..registerSingleton<ImageSourceService>(source)
      ..registerSingleton<ImageProcessor>(processor)
      ..registerFactory<AvatarStepViewModel>(
        () => AvatarStepViewModel(
          source: source,
          processor: processor,
          flow: harness.flow,
        ),
      );
  });

  tearDown(() async {
    harness.flow.dispose();
    await harness.dispose();
  });

  /// Walks the flow up to [step] so each view has the state it expects.
  Future<void> reach(int step) async {
    final flow = harness.flow..start();
    if (step < 1) return;
    flow.forms.email.control(SignUpForms.emailField).value = 'lucia@test.com';
    await flow.submitEmail();
    if (step < 2) return;
    flow.forms.code.control(SignUpForms.codeField).value = '123456';
    await flow.submitCode();
    if (step < 3) return;
    flow.forms.password.control(SignUpForms.passwordField).value =
        'Str0ng!Pass';
    flow.submitPassword();
    if (step < 4) return;
    flow.forms.name.control(SignUpForms.nameField).value = 'Lucía Gómez';
    flow.submitName();
    if (step < 5) return;
    flow.forms.username.control(SignUpForms.usernameField).value = 'lucia';
    await flow.submitUsername();
    if (step < 6) return;
    await flow.acceptTerms();
    if (step < 7) return;
    flow.skipAvatar();
  }

  final screens = <String, ({int step, Widget view})>{
    'welcome': (step: 0, view: const WelcomeView()),
    'email': (step: 0, view: const SignUpEmailView()),
    'code': (step: 1, view: const SignUpCodeView()),
    'password': (step: 2, view: const SignUpPasswordView()),
    'name': (step: 3, view: const SignUpNameView()),
    'username': (step: 4, view: const SignUpUsernameView()),
    'terms': (step: 5, view: const SignUpTermsView()),
    'avatar': (step: 6, view: const SignUpAvatarView()),
    'done': (step: 7, view: const SignUpDoneView()),
    'terms text': (step: 0, view: const TermsView()),
  };

  const sizes = [Size(320, 568), Size(390, 844), Size(768, 1024)];

  for (final entry in screens.entries) {
    testWidgets('${entry.key} fits every size, scale, theme and language', (
      tester,
    ) async {
      for (final size in sizes) {
        for (final scale in [1.0, 2.0]) {
          for (final dark in [false, true]) {
            for (final locale in const [Locale('es'), Locale('en')]) {
              tester.view
                ..physicalSize = size
                ..devicePixelRatio = 1;
              tester.platformDispatcher.textScaleFactorTestValue = scale;
              harness.flow.reset();
              await reach(entry.value.step);

              await pumpLocalized(
                tester,
                entry.value.view,
                locale: locale,
                dark: dark,
              );
              await tester.pump(const Duration(milliseconds: 300));

              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${entry.key} $size x$scale ${dark ? 'dark' : 'light'} $locale',
              );
            }
          }
        }
      }
      tester.view.reset();
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      await tester.pumpWidget(const SizedBox());
      harness.flow.reset();
    });

    testWidgets('${entry.key} fits with the keyboard open on a small phone', (
      tester,
    ) async {
      usePhone(tester, size: const Size(320, 568));
      openKeyboard(tester);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await reach(entry.value.step);

      await pumpLocalized(tester, entry.value.view);
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      harness.flow.reset();
    });
  }

  testWidgets('the pinned actions of the welcome stay reachable at 2x text', (
    tester,
  ) async {
    usePhone(tester, size: const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await harness.pump(tester, const WelcomeView());

    await tester.scrollUntilVisible(find.text('Ya tengo cuenta'), 100);

    expect(find.text('Ya tengo cuenta'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('every step has a 48 dp primary action', (tester) async {
    usePhone(tester);
    await reach(0);
    await harness.pump(tester, const SignUpEmailView());

    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );
    harness.flow.reset();
  });
}
