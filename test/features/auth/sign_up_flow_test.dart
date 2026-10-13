import 'dart:typed_data';

import 'package:demo/app/locator.dart';
import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/security/secure_storage.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/data/datasources/mock_auth_backend.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/usecases/check_username_availability_use_case.dart';
import 'package:demo/features/auth/domain/usecases/complete_sign_up_use_case.dart';
import 'package:demo/features/auth/domain/usecases/get_current_user_use_case.dart';
import 'package:demo/features/auth/domain/usecases/login_use_case.dart';
import 'package:demo/features/auth/domain/usecases/logout_use_case.dart';
import 'package:demo/features/auth/domain/usecases/send_confirmation_code_use_case.dart';
import 'package:demo/features/auth/domain/usecases/upload_avatar_use_case.dart';
import 'package:demo/features/auth/domain/usecases/verify_confirmation_code_use_case.dart';
import 'package:demo/features/tasks/data/datasources/mock_tasks_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/in_memory_secure_storage.dart';

/// Sign-up through the real data stack (use cases, repositories, Dio, the
/// auth interceptor, the in-app mock backend and session persistence); only
/// the platform plugins are replaced.
void main() {
  /// Survives an in-test "app restart".
  late InMemorySecureStorage storage;

  const config = AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: 'https://api.test',
    useMockApi: true,
    pinningEnabled: false,
    pinnedSha256: [],
    rootPolicy: SecurityPolicy.warn,
  );

  final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 9, 9, 0xFF, 0xD9]);

  Future<void> boot() async {
    SharedPreferences.setMockInitialValues({});
    await resetLocator();
    await setupLocator(
      router: GoRouter(routes: const []),
      config: config,
      mockRoutes: [...MockAuthBackend().routes, ...MockTasksBackend().routes],
    );
    locator
      ..unregister<SecureStorage>()
      ..registerSingleton<SecureStorage>(storage);
  }

  setUp(() async {
    storage = InMemorySecureStorage();
    await boot();
  });

  tearDown(resetLocator);

  T right_<T>(Either<Failure, T> result) => result.getOrElse(
    (failure) => fail('expected success but got ${failure.code}'),
  );

  Future<String> confirm(String email) async {
    right_(
      await locator<SendConfirmationCodeUseCase>()(
        SendCodeParams(email: email),
      ),
    );
    return right_(
      await locator<VerifyConfirmationCodeUseCase>()(
        VerifyCodeParams(email: email, code: MockAuthBackend.confirmationCode),
      ),
    );
  }

  Future<User> signUp({
    String email = 'lucia@test.com',
    String username = 'lucia',
    bool remember = true,
  }) async {
    final token = await confirm(email);
    return right_(
      await locator<CompleteSignUpUseCase>()(
        CompleteSignUpParams(
          verificationToken: token,
          name: 'Lucía Gómez',
          username: username,
          password: 'Abcdef1!',
          rememberSession: remember,
        ),
      ),
    );
  }

  Future<User?> restoredUser() async =>
      right_(await locator<GetCurrentUserUseCase>()(const NoParams()));

  group('sign-up through the whole stack', () {
    test(
      'confirms the e-mail, creates the account and stores the session',
      () async {
        final user = await signUp();

        expect(user.username, 'lucia');
        expect(user.email, 'lucia@test.com');
        expect(user.hasAvatar, isFalse);
        expect(await locator<TokenStorage>().read(), isNotNull);
        expect(storage.values['auth.user'], isNotNull);
      },
    );

    test('a remembered session survives an app restart', () async {
      final user = await signUp();

      await boot();

      expect(await restoredUser(), user);
    });

    test(
      'a session that is not remembered leaves nothing on the device',
      () async {
        final user = await signUp(remember: false);

        expect(storage.values, isEmpty);
        expect(await locator<TokenStorage>().read(), isNotNull);
        expect(await restoredUser(), user);

        await boot();

        expect(storage.values, isEmpty);
        expect(await restoredUser(), isNull);
      },
    );

    test('logging out always clears memory and storage', () async {
      for (final remember in [true, false]) {
        await boot();
        await signUp(
          email: 'u$remember@test.com',
          username: 'u$remember',
          remember: remember,
        );

        right_(await locator<LogoutUseCase>()(const NoParams()));

        expect(storage.values, isEmpty, reason: 'remember=$remember');
        expect(await locator<TokenStorage>().read(), isNull);
        expect(await restoredUser(), isNull);
      }
    });

    test('the new user can sign in again with the chosen password', () async {
      await signUp();
      right_(await locator<LogoutUseCase>()(const NoParams()));

      final user = right_(
        await locator<LoginUseCase>()(
          const LoginParams(email: 'lucia@test.com', password: 'Abcdef1!'),
        ),
      );

      expect(user.name, 'Lucía Gómez');
    });

    test('a not-remembered login also keeps storage empty', () async {
      right_(
        await locator<LoginUseCase>()(
          const LoginParams(
            email: MockAuthBackend.demoEmail,
            password: MockAuthBackend.demoPassword,
            rememberSession: false,
          ),
        ),
      );

      expect(storage.values, isEmpty);
      await boot();
      expect(await restoredUser(), isNull);
    });

    test('a later remembered login replaces a memory-only session', () async {
      await signUp(remember: false);
      right_(await locator<LogoutUseCase>()(const NoParams()));

      right_(
        await locator<LoginUseCase>()(
          const LoginParams(
            email: 'lucia@test.com',
            password: 'Abcdef1!',
          ),
        ),
      );
      await boot();

      expect(await restoredUser(), isNotNull);
    });
  });

  group('sign-up errors reach the caller as failures', () {
    test('a wrong code is a ServerFailure(invalid_code)', () async {
      right_(
        await locator<SendConfirmationCodeUseCase>()(
          const SendCodeParams(email: 'a@test.com'),
        ),
      );

      final result = await locator<VerifyConfirmationCodeUseCase>()(
        const VerifyCodeParams(email: 'a@test.com', code: '000000'),
      );

      expect(
        result,
        left<Failure, String>(const ServerFailure('invalid_code')),
      );
    });

    test('a registered e-mail is a ServerFailure(email_taken)', () async {
      final result = await locator<SendConfirmationCodeUseCase>()(
        const SendCodeParams(email: MockAuthBackend.demoEmail),
      );

      expect(result, left<Failure, Unit>(const ServerFailure('email_taken')));
    });

    test('a taken username is reported before and at registration', () async {
      final available = await locator<CheckUsernameAvailabilityUseCase>()(
        'demo',
      );
      expect(available, right<Failure, bool>(false));

      final token = await confirm('b@test.com');
      final result = await locator<CompleteSignUpUseCase>()(
        CompleteSignUpParams(
          verificationToken: token,
          name: 'B',
          username: 'DEMO',
          password: 'Abcdef1!',
        ),
      );
      expect(
        result,
        left<Failure, User>(const ServerFailure('username_taken')),
      );

      // The same token still works with another username.
      final retry = await locator<CompleteSignUpUseCase>()(
        CompleteSignUpParams(
          verificationToken: token,
          name: 'B',
          username: 'bee',
          password: 'Abcdef1!',
        ),
      );
      expect(retry.isRight(), isTrue);
    });
  });

  group('avatar upload through the whole stack', () {
    test('flags the user and persists the flag when remembered', () async {
      await signUp();

      final updated = right_(await locator<UploadAvatarUseCase>()(jpeg));

      expect(updated.hasAvatar, isTrue);
      await boot();
      expect((await restoredUser())?.hasAvatar, isTrue);
    });

    test('keeps storage empty for a session that is not remembered', () async {
      await signUp(remember: false);

      final updated = right_(await locator<UploadAvatarUseCase>()(jpeg));

      expect(updated.hasAvatar, isTrue);
      expect(storage.values, isEmpty);
    });

    test('is rejected without a session', () async {
      final result = await locator<UploadAvatarUseCase>()(jpeg);

      expect(result, left<Failure, User>(const UnauthorizedFailure()));
    });

    test('a server-side rejection does not flag the user', () async {
      await signUp();

      final result = await locator<UploadAvatarUseCase>()(
        Uint8List.fromList([1, 2, 3, 4, 5, 6]),
      );

      expect(result, left<Failure, User>(const ServerFailure('invalid_image')));
      expect((await restoredUser())?.hasAvatar, isFalse);
    });
  });
}
