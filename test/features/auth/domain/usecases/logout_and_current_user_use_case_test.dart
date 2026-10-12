import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/auth_mocks.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  group('LogoutUseCase', () {
    test('delegates to the repository', () async {
      when(repository.logout()).thenAnswer((_) async => right(unit));

      final result = await LogoutUseCase(repository)(const NoParams());

      expect(result, right<Failure, Unit>(unit));
      verify(repository.logout()).called(1);
    });

    test('forwards failures', () async {
      when(
        repository.logout(),
      ).thenAnswer((_) async => left(const CacheFailure()));

      expect(
        await LogoutUseCase(repository)(const NoParams()),
        left<Failure, Unit>(const CacheFailure()),
      );
    });
  });

  group('GetCurrentUserUseCase', () {
    test('returns the restored user', () async {
      const user = User(id: '1', name: 'Ana', email: 'a@b.co');
      when(repository.restoreSession()).thenAnswer((_) async => right(user));

      expect(
        await GetCurrentUserUseCase(repository)(const NoParams()),
        right<Failure, User?>(user),
      );
    });

    test('returns null when there is no session', () async {
      when(repository.restoreSession()).thenAnswer((_) async => right(null));

      expect(
        await GetCurrentUserUseCase(repository)(const NoParams()),
        right<Failure, User?>(null),
      );
    });

    test('forwards failures', () async {
      when(
        repository.restoreSession(),
      ).thenAnswer((_) async => left(const CacheFailure()));

      expect(
        (await GetCurrentUserUseCase(repository)(const NoParams())).isLeft(),
        isTrue,
      );
    });
  });
}
