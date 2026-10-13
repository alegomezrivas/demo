import 'dart:typed_data';

import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:demo/features/auth/domain/usecases/check_username_availability_use_case.dart';
import 'package:demo/features/auth/domain/usecases/complete_sign_up_use_case.dart';
import 'package:demo/features/auth/domain/usecases/send_confirmation_code_use_case.dart';
import 'package:demo/features/auth/domain/usecases/upload_avatar_use_case.dart';
import 'package:demo/features/auth/domain/usecases/verify_confirmation_code_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/auth_mocks.dart';

void main() {
  late MockSignUpRepository repository;
  const user = User(
    id: '1',
    name: 'Ana',
    email: 'ana@test.com',
    username: 'ana',
  );

  setUp(() {
    repository = MockSignUpRepository();
    provideDummy<Either<Failure, Unit>>(right(unit));
    provideDummy<Either<Failure, String>>(right(''));
    provideDummy<Either<Failure, bool>>(right(false));
    provideDummy<Either<Failure, User>>(right(user));
  });

  group('SendConfirmationCodeUseCase', () {
    late SendConfirmationCodeUseCase useCase;
    setUp(() => useCase = SendConfirmationCodeUseCase(repository));

    test('sends the first code through the repository', () async {
      when(
        repository.sendConfirmationCode('a@b.co'),
      ).thenAnswer((_) async => right(unit));

      final result = await useCase(const SendCodeParams(email: 'a@b.co'));

      expect(result, right<Failure, Unit>(unit));
      verifyNever(repository.resendConfirmationCode(any));
    });

    test('uses the resend endpoint when asked again', () async {
      when(
        repository.resendConfirmationCode('a@b.co'),
      ).thenAnswer((_) async => right(unit));

      await useCase(const SendCodeParams(email: 'a@b.co', isResend: true));

      verify(repository.resendConfirmationCode('a@b.co')).called(1);
      verifyNever(repository.sendConfirmationCode(any));
    });

    test('forwards repository failures', () async {
      when(
        repository.sendConfirmationCode(any),
      ).thenAnswer((_) async => left(const ServerFailure('email_taken')));

      final result = await useCase(const SendCodeParams(email: 'a@b.co'));

      expect(result, left<Failure, Unit>(const ServerFailure('email_taken')));
    });

    test('rejects malformed e-mails without calling the repository', () async {
      for (final email in ['', '  ', 'nope', 'a@b']) {
        final result = await useCase(SendCodeParams(email: email));

        expect(
          result,
          left<Failure, Unit>(const ValidationFailure('invalid_email')),
          reason: email,
        );
      }
      verifyZeroInteractions(repository);
    });
  });

  group('VerifyConfirmationCodeUseCase', () {
    late VerifyConfirmationCodeUseCase useCase;
    setUp(() => useCase = VerifyConfirmationCodeUseCase(repository));

    test('returns the verification token', () async {
      when(
        repository.verifyConfirmationCode(email: 'a@b.co', code: '123456'),
      ).thenAnswer((_) async => right('token'));

      final result = await useCase(
        const VerifyCodeParams(email: 'a@b.co', code: '123456'),
      );

      expect(result, right<Failure, String>('token'));
    });

    test('forwards a wrong-code failure', () async {
      when(
        repository.verifyConfirmationCode(
          email: anyNamed('email'),
          code: anyNamed('code'),
        ),
      ).thenAnswer((_) async => left(const ServerFailure('invalid_code')));

      final result = await useCase(
        const VerifyCodeParams(email: 'a@b.co', code: '000000'),
      );

      expect(
        result,
        left<Failure, String>(const ServerFailure('invalid_code')),
      );
    });

    test('rejects codes that are not six digits', () async {
      for (final code in ['', '123', '1234567', 'abcdef']) {
        final result = await useCase(
          VerifyCodeParams(email: 'a@b.co', code: code),
        );

        expect(
          result,
          left<Failure, String>(const ValidationFailure('invalid_code')),
          reason: code,
        );
      }
      verifyZeroInteractions(repository);
    });
  });

  group('CheckUsernameAvailabilityUseCase', () {
    late CheckUsernameAvailabilityUseCase useCase;
    setUp(() => useCase = CheckUsernameAvailabilityUseCase(repository));

    test('returns the availability', () async {
      when(
        repository.isUsernameAvailable('ana'),
      ).thenAnswer((_) async => right(true));

      expect(await useCase('ana'), right<Failure, bool>(true));
    });

    test('does not ask the server about malformed usernames', () async {
      for (final name in ['', 'ab', 'bad name', 'dot.']) {
        expect(
          await useCase(name),
          left<Failure, bool>(const ValidationFailure('invalid_username')),
          reason: name,
        );
      }
      verifyZeroInteractions(repository);
    });
  });

  group('CompleteSignUpUseCase', () {
    late CompleteSignUpUseCase useCase;
    setUp(() => useCase = CompleteSignUpUseCase(repository));

    const valid = CompleteSignUpParams(
      verificationToken: 'tok',
      name: 'Ana',
      username: 'ana',
      password: 'Str0ng!Pass',
    );

    test('creates the account and remembers the session by default', () async {
      when(
        repository.completeSignUp(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'Str0ng!Pass',
        ),
      ).thenAnswer((_) async => right(user));

      final result = await useCase(valid);

      expect(result, right<Failure, User>(user));
    });

    test('passes along that the session must not be remembered', () async {
      when(
        repository.completeSignUp(
          verificationToken: anyNamed('verificationToken'),
          name: anyNamed('name'),
          username: anyNamed('username'),
          password: anyNamed('password'),
          rememberSession: false,
        ),
      ).thenAnswer((_) async => right(user));

      await useCase(
        const CompleteSignUpParams(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'Str0ng!Pass',
          rememberSession: false,
        ),
      );

      verify(
        repository.completeSignUp(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'Str0ng!Pass',
          rememberSession: false,
        ),
      ).called(1);
    });

    test('rejects blank names and tokens', () async {
      for (final params in const [
        CompleteSignUpParams(
          verificationToken: '',
          name: 'Ana',
          username: 'ana',
          password: 'Str0ng!Pass',
        ),
        CompleteSignUpParams(
          verificationToken: 'tok',
          name: '   ',
          username: 'ana',
          password: 'Str0ng!Pass',
        ),
      ]) {
        expect(
          await useCase(params),
          left<Failure, User>(const ValidationFailure('empty_fields')),
        );
      }
      verifyZeroInteractions(repository);
    });

    test('rejects invalid usernames', () async {
      final result = await useCase(
        const CompleteSignUpParams(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'no spaces',
          password: 'Str0ng!Pass',
        ),
      );

      expect(
        result,
        left<Failure, User>(const ValidationFailure('invalid_username')),
      );
      verifyZeroInteractions(repository);
    });

    test('rejects weak passwords', () async {
      final result = await useCase(
        const CompleteSignUpParams(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'weak',
        ),
      );

      expect(
        result,
        left<Failure, User>(const ValidationFailure('weak_password')),
      );
      verifyZeroInteractions(repository);
    });

    test('forwards a taken-username failure', () async {
      when(
        repository.completeSignUp(
          verificationToken: anyNamed('verificationToken'),
          name: anyNamed('name'),
          username: anyNamed('username'),
          password: anyNamed('password'),
        ),
      ).thenAnswer((_) async => left(const ServerFailure('username_taken')));

      final result = await useCase(valid);

      expect(
        result,
        left<Failure, User>(const ServerFailure('username_taken')),
      );
    });
  });

  group('UploadAvatarUseCase', () {
    late MockAvatarRepository avatars;
    late UploadAvatarUseCase useCase;

    setUp(() {
      avatars = MockAvatarRepository();
      useCase = UploadAvatarUseCase(avatars);
    });

    test('uploads a picture within the limit', () async {
      final jpeg = Uint8List.fromList([1, 2, 3]);
      when(avatars.uploadAvatar(jpeg)).thenAnswer((_) async => right(user));

      expect(await useCase(jpeg), right<Failure, User>(user));
    });

    test('accepts exactly the size limit', () async {
      final jpeg = Uint8List(AuthRules.maxAvatarBytes);
      when(avatars.uploadAvatar(jpeg)).thenAnswer((_) async => right(user));

      expect((await useCase(jpeg)).isRight(), isTrue);
    });

    test('rejects one byte over the limit', () async {
      final result = await useCase(Uint8List(AuthRules.maxAvatarBytes + 1));

      expect(
        result,
        left<Failure, User>(const ValidationFailure('image_too_large')),
      );
      verifyZeroInteractions(avatars);
    });

    test('rejects an empty picture', () async {
      expect(
        await useCase(Uint8List(0)),
        left<Failure, User>(const ValidationFailure('invalid_image')),
      );
      verifyZeroInteractions(avatars);
    });
  });
}
