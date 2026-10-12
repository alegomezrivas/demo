import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/auth_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;
  const user = User(id: '1', name: 'Ana', email: 'ana@test.com');

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  group('LoginUseCase', () {
    test('returns the user when the repository succeeds', () async {
      when(repository.login(email: 'ana@test.com', password: 'pw'))
          .thenAnswer((_) async => right(user));

      final result = await useCase(
        const LoginParams(email: 'ana@test.com', password: 'pw'),
      );

      expect(result, right<Failure, User>(user));
      verify(repository.login(email: 'ana@test.com', password: 'pw')).called(1);
    });

    test('forwards repository failures untouched', () async {
      when(
        repository.login(
          email: anyNamed('email'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => left(const UnauthorizedFailure()));

      final result = await useCase(
        const LoginParams(email: 'a@b.co', password: 'x'),
      );

      expect(result, left<Failure, User>(const UnauthorizedFailure()));
    });

    test(
      'rejects blank e-mail or empty password without calling the repository',
      () async {
        for (final params in const [
          LoginParams(email: '  ', password: 'pw'),
          LoginParams(email: 'a@b.co', password: ''),
        ]) {
          final result = await useCase(params);

          expect(
            result,
            left<Failure, User>(const ValidationFailure('empty_credentials')),
          );
        }
        verifyZeroInteractions(repository);
      },
    );
  });
}
