// Steps are written one call per line, like the user's actions, and the
// fakeAsync bodies start futures that `flushMicrotasks` completes.
// ignore_for_file: cascade_invocations, discarded_futures

import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/complete_sign_up_use_case.dart';
import 'package:demo/features/auth/domain/usecases/send_confirmation_code_use_case.dart';
import 'package:demo/features/auth/domain/usecases/verify_confirmation_code_use_case.dart';
import 'package:demo/features/auth/presentation/forms/sign_up_forms.dart';
import 'package:demo/features/auth/presentation/models/sign_up_step.dart';
import 'package:demo/features/auth/presentation/models/username_status.dart';
import 'package:demo/features/auth/presentation/services/sign_up_progress.dart';
import 'package:demo/features/auth/presentation/viewmodels/sign_up_flow_view_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';
import 'package:reactive_forms/reactive_forms.dart';

import '../../../../helpers/mocks.dart';
import '../../helpers/auth_mocks.dart';

void main() {
  late MockSendConfirmationCodeUseCase sendCode;
  late MockVerifyConfirmationCodeUseCase verifyCode;
  late MockCheckUsernameAvailabilityUseCase checkUsername;
  late MockCompleteSignUpUseCase completeSignUp;
  late MockUploadAvatarUseCase uploadAvatar;
  late MockNavigationService navigation;
  late MockScreenProtection protection;
  late SessionService session;
  late SignUpProgress progress;
  late SignUpFlowViewModel viewModel;

  const user = User(
    id: '1',
    name: 'Lucía',
    email: 'lucia@test.com',
    username: 'lucia',
  );
  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xFF, 0xD9]);

  SignUpFlowViewModel build() => SignUpFlowViewModel(
    sendCode: sendCode,
    verifyCode: verifyCode,
    checkUsername: checkUsername,
    completeSignUp: completeSignUp,
    uploadAvatar: uploadAvatar,
    navigation: navigation,
    session: session,
    progress: progress,
    screenProtection: protection,
  );

  setUp(() {
    sendCode = MockSendConfirmationCodeUseCase();
    verifyCode = MockVerifyConfirmationCodeUseCase();
    checkUsername = MockCheckUsernameAvailabilityUseCase();
    completeSignUp = MockCompleteSignUpUseCase();
    uploadAvatar = MockUploadAvatarUseCase();
    navigation = MockNavigationService();
    protection = MockScreenProtection();
    session = SessionService();
    progress = SignUpProgress();
    provideDummy<Either<Failure, Unit>>(right(unit));
    provideDummy<Either<Failure, String>>(right(''));
    provideDummy<Either<Failure, bool>>(right(false));
    provideDummy<Either<Failure, User>>(right(user));
    when(sendCode(any)).thenAnswer((_) async => right(unit));
    when(verifyCode(any)).thenAnswer((_) async => right('tok'));
    when(checkUsername(any)).thenAnswer((_) async => right(true));
    when(completeSignUp(any)).thenAnswer((_) async => right(user));
    when(uploadAvatar(any)).thenAnswer((_) async => right(user));
    viewModel = build();
  });

  tearDown(() => viewModel.dispose());

  void type(FormGroup group, String field, Object? value) =>
      group.control(field).value = value;

  void typeEmail([String email = 'lucia@test.com']) =>
      type(viewModel.forms.email, SignUpForms.emailField, email);
  void typeCode([String code = '123456']) =>
      type(viewModel.forms.code, SignUpForms.codeField, code);
  void typePassword({String password = 'Str0ng!Pass', bool remember = true}) {
    type(viewModel.forms.password, SignUpForms.passwordField, password);
    type(viewModel.forms.password, SignUpForms.rememberField, remember);
  }

  void typeName([String name = 'Lucía Gómez']) =>
      type(viewModel.forms.name, SignUpForms.nameField, name);
  void typeUsername([String username = 'lucia']) =>
      type(viewModel.forms.username, SignUpForms.usernameField, username);

  /// Walks the flow up to the terms step with the mocks above.
  Future<void> reachTerms({bool remember = true}) async {
    viewModel.start();
    typeEmail();
    await viewModel.submitEmail();
    typeCode();
    await viewModel.submitCode();
    typePassword(remember: remember);
    viewModel.submitPassword();
    typeName();
    viewModel.submitName();
    typeUsername();
    await viewModel.submitUsername();
    clearInteractions(navigation);
  }

  group('start / reset', () {
    test('opens the e-mail step and unlocks only that step', () {
      viewModel.start();

      verify(navigation.push<void>(AppRoutes.signUpEmail)).called(1);
      expect(progress.furthest, SignUpStep.email);
      expect(progress.canEnter(SignUpStep.code), isFalse);
    });

    test('starting again forgets what was typed and confirmed', () async {
      await reachTerms();
      expect(viewModel.state.email, isNotEmpty);

      viewModel.start();

      expect(viewModel.state.email, isEmpty);
      expect(viewModel.state.isEmailVerified, isFalse);
      expect(
        SignUpForms.textOf(viewModel.forms.name, SignUpForms.nameField),
        isEmpty,
      );
      expect(progress.furthest, SignUpStep.email);
    });

    test('reset clears the progress', () {
      viewModel
        ..start()
        ..reset();

      expect(progress.hasStarted, isFalse);
    });

    test('notifies listeners when it resets', () {
      var notified = 0;
      viewModel
        ..addListener(() => notified++)
        ..reset();

      expect(notified, 1);
    });
  });

  group('submitEmail', () {
    test('an empty or malformed e-mail never reaches the use case', () async {
      viewModel.start();
      await viewModel.submitEmail();
      typeEmail('nope');
      await viewModel.submitEmail();

      verifyZeroInteractions(sendCode);
      expect(
        viewModel.forms.email.control(SignUpForms.emailField).touched,
        isTrue,
      );
    });

    test('sends the code, keeps the address and opens the code step', () async {
      viewModel.start();
      typeEmail('  lucia@test.com ');

      await viewModel.submitEmail();

      final params =
          verify(sendCode(captureAny)).captured.single as SendCodeParams;
      expect(params.email, 'lucia@test.com');
      expect(params.isResend, isFalse);
      expect(viewModel.state.email, 'lucia@test.com');
      expect(progress.canEnter(SignUpStep.code), isTrue);
      verify(navigation.push<void>(AppRoutes.signUpCode)).called(1);
      expect(viewModel.isBusy, isFalse);
    });

    test('starts the wait before a new code can be requested', () async {
      viewModel.start();
      typeEmail();

      await viewModel.submitEmail();

      expect(viewModel.resendSecondsLeft, 30);
      expect(viewModel.canResendCode, isFalse);
    });

    test('is busy while the code is being sent', () async {
      viewModel.start();
      typeEmail();
      final busy = <bool>[];
      viewModel.addListener(() => busy.add(viewModel.isBusy));

      await viewModel.submitEmail();

      expect(busy, contains(true));
      expect(viewModel.isBusy, isFalse);
    });

    test('a taken e-mail stays on the step with its failure', () async {
      when(
        sendCode(any),
      ).thenAnswer((_) async => left(const ServerFailure('email_taken')));
      viewModel.start();
      typeEmail();
      clearInteractions(navigation);

      await viewModel.submitEmail();

      expect(viewModel.failure, const ServerFailure('email_taken'));
      expect(viewModel.state.email, isEmpty);
      expect(progress.canEnter(SignUpStep.code), isFalse);
      verifyNever(navigation.push<void>(any));
      expect(viewModel.isBusy, isFalse);
    });

    test('a network failure is reported and can be retried', () async {
      when(
        sendCode(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();
      expect(viewModel.failure, const NetworkFailure());

      when(sendCode(any)).thenAnswer((_) async => right(unit));
      await viewModel.submitEmail();

      expect(viewModel.failure, isNull);
      expect(progress.canEnter(SignUpStep.code), isTrue);
    });

    test('ignores a second tap while busy', () async {
      viewModel.start();
      typeEmail();

      final first = viewModel.submitEmail();
      final second = viewModel.submitEmail();
      await Future.wait([first, second]);

      verify(sendCode(any)).called(1);
    });

    test('the same address does not send a second code on return', () async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();
      // The person goes back to the first step and taps "Next" again.
      viewModel.back();
      clearInteractions(sendCode);
      clearInteractions(navigation);

      await viewModel.submitEmail();

      verifyZeroInteractions(sendCode);
      verify(navigation.push<void>(AppRoutes.signUpCode)).called(1);
    });

    test('a different address invalidates the confirmation', () async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();
      typeCode();
      await viewModel.submitCode();
      expect(viewModel.state.isEmailVerified, isTrue);
      expect(progress.canEnter(SignUpStep.password), isTrue);

      // Back to the first step to change the address.
      viewModel
        ..back()
        ..back();
      typeEmail('otra@test.com');
      await viewModel.submitEmail();

      expect(viewModel.state.email, 'otra@test.com');
      expect(viewModel.state.isEmailVerified, isFalse);
      expect(progress.canEnter(SignUpStep.password), isFalse);
      expect(progress.canEnter(SignUpStep.code), isTrue);
      expect(
        SignUpForms.textOf(viewModel.forms.code, SignUpForms.codeField),
        isEmpty,
      );
    });
  });

  group('submitCode', () {
    setUp(() async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();
      clearInteractions(navigation);
    });

    test('a short code never reaches the use case', () async {
      typeCode('123');

      await viewModel.submitCode();

      verifyZeroInteractions(verifyCode);
    });

    test('keeps the verification token and opens the password step', () async {
      typeCode();

      await viewModel.submitCode();

      final params =
          verify(verifyCode(captureAny)).captured.single as VerifyCodeParams;
      expect(params.email, 'lucia@test.com');
      expect(params.code, '123456');
      expect(viewModel.state.verificationToken, 'tok');
      expect(progress.canEnter(SignUpStep.password), isTrue);
      verify(navigation.push<void>(AppRoutes.signUpPassword)).called(1);
    });

    test('a wrong code is reported, cleared and does not advance', () async {
      when(verifyCode(any)).thenAnswer(
        (_) async => left(const ServerFailure('invalid_code')),
      );
      typeCode('000000');

      await viewModel.submitCode();

      expect(viewModel.failure, const ServerFailure('invalid_code'));
      expect(
        SignUpForms.textOf(viewModel.forms.code, SignUpForms.codeField),
        isEmpty,
      );
      expect(viewModel.state.isEmailVerified, isFalse);
      verifyNever(navigation.push<void>(any));
    });

    test('too many attempts is reported', () async {
      when(verifyCode(any)).thenAnswer(
        (_) async => left(const ServerFailure('too_many_attempts')),
      );
      typeCode();

      await viewModel.submitCode();

      expect(viewModel.failure, const ServerFailure('too_many_attempts'));
    });

    test('a later success clears the previous failure', () async {
      when(verifyCode(any)).thenAnswer(
        (_) async => left(const ServerFailure('invalid_code')),
      );
      typeCode('000000');
      await viewModel.submitCode();

      when(verifyCode(any)).thenAnswer((_) async => right('tok'));
      typeCode();
      await viewModel.submitCode();

      expect(viewModel.failure, isNull);
    });
  });

  group('resendCode', () {
    test('cannot be used while the wait is running', () async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();
      clearInteractions(sendCode);

      await viewModel.resendCode();

      verifyZeroInteractions(sendCode);
    });

    test('asks for a new code once the wait is over', () {
      fakeAsync((async) {
        viewModel.dispose();
        viewModel = SignUpFlowViewModel(
          sendCode: sendCode,
          verifyCode: verifyCode,
          checkUsername: checkUsername,
          completeSignUp: completeSignUp,
          uploadAvatar: uploadAvatar,
          navigation: navigation,
          session: session,
          progress: progress,
          screenProtection: protection,
          resendCooldownSeconds: 2,
        )..start();
        typeEmail();
        viewModel.submitEmail();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        expect(viewModel.canResendCode, isTrue);
        typeCode('999999');

        viewModel.resendCode();
        async.flushMicrotasks();

        final calls = verify(
          sendCode(captureAny),
        ).captured.cast<SendCodeParams>();
        expect(calls.map((c) => c.isResend), [false, true]);
        expect(
          SignUpForms.textOf(viewModel.forms.code, SignUpForms.codeField),
          isEmpty,
        );
        expect(viewModel.resendSecondsLeft, 2);
      });
    });

    test('restarts the wait when the server says it is too soon', () {
      fakeAsync((async) {
        viewModel.dispose();
        viewModel = SignUpFlowViewModel(
          sendCode: sendCode,
          verifyCode: verifyCode,
          checkUsername: checkUsername,
          completeSignUp: completeSignUp,
          uploadAvatar: uploadAvatar,
          navigation: navigation,
          session: session,
          progress: progress,
          screenProtection: protection,
          resendCooldownSeconds: 2,
        )..start();
        typeEmail();
        viewModel.submitEmail();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 2));
        when(sendCode(any)).thenAnswer(
          (_) async => left(const ServerFailure('resend_too_soon')),
        );

        viewModel.resendCode();
        async.flushMicrotasks();

        expect(viewModel.failure, const ServerFailure('resend_too_soon'));
        expect(viewModel.resendSecondsLeft, 2);
      });
    });

    test('keeps the failure and the wait over when sending fails', () {
      fakeAsync((async) {
        viewModel.dispose();
        viewModel = SignUpFlowViewModel(
          sendCode: sendCode,
          verifyCode: verifyCode,
          checkUsername: checkUsername,
          completeSignUp: completeSignUp,
          uploadAvatar: uploadAvatar,
          navigation: navigation,
          session: session,
          progress: progress,
          screenProtection: protection,
          resendCooldownSeconds: 1,
        )..start();
        typeEmail();
        viewModel.submitEmail();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));
        when(
          sendCode(any),
        ).thenAnswer((_) async => left(const NetworkFailure()));

        viewModel.resendCode();
        async.flushMicrotasks();

        expect(viewModel.failure, const NetworkFailure());
        expect(viewModel.canResendCode, isTrue);
      });
    });
  });

  group('submitPassword', () {
    test('rejects weak passwords', () {
      viewModel.start();
      typePassword(password: 'weak');

      viewModel.submitPassword();

      verifyNever(navigation.push<void>(AppRoutes.signUpName));
      expect(progress.canEnter(SignUpStep.name), isFalse);
    });

    test('opens the name step', () {
      viewModel.start();
      typePassword();

      viewModel.submitPassword();

      verify(navigation.push<void>(AppRoutes.signUpName)).called(1);
      expect(progress.canEnter(SignUpStep.name), isTrue);
    });
  });

  group('submitName', () {
    test('rejects a blank name', () {
      viewModel.start();
      typeName('   ');

      viewModel.submitName();

      verifyNever(navigation.push<void>(AppRoutes.signUpUsername));
    });

    test('opens the username step', () {
      viewModel.start();
      typeName();

      viewModel.submitName();

      verify(navigation.push<void>(AppRoutes.signUpUsername)).called(1);
    });
  });

  group('username check', () {
    test('typing nothing is idle', () {
      viewModel.start();

      viewModel.onUsernameChanged('  ');

      expect(viewModel.state.usernameStatus, UsernameStatus.idle);
    });

    test('malformed text is invalid and the server is not asked', () {
      fakeAsync((async) {
        viewModel.start();

        typeUsername('bad name');
        async.elapse(const Duration(seconds: 2));

        expect(viewModel.state.usernameStatus, UsernameStatus.invalid);
        verifyZeroInteractions(checkUsername);
      });
    });

    test('asks only after the typing pauses', () {
      fakeAsync((async) {
        viewModel.start();

        typeUsername('luc');
        async.elapse(const Duration(milliseconds: 200));
        typeUsername();
        async.elapse(const Duration(milliseconds: 200));
        expect(viewModel.state.usernameStatus, UsernameStatus.checking);
        verifyZeroInteractions(checkUsername);

        async.elapse(const Duration(milliseconds: 400));
        async.flushMicrotasks();

        verify(checkUsername('lucia')).called(1);
        expect(viewModel.state.usernameStatus, UsernameStatus.available);
      });
    });

    test('reports a taken username', () {
      fakeAsync((async) {
        when(checkUsername(any)).thenAnswer((_) async => right(false));
        viewModel.start();

        typeUsername();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(viewModel.state.usernameStatus, UsernameStatus.taken);
      });
    });

    test('a failed check is unknown, not an error', () {
      fakeAsync((async) {
        when(
          checkUsername(any),
        ).thenAnswer((_) async => left(const NetworkFailure()));
        viewModel.start();

        typeUsername();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(viewModel.state.usernameStatus, UsernameStatus.unknown);
        expect(viewModel.failure, isNull);
      });
    });

    test('ignores the answer for text that was changed meanwhile', () {
      fakeAsync((async) {
        final first = Completer<Either<Failure, bool>>();
        when(checkUsername('first')).thenAnswer((_) => first.future);
        viewModel.start();

        typeUsername('first');
        async.elapse(const Duration(seconds: 1));
        typeUsername('second');
        first.complete(right(false));
        async.flushMicrotasks();

        expect(viewModel.state.usernameStatus, isNot(UsernameStatus.taken));
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        expect(viewModel.state.usernameStatus, UsernameStatus.available);
      });
    });

    test('emptying the field resets the status', () {
      fakeAsync((async) {
        viewModel.start();
        typeUsername();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();

        viewModel.forms.username.control(SignUpForms.usernameField).value = '';
        async.flushMicrotasks();

        expect(viewModel.state.usernameStatus, UsernameStatus.idle);
      });
    });

    test('notifies only when the status changes', () {
      fakeAsync((async) {
        viewModel.start();
        var notified = 0;
        viewModel.addListener(() => notified++);

        viewModel.onUsernameChanged('bad name');
        viewModel.onUsernameChanged('bad name');

        expect(notified, 1);
      });
    });
  });

  group('submitUsername', () {
    setUp(() async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();
      clearInteractions(navigation);
    });

    test('an invalid username does not advance', () async {
      typeUsername('no spaces');

      await viewModel.submitUsername();

      verifyNever(navigation.push<void>(AppRoutes.signUpTerms));
    });

    test(
      'checks right away when the person is quicker than the debounce',
      () async {
        typeUsername();

        await viewModel.submitUsername();

        verify(checkUsername('lucia')).called(1);
        verify(navigation.push<void>(AppRoutes.signUpTerms)).called(1);
        expect(progress.canEnter(SignUpStep.terms), isTrue);
      },
    );

    test('a taken username does not advance', () async {
      when(checkUsername(any)).thenAnswer((_) async => right(false));
      typeUsername();

      await viewModel.submitUsername();

      expect(viewModel.state.usernameStatus, UsernameStatus.taken);
      verifyNever(navigation.push<void>(AppRoutes.signUpTerms));
    });

    test('lets an unknown result through; registration decides', () async {
      when(
        checkUsername(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      typeUsername();

      await viewModel.submitUsername();

      verify(navigation.push<void>(AppRoutes.signUpTerms)).called(1);
    });

    test('does not ask again when the username is already known free', () {
      fakeAsync((async) {
        // Forms are subscribed in the zone that starts the flow.
        viewModel.start();
        typeUsername();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        clearInteractions(checkUsername);

        viewModel.submitUsername();
        async.flushMicrotasks();

        verifyZeroInteractions(checkUsername);
        verify(navigation.push<void>(AppRoutes.signUpTerms)).called(1);
      });
    });
  });

  group('acceptTerms', () {
    test('creates the account with everything collected', () async {
      await reachTerms();

      await viewModel.acceptTerms();

      final params =
          verify(completeSignUp(captureAny)).captured.single
              as CompleteSignUpParams;
      expect(params.verificationToken, 'tok');
      expect(params.name, 'Lucía Gómez');
      expect(params.username, 'lucia');
      expect(params.password, 'Str0ng!Pass');
      expect(params.rememberSession, isTrue);
    });

    test('passes along that the session must not be remembered', () async {
      await reachTerms(remember: false);

      await viewModel.acceptTerms();

      final params =
          verify(completeSignUp(captureAny)).captured.single
              as CompleteSignUpParams;
      expect(params.rememberSession, isFalse);
    });

    test('moves to the picture step and locks the earlier ones', () async {
      await reachTerms();

      await viewModel.acceptTerms();

      verify(navigation.go(AppRoutes.signUpAvatar)).called(1);
      expect(viewModel.state.user, user);
      expect(progress.canEnter(SignUpStep.avatar), isTrue);
      expect(progress.canEnter(SignUpStep.terms), isFalse);
      expect(progress.canEnter(SignUpStep.email), isFalse);
    });

    test('does not mark the session signed in yet', () async {
      await reachTerms();

      await viewModel.acceptTerms();

      expect(session.isAuthenticated, isFalse);
    });

    test('forgets the password and the proof of the e-mail', () async {
      await reachTerms();

      await viewModel.acceptTerms();

      expect(
        SignUpForms.textOf(viewModel.forms.password, SignUpForms.passwordField),
        isEmpty,
      );
      expect(viewModel.state.verificationToken, isNull);
    });

    test('a taken username sends the person back to that step', () async {
      when(completeSignUp(any)).thenAnswer(
        (_) async => left(const ServerFailure('username_taken')),
      );
      await reachTerms();

      await viewModel.acceptTerms();

      verify(navigation.pop<Object?>()).called(1);
      expect(viewModel.state.usernameStatus, UsernameStatus.taken);
      expect(viewModel.state.hasAccount, isFalse);
      expect(viewModel.state.isEmailVerified, isTrue);
    });

    test('an expired confirmation restarts from the e-mail step', () async {
      when(completeSignUp(any)).thenAnswer(
        (_) async => left(const ServerFailure('invalid_verification_token')),
      );
      await reachTerms();

      await viewModel.acceptTerms();

      verify(navigation.go(AppRoutes.signUpEmail)).called(1);
      expect(viewModel.state.isEmailVerified, isFalse);
      expect(
        viewModel.failure,
        const ServerFailure('invalid_verification_token'),
      );
      expect(progress.canEnter(SignUpStep.code), isFalse);
    });

    test(
      'an e-mail registered meanwhile restarts from the e-mail step',
      () async {
        when(completeSignUp(any)).thenAnswer(
          (_) async => left(const ServerFailure('email_taken')),
        );
        await reachTerms();

        await viewModel.acceptTerms();

        verify(navigation.go(AppRoutes.signUpEmail)).called(1);
        expect(viewModel.failure, const ServerFailure('email_taken'));
      },
    );

    test('other failures stay on the step and can be retried', () async {
      when(
        completeSignUp(any),
      ).thenAnswer((_) async => left(const NetworkFailure()));
      await reachTerms();

      await viewModel.acceptTerms();

      expect(viewModel.failure, const NetworkFailure());
      verifyNever(navigation.go(any));
      verifyNever(navigation.pop<Object?>());

      when(completeSignUp(any)).thenAnswer((_) async => right(user));
      await viewModel.acceptTerms();

      verify(navigation.go(AppRoutes.signUpAvatar)).called(1);
    });

    test('without a verification token it restarts from the e-mail', () async {
      viewModel.start();
      clearInteractions(navigation);

      await viewModel.acceptTerms();

      verifyZeroInteractions(completeSignUp);
      verify(navigation.go(AppRoutes.signUpEmail)).called(1);
    });

    test('ignores a second tap while busy', () async {
      await reachTerms();

      final first = viewModel.acceptTerms();
      final second = viewModel.acceptTerms();
      await Future.wait([first, second]);

      verify(completeSignUp(any)).called(1);
    });
  });

  group('picture step', () {
    setUp(() async {
      await reachTerms();
      await viewModel.acceptTerms();
      clearInteractions(navigation);
    });

    test('uploading finishes the step', () async {
      await viewModel.submitAvatar(jpeg);

      verify(uploadAvatar(jpeg)).called(1);
      verify(navigation.go(AppRoutes.signUpDone)).called(1);
      expect(progress.canEnter(SignUpStep.done), isTrue);
    });

    test('keeps the updated user', () async {
      final withAvatar = user.copyWith(hasAvatar: true);
      when(uploadAvatar(any)).thenAnswer((_) async => right(withAvatar));

      await viewModel.submitAvatar(jpeg);

      expect(viewModel.state.user, withAvatar);
    });

    test('a failed upload stays on the step', () async {
      when(uploadAvatar(any)).thenAnswer(
        (_) async => left(const ServerFailure('invalid_image')),
      );

      await viewModel.submitAvatar(jpeg);

      expect(viewModel.failure, const ServerFailure('invalid_image'));
      verifyNever(navigation.go(any));
      expect(viewModel.isBusy, isFalse);
    });

    test('skipping goes to the final step without uploading', () {
      viewModel.skipAvatar();

      verifyZeroInteractions(uploadAvatar);
      verify(navigation.go(AppRoutes.signUpDone)).called(1);
    });
  });

  group('finish', () {
    test('signs in persistently and enters the app', () async {
      await reachTerms();
      await viewModel.acceptTerms();
      viewModel.skipAvatar();

      viewModel.finish();

      expect(session.isAuthenticated, isTrue);
      expect(session.isPersistent, isTrue);
      verify(navigation.go(AppRoutes.home)).called(1);
    });

    test('a session that is not remembered is marked as such', () async {
      await reachTerms(remember: false);
      await viewModel.acceptTerms();
      viewModel.skipAvatar();

      viewModel.finish();

      expect(session.isAuthenticated, isTrue);
      expect(session.isPersistent, isFalse);
    });

    test('forgets the flow', () async {
      await reachTerms();
      await viewModel.acceptTerms();
      viewModel.skipAvatar();

      viewModel.finish();

      expect(progress.hasStarted, isFalse);
      expect(viewModel.state.hasAccount, isFalse);
    });
  });

  group('navigation helpers', () {
    test('back pops', () {
      viewModel.back();

      verify(navigation.pop<Object?>()).called(1);
    });

    test('goToLogin replaces the stack with the sign-in screen', () {
      viewModel.goToLogin();

      verify(navigation.go(AppRoutes.login)).called(1);
    });

    test('openTerms pushes the terms text', () {
      viewModel.openTerms();

      verify(navigation.push<void>(AppRoutes.terms)).called(1);
    });
  });

  group('screen protection', () {
    test('enables and disables the protection', () async {
      await viewModel.protectScreen(enabled: true);
      await viewModel.protectScreen(enabled: false);

      verifyInOrder([protection.enable(), protection.disable()]);
    });

    test('is best effort', () async {
      when(protection.enable()).thenThrow(PlatformException(code: 'x'));

      await expectLater(viewModel.protectScreen(enabled: true), completes);
    });
  });

  group('leaving the flow', () {
    test('backing out of the first step forgets everything typed', () async {
      viewModel.start();
      typeEmail();
      typePassword();

      viewModel.back();

      verify(navigation.pop<Object?>()).called(1);
      expect(progress.hasStarted, isFalse);
      expect(
        SignUpForms.textOf(viewModel.forms.password, SignUpForms.passwordField),
        isEmpty,
      );
      expect(
        SignUpForms.textOf(viewModel.forms.email, SignUpForms.emailField),
        isEmpty,
      );
    });

    test('backing out of a later step keeps what was typed', () async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();

      viewModel.back();

      expect(viewModel.state.email, 'lucia@test.com');
      expect(progress.hasStarted, isTrue);
    });

    test('going back twice from the code step leaves the flow', () async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();

      viewModel
        ..back()
        ..back();

      expect(progress.hasStarted, isFalse);
      expect(viewModel.state.email, isEmpty);
    });

    test('opening the sign-in forgets the password and the proof', () async {
      await reachTerms();

      viewModel.goToLogin();

      verify(navigation.go(AppRoutes.login)).called(1);
      expect(viewModel.state.isEmailVerified, isFalse);
      expect(
        SignUpForms.textOf(viewModel.forms.password, SignUpForms.passwordField),
        isEmpty,
      );
      expect(progress.hasStarted, isFalse);
    });

    test(
      'reset empties the retired forms that screens may still show',
      () async {
        viewModel.start();
        typePassword();
        final oldForms = viewModel.forms;

        viewModel.reset();

        expect(
          oldForms.password.control(SignUpForms.passwordField).value,
          isNull,
        );
        // Still usable: a screen animating out must not crash on it.
        expect(
          () =>
              oldForms.password.control(SignUpForms.passwordField).value = 'x',
          returnsNormally,
        );
      },
    );
  });

  group('answers that arrive late', () {
    test(
      'going back while the code is being sent ignores the answer',
      () async {
        final pending = Completer<Either<Failure, Unit>>();
        when(sendCode(any)).thenAnswer((_) => pending.future);
        viewModel.start();
        typeEmail();
        clearInteractions(navigation);

        final submit = viewModel.submitEmail();
        viewModel.back();
        pending.complete(right(unit));
        await submit;

        verifyNever(navigation.push<void>(AppRoutes.signUpCode));
        expect(viewModel.state.email, isEmpty);
        expect(viewModel.isBusy, isFalse);
        expect(viewModel.resendSecondsLeft, 0);
      },
    );

    test('restarting while the code is checked ignores the answer', () async {
      viewModel.start();
      typeEmail();
      await viewModel.submitEmail();
      final pending = Completer<Either<Failure, String>>();
      when(verifyCode(any)).thenAnswer((_) => pending.future);
      typeCode();

      final submit = viewModel.submitCode();
      viewModel.start();
      pending.complete(right('tok'));
      await submit;

      expect(viewModel.state.isEmailVerified, isFalse);
      verifyNever(navigation.push<void>(AppRoutes.signUpPassword));
    });

    test('a failure that arrives after leaving is not shown', () async {
      final pending = Completer<Either<Failure, Unit>>();
      when(sendCode(any)).thenAnswer((_) => pending.future);
      viewModel.start();
      typeEmail();

      final submit = viewModel.submitEmail();
      viewModel.reset();
      pending.complete(left(const ServerFailure('email_taken')));
      await submit;

      expect(viewModel.failure, isNull);
    });

    test(
      'an account created after leaving does not move the new flow',
      () async {
        await reachTerms();
        final pending = Completer<Either<Failure, User>>();
        when(completeSignUp(any)).thenAnswer((_) => pending.future);
        clearInteractions(navigation);

        final accept = viewModel.acceptTerms();
        viewModel.reset();
        pending.complete(right(user));
        await accept;

        verifyNever(navigation.go(AppRoutes.signUpAvatar));
        expect(viewModel.state.hasAccount, isFalse);
      },
    );

    test(
      'a picture uploaded after leaving does not open the final step',
      () async {
        await reachTerms();
        await viewModel.acceptTerms();
        final pending = Completer<Either<Failure, User>>();
        when(uploadAvatar(any)).thenAnswer((_) => pending.future);
        clearInteractions(navigation);

        final upload = viewModel.submitAvatar(jpeg);
        viewModel.reset();
        pending.complete(right(user));
        await upload;

        verifyNever(navigation.go(AppRoutes.signUpDone));
        expect(viewModel.state.avatar, isNull);
      },
    );
  });

  group('double taps', () {
    test('two quick taps on the username step push the terms once', () async {
      viewModel.start();
      typeUsername();

      final first = viewModel.submitUsername();
      final second = viewModel.submitUsername();
      await Future.wait([first, second]);

      verify(navigation.push<void>(AppRoutes.signUpTerms)).called(1);
      expect(viewModel.isBusy, isFalse);
    });

    test('a username already known free is also pushed only once', () {
      fakeAsync((async) {
        viewModel.start();
        typeUsername();
        async.elapse(const Duration(seconds: 1));
        async.flushMicrotasks();
        clearInteractions(navigation);

        viewModel.submitUsername();
        viewModel.submitUsername();
        async.flushMicrotasks();

        verify(navigation.push<void>(AppRoutes.signUpTerms)).called(1);
      });
    });

    test('leaving during the check does not open the terms', () async {
      final pending = Completer<Either<Failure, bool>>();
      when(checkUsername(any)).thenAnswer((_) => pending.future);
      viewModel.start();
      typeUsername();
      clearInteractions(navigation);

      final submit = viewModel.submitUsername();
      viewModel.reset();
      pending.complete(right(true));
      await submit;

      verifyNever(navigation.push<void>(AppRoutes.signUpTerms));
    });
  });

  group('small details', () {
    test(
      'the same address in another case does not send a second code',
      () async {
        viewModel.start();
        typeEmail();
        await viewModel.submitEmail();
        clearInteractions(sendCode);

        typeEmail('LUCIA@Test.com');
        await viewModel.submitEmail();

        verifyZeroInteractions(sendCode);
      },
    );

    test('skipping after a failed upload clears the failure', () async {
      await reachTerms();
      await viewModel.acceptTerms();
      when(uploadAvatar(any)).thenAnswer(
        (_) async => left(const ServerFailure('invalid_image')),
      );
      await viewModel.submitAvatar(jpeg);
      expect(viewModel.failure, isNotNull);

      viewModel.skipAvatar();

      expect(viewModel.failure, isNull);
    });

    test(
      'an unexpected "remember me" value counts as not remembering',
      () async {
        viewModel.start();
        typePassword();
        viewModel.forms.password.control(SignUpForms.rememberField).value =
            null;
        viewModel.submitPassword();
        typeName();
        viewModel.submitName();
        typeUsername();
        await viewModel.submitUsername();
        typeEmail();
        await viewModel.submitEmail();

        expect(SignUpForms.rememberOf(viewModel.forms.password), isFalse);
      },
    );
  });

  test('dispose cancels pending work without errors', () {
    fakeAsync((async) {
      viewModel
        ..start()
        ..onUsernameChanged('lucia')
        ..dispose();

      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();

      expect(async.pendingTimers, isEmpty);
    });
    // The shared tearDown disposes again; make that safe.
    viewModel = build();
  });
}
