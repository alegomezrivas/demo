import 'package:demo/app/router/app_routes.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/core/utils/validators/validation_keys.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/register_use_case.dart';
import 'package:demo/features/auth/presentation/viewmodels/register_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../../../helpers/mocks.dart';
import '../../helpers/auth_mocks.dart';

void main() {
  late MockRegisterUseCase register;
  late MockNavigationService navigation;
  late MockScreenProtection protection;
  late SessionService session;
  late RegisterViewModel viewModel;
  const user = User(id: '1', name: 'Ana', email: 'ana@test.com');

  setUp(() {
    register = MockRegisterUseCase();
    navigation = MockNavigationService();
    protection = MockScreenProtection();
    session = SessionService();
    viewModel = RegisterViewModel(
      register: register,
      navigation: navigation,
      session: session,
      screenProtection: protection,
    );
  });

  void fill({
    String name = 'Ana',
    String email = 'ana@test.com',
    String phone = '',
    String password = 'Abcdef1!',
    String confirm = 'Abcdef1!',
  }) {
    viewModel.form.patchValue({
      RegisterViewModel.nameField: name,
      RegisterViewModel.emailField: email,
      RegisterViewModel.phoneField: phone,
      RegisterViewModel.passwordField: password,
      RegisterViewModel.confirmPasswordField: confirm,
    });
  }

  group('validation', () {
    test('an empty form is invalid and never reaches the use case', () async {
      await viewModel.submit();

      expect(viewModel.form.valid, isFalse);
      verifyZeroInteractions(register);
    });

    test('rejects a weak password', () {
      fill(password: 'abc', confirm: 'abc');

      expect(
        viewModel.form.control(RegisterViewModel.passwordField).errors,
        contains(ValidationKeys.strongPassword),
      );
    });

    test('rejects mismatching confirmation', () {
      fill(confirm: 'Different1!');

      expect(
        viewModel.form.control(RegisterViewModel.confirmPasswordField).errors,
        contains(ValidationKeys.mustMatch),
      );
    });

    test('rejects a one-letter name and an invalid phone', () {
      fill(name: 'A', phone: 'abc');

      expect(
        viewModel.form.control(RegisterViewModel.nameField).errors,
        contains(ValidationKeys.minLength),
      );
      expect(
        viewModel.form.control(RegisterViewModel.phoneField).errors,
        contains(ValidationKeys.phone),
      );
    });

    test('the phone is optional', () {
      fill();

      expect(viewModel.form.valid, isTrue);
    });
  });

  group('submit', () {
    test('registers, marks the session and goes home', () async {
      when(register(any)).thenAnswer((_) async => right(user));
      fill(phone: '3001234567');

      await viewModel.submit();

      final params =
          verify(register(captureAny)).captured.single as RegisterParams;
      expect(params.name, 'Ana');
      expect(params.email, 'ana@test.com');
      expect(params.password, 'Abcdef1!');
      expect(params.phone, '3001234567');
      expect(session.isAuthenticated, isTrue);
      verify(navigation.go(AppRoutes.home)).called(1);
    });

    test('sends a null phone when the field is empty', () async {
      when(register(any)).thenAnswer((_) async => right(user));
      fill();

      await viewModel.submit();

      final params =
          verify(register(captureAny)).captured.single as RegisterParams;
      expect(params.phone, isNull);
    });

    test('exposes the failure and does not sign in when it fails', () async {
      when(register(any))
          .thenAnswer((_) async => left(const ServerFailure('email_taken')));
      fill();

      await viewModel.submit();

      expect(viewModel.failure, const ServerFailure('email_taken'));
      expect(session.isAuthenticated, isFalse);
      verifyZeroInteractions(navigation);
    });
  });

  group('navigation and UI state', () {
    test('goToLogin pops when there is a previous screen', () {
      when(navigation.canPop).thenReturn(true);

      viewModel.goToLogin();

      verify(navigation.pop<void>()).called(1);
    });

    test('goToLogin replaces the stack when opened directly', () {
      when(navigation.canPop).thenReturn(false);

      viewModel.goToLogin();

      verify(navigation.go(AppRoutes.login)).called(1);
    });

    test('toggles password visibility', () {
      viewModel.togglePasswordVisibility();

      expect(viewModel.obscurePassword, isFalse);
    });
  });

  group('screen protection', () {
    test('is enabled on init and disabled on dispose', () async {
      await viewModel.init();
      viewModel.dispose();

      verify(protection.enable()).called(1);
      verify(protection.disable()).called(1);
    });
  });
}
