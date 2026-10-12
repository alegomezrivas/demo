import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/register_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/auth_mocks.dart';

void main() {
  late MockAuthRepository repository;
  late RegisterUseCase useCase;
  const user = User(id: '1', name: 'Ana', email: 'ana@test.com');
  const params = RegisterParams(
    name: 'Ana',
    email: 'ana@test.com',
    password: 'Abcdef1!',
    phone: '3001234567',
  );

  setUp(() {
    repository = MockAuthRepository();
    useCase = RegisterUseCase(repository);
  });

  void stubRegister(Either<Failure, User> result) {
    when(
      repository.register(
        name: anyNamed('name'),
        email: anyNamed('email'),
        password: anyNamed('password'),
        phone: anyNamed('phone'),
      ),
    ).thenAnswer((_) async => result);
  }

  group('RegisterUseCase', () {
    test('passes every field to the repository and returns the user', () async {
      stubRegister(right(user));

      final result = await useCase(params);

      expect(result, right<Failure, User>(user));
      verify(
        repository.register(
          name: 'Ana',
          email: 'ana@test.com',
          password: 'Abcdef1!',
          phone: '3001234567',
        ),
      ).called(1);
    });

    test('forwards repository failures', () async {
      stubRegister(left(const ServerFailure('email_taken')));

      expect(
        await useCase(params),
        left<Failure, User>(const ServerFailure('email_taken')),
      );
    });

    test(
      'rejects missing required fields without calling the repository',
      () async {
        for (final invalid in const [
          RegisterParams(name: ' ', email: 'a@b.co', password: 'x'),
          RegisterParams(name: 'Ana', email: '', password: 'x'),
          RegisterParams(name: 'Ana', email: 'a@b.co', password: ''),
        ]) {
          expect(
            await useCase(invalid),
            left<Failure, User>(const ValidationFailure('empty_fields')),
          );
        }
        verifyZeroInteractions(repository);
      },
    );

    test('allows the phone to be omitted', () async {
      stubRegister(right(user));

      final result = await useCase(
        const RegisterParams(name: 'Ana', email: 'a@b.co', password: 'x'),
      );

      expect(result.isRight(), isTrue);
    });
  });
}
