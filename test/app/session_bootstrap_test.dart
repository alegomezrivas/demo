import 'package:demo/app/session_bootstrap.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/services/session_service.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../features/auth/helpers/auth_mocks.dart';

void main() {
  late MockGetCurrentUserUseCase getCurrentUser;
  late SessionService session;

  setUp(() {
    getCurrentUser = MockGetCurrentUserUseCase();
    session = SessionService();
  });

  Future<void> run(Either<Failure, User?> result) {
    when(getCurrentUser(any)).thenAnswer((_) async => result);
    return restoreSession(getCurrentUser: getCurrentUser, session: session);
  }

  group('restoreSession', () {
    test('signs in when a stored user exists', () async {
      await run(right(const User(id: '1', name: 'Ana', email: 'a@b.co')));

      expect(session.isAuthenticated, isTrue);
    });

    test('stays signed out when there is no stored user', () async {
      await run(right(null));

      expect(session.isAuthenticated, isFalse);
    });

    test('stays signed out when restoring fails', () async {
      await run(left(const CacheFailure()));

      expect(session.isAuthenticated, isFalse);
    });

    test('signs out a session that was wrongly marked as active', () async {
      session.markSignedIn();

      await run(right(null));

      expect(session.isAuthenticated, isFalse);
    });
  });
}
