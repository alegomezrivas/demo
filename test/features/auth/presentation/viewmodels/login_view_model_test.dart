import 'dart:async';

import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:demo/features/auth/presentation/viewmodels/login_view_model.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../helpers/auth_mocks.dart';

void main() {
  late MockLoginUseCase login;
  late MockNavigationService navigation;
  late MockScreenProtection protection;
  late SessionService session;
  late LoginViewModel viewModel;
  const user = User(
    id: '1',
    name: 'Ana',
    email: 'ana@test.com',
    username: 'ana',
  );

  setUp(() {
    login = MockLoginUseCase();
    navigation = MockNavigationService();
    protection = MockScreenProtection();
    session = SessionService();
    viewModel = LoginViewModel(
      login: login,
      navigation: navigation,
      session: session,
      screenProtection: protection,
    );
  });

  void fill({String email = 'ana@test.com', String password = 'pw'}) {
    viewModel.form.control(LoginViewModel.emailField).value = email;
    viewModel.form.control(LoginViewModel.passwordField).value = password;
  }

  group('validation', () {
    test('an empty form is invalid and never reaches the use case', () async {
      await viewModel.submit();

      expect(viewModel.form.valid, isFalse);
      expect(viewModel.form.control(LoginViewModel.emailField).touched, isTrue);
      verifyZeroInteractions(login);
      verifyZeroInteractions(navigation);
    });

    test('a malformed e-mail is rejected', () async {
      fill(email: 'not-an-email');

      await viewModel.submit();

      verifyZeroInteractions(login);
    });
  });

  group('submit', () {
    test('signs in, marks the session and goes home', () async {
      when(login(any)).thenAnswer((_) async => right(user));
      fill();

      await viewModel.submit();

      final params = verify(login(captureAny)).captured.single as LoginParams;
      expect(params.email, 'ana@test.com');
      expect(params.password, 'pw');
      expect(session.isAuthenticated, isTrue);
      expect(viewModel.failure, isNull);
      expect(viewModel.isBusy, isFalse);
      verify(navigation.go(AppRoutes.home)).called(1);
    });

    test('keeps the failure and stays on the screen when it fails', () async {
      when(
        login(any),
      ).thenAnswer((_) async => left(const UnauthorizedFailure()));
      fill();

      await viewModel.submit();

      expect(viewModel.failure, const UnauthorizedFailure());
      expect(session.isAuthenticated, isFalse);
      expect(viewModel.isBusy, isFalse);
      verifyZeroInteractions(navigation);
    });

    test('clears the previous failure on a new attempt', () async {
      when(login(any)).thenAnswer((_) async => left(const NetworkFailure()));
      fill();
      await viewModel.submit();
      when(login(any)).thenAnswer((_) async => right(user));

      await viewModel.submit();

      expect(viewModel.failure, isNull);
    });

    test('is busy while the request runs and ignores double submits', () async {
      final completer = Completer<Either<Failure, User>>();
      when(login(any)).thenAnswer((_) => completer.future);
      fill();

      final first = viewModel.submit();
      await Future<void>.delayed(Duration.zero);
      expect(viewModel.isBusy, isTrue);
      await viewModel.submit();
      completer.complete(right(user));
      await first;

      verify(login(any)).called(1);
      expect(viewModel.isBusy, isFalse);
    });
  });

  group('UI state', () {
    test('toggles password visibility and notifies', () {
      var notified = 0;
      viewModel.addListener(() => notified++);

      expect(viewModel.obscurePassword, isTrue);
      viewModel.togglePasswordVisibility();

      expect(viewModel.obscurePassword, isFalse);
      expect(notified, 1);
    });
  });

  group('screen protection', () {
    test('init enables the protection', () async {
      await viewModel.init();

      verify(protection.enable()).called(1);
    });

    test('init survives a plugin failure', () async {
      when(protection.enable()).thenThrow(PlatformException(code: 'x'));

      await expectLater(viewModel.init(), completes);
    });

    test('dispose turns the protection off', () {
      viewModel.dispose();

      verify(protection.disable()).called(1);
    });
  });
}
