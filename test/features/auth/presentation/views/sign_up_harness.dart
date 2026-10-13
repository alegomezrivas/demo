import 'package:demo/app/locator.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/pump_app.dart';
import '../../helpers/auth_mocks.dart';

/// Real [SignUpFlowViewModel] over mocked use cases, registered in the
/// locator the way the app does, so views can be tested one at a time.
class SignUpHarness {
  SignUpHarness() {
    provideDummy<Either<Failure, Unit>>(right(unit));
    provideDummy<Either<Failure, String>>(right(''));
    provideDummy<Either<Failure, bool>>(right(false));
    provideDummy<Either<Failure, User>>(right(user));
    when(sendCode(any)).thenAnswer((_) async => right(unit));
    when(verifyCode(any)).thenAnswer((_) async => right('tok'));
    when(checkUsername(any)).thenAnswer((_) async => right(true));
    when(completeSignUp(any)).thenAnswer((_) async => right(user));
    when(uploadAvatar(any)).thenAnswer((_) async => right(user));
    flow = SignUpFlowViewModel(
      sendCode: sendCode,
      verifyCode: verifyCode,
      checkUsername: checkUsername,
      completeSignUp: completeSignUp,
      uploadAvatar: uploadAvatar,
      navigation: navigation,
      session: session,
      progress: progress,
      screenProtection: protection,
      usernameDebounce: const Duration(milliseconds: 10),
    );
  }

  static const User user = User(
    id: '1',
    name: 'Lucía Gómez',
    email: 'lucia@test.com',
    username: 'lucia',
  );

  final MockSendConfirmationCodeUseCase sendCode =
      MockSendConfirmationCodeUseCase();
  final MockVerifyConfirmationCodeUseCase verifyCode =
      MockVerifyConfirmationCodeUseCase();
  final MockCheckUsernameAvailabilityUseCase checkUsername =
      MockCheckUsernameAvailabilityUseCase();
  final MockCompleteSignUpUseCase completeSignUp = MockCompleteSignUpUseCase();
  final MockUploadAvatarUseCase uploadAvatar = MockUploadAvatarUseCase();
  final MockNavigationService navigation = MockNavigationService();
  final MockScreenProtection protection = MockScreenProtection();
  final SessionService session = SessionService();
  final SignUpProgress progress = SignUpProgress();
  late final SignUpFlowViewModel flow;

  /// Registers the ViewModel like the app does; call from `setUp`.
  Future<void> register() async {
    await resetLocator();
    locator.registerSingleton<SignUpFlowViewModel>(flow);
  }

  /// Releases the ViewModel; call from `tearDown`.
  Future<void> dispose() async {
    await resetLocator();
  }

  /// Pumps [view] in the localized, themed app and lets it settle.
  Future<void> pump(
    WidgetTester tester,
    Widget view, {
    Locale locale = const Locale('es'),
    bool dark = false,
  }) async {
    await pumpLocalized(tester, view, locale: locale, dark: dark);
    await tester.pumpAndSettle();
  }
}

/// Gives the test view a phone-like size, restored when the test ends.
void usePhone(WidgetTester tester, {Size size = const Size(390, 800)}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Pretends the software keyboard is open.
void openKeyboard(WidgetTester tester, {double height = 300}) {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  addTearDown(tester.view.resetViewInsets);
}
