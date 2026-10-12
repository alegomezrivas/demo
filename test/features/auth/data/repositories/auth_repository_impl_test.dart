import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
import 'package:demo/features/auth/data/models/register_request_dto.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/auth_mocks.dart';

void main() {
  late MockAuthRemoteDataSource remote;
  late MockAuthLocalDataSource local;
  late AuthRepositoryImpl repository;

  const userDto = UserDto(id: '1', name: 'Ana', email: 'ana@test.com');
  const response = AuthResponseDto(
    user: userDto,
    accessToken: 'a',
    refreshToken: 'r',
  );
  const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

  setUp(() {
    remote = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    repository = AuthRepositoryImpl(remote: remote, local: local);
  });

  group('login', () {
    test('returns the user and stores the session', () async {
      when(remote.login(any)).thenAnswer((_) async => response);

      final result = await repository.login(
        email: 'ana@test.com',
        password: 'pw',
      );

      expect(result, right<Failure, User>(userDto.toEntity()));
      verify(local.saveSession(tokens: tokens, user: userDto)).called(1);
    });

    test('sanitizes the e-mail but never touches the password', () async {
      when(remote.login(any)).thenAnswer((_) async => response);

      await repository.login(email: '  ANA@Test.COM ', password: ' Pa ss<b> ');

      final request =
          verify(remote.login(captureAny)).captured.single as LoginRequestDto;
      expect(request.email, 'ana@test.com');
      expect(request.password, ' Pa ss<b> ');
    });

    test('maps AppExceptions to failures without storing anything', () async {
      final cases = <AppException, Failure>{
        const UnauthorizedException(): const UnauthorizedFailure(),
        const NetworkException(): const NetworkFailure(),
        const ServerException(code: 'boom'): const ServerFailure('boom'),
      };
      for (final entry in cases.entries) {
        when(remote.login(any)).thenThrow(entry.key);

        final result = await repository.login(email: 'a@b.co', password: 'pw');

        expect(result, left<Failure, User>(entry.value));
      }
      verifyNever(
        local.saveSession(tokens: anyNamed('tokens'), user: anyNamed('user')),
      );
    });

    test('hides unexpected exceptions behind UnexpectedFailure', () async {
      when(remote.login(any)).thenThrow(const FormatException('secret'));

      final result = await repository.login(email: 'a@b.co', password: 'pw');

      expect(result, left<Failure, User>(const UnexpectedFailure()));
    });

    test('fails when the session cannot be persisted', () async {
      when(remote.login(any)).thenAnswer((_) async => response);
      when(
        local.saveSession(tokens: anyNamed('tokens'), user: anyNamed('user')),
      ).thenThrow(const CacheException());

      final result = await repository.login(email: 'a@b.co', password: 'pw');

      expect(result, left<Failure, User>(const CacheFailure()));
    });
  });

  group('register', () {
    test('sanitizes input, sends it and stores the session', () async {
      when(remote.register(any)).thenAnswer((_) async => response);

      final result = await repository.register(
        name: '  <b>Ana</b> ',
        email: ' Ana@Test.com ',
        password: 'Abcdef1!',
        phone: '+57 (300) 123-4567',
      );

      expect(result.isRight(), isTrue);
      final request =
          verify(remote.register(captureAny)).captured.single
              as RegisterRequestDto;
      expect(request.name, 'Ana');
      expect(request.email, 'ana@test.com');
      expect(request.phone, '+573001234567');
      verify(local.saveSession(tokens: tokens, user: userDto)).called(1);
    });

    test('omits the phone when it is null or empty after cleaning', () async {
      when(remote.register(any)).thenAnswer((_) async => response);

      await repository.register(name: 'Ana', email: 'a@b.co', password: 'x');
      await repository.register(
        name: 'Ana',
        email: 'a@b.co',
        password: 'x',
        phone: 'abc',
      );

      final requests = verify(
        remote.register(captureAny),
      ).captured.cast<RegisterRequestDto>();
      expect(requests.map((r) => r.phone), [null, null]);
    });

    test('maps a duplicate e-mail to a ServerFailure with its code', () async {
      when(
        remote.register(any),
      ).thenThrow(const ServerException(code: 'email_taken', statusCode: 409));

      final result = await repository.register(
        name: 'Ana',
        email: 'a@b.co',
        password: 'x',
      );

      expect(result, left<Failure, User>(const ServerFailure('email_taken')));
    });
  });

  group('logout', () {
    test('clears local session data', () async {
      expect(await repository.logout(), right<Failure, Unit>(unit));
      verify(local.clear()).called(1);
    });

    test('reports storage failures', () async {
      when(local.clear()).thenThrow(const CacheException());

      expect(
        await repository.logout(),
        left<Failure, Unit>(const CacheFailure()),
      );
    });
  });

  group('restoreSession', () {
    test('returns the cached user as an entity', () async {
      when(local.readUser()).thenAnswer((_) async => userDto);

      expect(
        await repository.restoreSession(),
        right<Failure, User?>(userDto.toEntity()),
      );
    });

    test('returns null when there is no session', () async {
      when(local.readUser()).thenAnswer((_) async => null);

      expect(await repository.restoreSession(), right<Failure, User?>(null));
    });

    test('maps storage errors to failures', () async {
      when(
        local.readUser(),
      ).thenThrow(const CacheException('invalid_user_cache'));

      expect(
        await repository.restoreSession(),
        left<Failure, User?>(const CacheFailure('invalid_user_cache')),
      );
    });
  });
}
