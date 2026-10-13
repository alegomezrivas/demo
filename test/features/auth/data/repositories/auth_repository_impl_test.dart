import 'dart:async';

import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
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

  const userDto = UserDto(
    id: '1',
    name: 'Ana',
    email: 'ana@test.com',
    username: 'ana',
  );
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
      verify(
        local.saveSession(tokens: tokens, user: userDto),
      ).called(1);
    });

    test('keeps the session in memory only when not remembered', () async {
      when(remote.login(any)).thenAnswer((_) async => response);

      await repository.login(
        email: 'ana@test.com',
        password: 'pw',
        rememberSession: false,
      );

      verify(
        local.saveSession(tokens: tokens, user: userDto, persist: false),
      ).called(1);
    });

    test('remembers the session by default', () async {
      when(remote.login(any)).thenAnswer((_) async => response);

      await repository.login(email: 'ana@test.com', password: 'pw');

      verify(
        local.saveSession(tokens: tokens, user: userDto),
      ).called(1);
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
        local.saveSession(
          tokens: anyNamed('tokens'),
          user: anyNamed('user'),
          persist: anyNamed('persist'),
        ),
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
        local.saveSession(
          tokens: anyNamed('tokens'),
          user: anyNamed('user'),
          persist: anyNamed('persist'),
        ),
      ).thenThrow(const CacheException());

      final result = await repository.login(email: 'a@b.co', password: 'pw');

      expect(result, left<Failure, User>(const CacheFailure()));
    });
  });

  group('logout', () {
    test('revokes the session on the server, then clears local data', () async {
      when(local.readRefreshToken()).thenAnswer((_) async => 'r');

      expect(await repository.logout(), right<Failure, Unit>(unit));

      verifyInOrder([remote.logout('r'), local.clear()]);
    });

    test('only clears local data when there is no refresh token', () async {
      when(local.readRefreshToken()).thenAnswer((_) async => null);

      expect(await repository.logout(), right<Failure, Unit>(unit));

      verifyNever(remote.logout(any));
      verify(local.clear()).called(1);
    });

    test('still signs out when the server call fails', () async {
      when(local.readRefreshToken()).thenAnswer((_) async => 'r');
      final errors = <Exception>[
        const NetworkException(),
        const ServerException(code: 'boom', statusCode: 500),
        const UnauthorizedException(),
        const FormatException('unexpected'),
      ];
      for (final error in errors) {
        clearInteractions(local);
        when(remote.logout(any)).thenThrow(error);

        final result = await repository.logout();

        expect(result, right<Failure, Unit>(unit), reason: '$error');
        verify(local.clear()).called(1);
      }
    });

    test('does not wait forever for a slow server', () async {
      repository = AuthRepositoryImpl(
        remote: remote,
        local: local,
        serverLogoutTimeout: const Duration(milliseconds: 1),
      );
      when(local.readRefreshToken()).thenAnswer((_) async => 'r');
      when(remote.logout(any)).thenAnswer((_) => Completer<void>().future);

      expect(await repository.logout(), right<Failure, Unit>(unit));

      verify(local.clear()).called(1);
    });

    test('still signs out when the refresh token cannot be read', () async {
      when(local.readRefreshToken()).thenThrow(const CacheException());

      expect(await repository.logout(), right<Failure, Unit>(unit));

      verifyNever(remote.logout(any));
      verify(local.clear()).called(1);
    });

    test('reports storage failures when clearing', () async {
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
