import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/presentation/models/sign_up_state.dart';
import 'package:demo/features/auth/presentation/models/username_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const user = User(id: '1', name: 'Ana', email: 'a@b.co', username: 'ana');

  group('SignUpState', () {
    test('starts empty', () {
      const state = SignUpState();

      expect(state.email, isEmpty);
      expect(state.isEmailVerified, isFalse);
      expect(state.hasAccount, isFalse);
      expect(state.usernameStatus, UsernameStatus.idle);
      expect(state.failure, isNull);
    });

    test('copyWith replaces only the given fields', () {
      final state = const SignUpState().copyWith(
        email: 'a@b.co',
        verificationToken: 'tok',
      );

      expect(state.email, 'a@b.co');
      expect(state.isEmailVerified, isTrue);

      final next = state.copyWith(user: user);
      expect(next.hasAccount, isTrue);
      expect(next.email, 'a@b.co');
      expect(next.verificationToken, 'tok');
    });

    test('can clear the token and the failure', () {
      final state = const SignUpState().copyWith(
        verificationToken: 'tok',
        failure: const ServerFailure('x'),
      );

      final cleared = state.copyWith(
        clearVerificationToken: true,
        clearFailure: true,
      );

      expect(cleared.verificationToken, isNull);
      expect(cleared.failure, isNull);
    });

    test('keeps the failure when nothing says otherwise', () {
      final state = const SignUpState().copyWith(
        failure: const ServerFailure('x'),
      );

      expect(state.copyWith(email: 'a@b.co').failure, const ServerFailure('x'));
    });
  });
}
