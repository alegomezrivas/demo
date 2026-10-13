import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/complete_sign_up_request_dto.dart';
import 'package:demo/features/auth/data/models/email_request_dto.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/data/models/username_availability_dto.dart';
import 'package:demo/features/auth/data/models/verification_response_dto.dart';
import 'package:demo/features/auth/data/models/verify_code_request_dto.dart';
import 'package:demo/features/auth/data/repositories/sign_up_repository_impl.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/auth_mocks.dart';

void main() {
  late MockSignUpRemoteDataSource signUp;
  late MockAuthRemoteDataSource auth;
  late MockAuthLocalDataSource local;
  late SignUpRepositoryImpl repository;

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
    signUp = MockSignUpRemoteDataSource();
    auth = MockAuthRemoteDataSource();
    local = MockAuthLocalDataSource();
    repository = SignUpRepositoryImpl(signUp: signUp, auth: auth, local: local);
  });

  group('sendConfirmationCode / resendConfirmationCode', () {
    test('send a sanitized e-mail to the right endpoint', () async {
      expect(
        await repository.sendConfirmationCode('  Ana@Test.COM '),
        right<Failure, Unit>(unit),
      );
      expect(
        await repository.resendConfirmationCode('Ana@Test.com'),
        right<Failure, Unit>(unit),
      );

      verify(
        signUp.sendCode(const EmailRequestDto(email: 'ana@test.com')),
      ).called(1);
      verify(
        signUp.resendCode(const EmailRequestDto(email: 'ana@test.com')),
      ).called(1);
    });

    test('map exceptions to failures keeping the backend code', () async {
      when(signUp.sendCode(any)).thenThrow(
        const ServerException(code: 'email_taken', statusCode: 409),
      );
      when(signUp.resendCode(any)).thenThrow(
        const ServerException(code: 'resend_too_soon', statusCode: 429),
      );

      expect(
        await repository.sendConfirmationCode('a@b.co'),
        left<Failure, Unit>(const ServerFailure('email_taken')),
      );
      expect(
        await repository.resendConfirmationCode('a@b.co'),
        left<Failure, Unit>(const ServerFailure('resend_too_soon')),
      );
    });

    test('report connectivity problems', () async {
      when(signUp.sendCode(any)).thenThrow(const NetworkException());

      expect(
        await repository.sendConfirmationCode('a@b.co'),
        left<Failure, Unit>(const NetworkFailure()),
      );
    });
  });

  group('verifyConfirmationCode', () {
    test('returns the token and never alters the code', () async {
      when(signUp.verifyCode(any)).thenAnswer(
        (_) async => const VerificationResponseDto(verificationToken: 'tok'),
      );

      final result = await repository.verifyConfirmationCode(
        email: ' Ana@Test.com ',
        code: '123456',
      );

      expect(result, right<Failure, String>('tok'));
      verify(
        signUp.verifyCode(
          const VerifyCodeRequestDto(email: 'ana@test.com', code: '123456'),
        ),
      ).called(1);
    });

    test('maps wrong-code errors', () async {
      when(signUp.verifyCode(any)).thenThrow(
        const ServerException(code: 'invalid_code', statusCode: 422),
      );

      expect(
        await repository.verifyConfirmationCode(
          email: 'a@b.co',
          code: '000000',
        ),
        left<Failure, String>(const ServerFailure('invalid_code')),
      );
    });
  });

  group('isUsernameAvailable', () {
    test('lower-cases the username and returns the flag', () async {
      when(signUp.isUsernameAvailable(any)).thenAnswer(
        (_) async => const UsernameAvailabilityDto(available: true),
      );

      final result = await repository.isUsernameAvailable('  Ana.P ');

      expect(result, right<Failure, bool>(true));
      verify(signUp.isUsernameAvailable('ana.p')).called(1);
    });

    test('maps failures', () async {
      when(signUp.isUsernameAvailable(any)).thenThrow(const NetworkException());

      expect(
        await repository.isUsernameAvailable('ana'),
        left<Failure, bool>(const NetworkFailure()),
      );
    });
  });

  group('completeSignUp', () {
    test(
      'sanitizes input, registers and stores a remembered session',
      () async {
        when(auth.register(any)).thenAnswer((_) async => response);

        final result = await repository.completeSignUp(
          verificationToken: 'tok',
          name: '  <b>Ana</b> ',
          username: ' Ana ',
          password: ' Pa ss<b> ',
        );

        expect(result, right<Failure, User>(userDto.toEntity()));
        final request =
            verify(auth.register(captureAny)).captured.single
                as CompleteSignUpRequestDto;
        expect(request.verificationToken, 'tok');
        expect(request.name, 'Ana');
        expect(request.username, 'ana');
        expect(request.password, ' Pa ss<b> ');
        verify(local.saveSession(tokens: tokens, user: userDto)).called(1);
      },
    );

    test('keeps the session in memory when not remembered', () async {
      when(auth.register(any)).thenAnswer((_) async => response);

      await repository.completeSignUp(
        verificationToken: 'tok',
        name: 'Ana',
        username: 'ana',
        password: 'x',
        rememberSession: false,
      );

      verify(
        local.saveSession(tokens: tokens, user: userDto, persist: false),
      ).called(1);
    });

    test('maps taken usernames and invalid tokens without storing', () async {
      final cases = <String, Failure>{
        'username_taken': const ServerFailure('username_taken'),
        'invalid_verification_token': const ServerFailure(
          'invalid_verification_token',
        ),
        'email_taken': const ServerFailure('email_taken'),
      };
      for (final entry in cases.entries) {
        when(auth.register(any)).thenThrow(ServerException(code: entry.key));

        final result = await repository.completeSignUp(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'x',
        );

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

    test('fails when the session cannot be persisted', () async {
      when(auth.register(any)).thenAnswer((_) async => response);
      when(
        local.saveSession(
          tokens: anyNamed('tokens'),
          user: anyNamed('user'),
          persist: anyNamed('persist'),
        ),
      ).thenThrow(const CacheException());

      expect(
        await repository.completeSignUp(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'x',
        ),
        left<Failure, User>(const CacheFailure()),
      );
    });
  });
}
