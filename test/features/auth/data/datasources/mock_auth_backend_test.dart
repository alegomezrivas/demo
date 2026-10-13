import 'dart:typed_data';

import 'package:demo/core/network/mock/mock_api_interceptor.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/data/datasources/mock_auth_backend.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Dio dio;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..interceptors.add(
        MockApiInterceptor(
          routes: MockAuthBackend().routes,
          settings: const MockApiSettings(latency: Duration.zero),
        ),
      );
  });

  Future<Response<Map<String, dynamic>>> post(
    String path,
    Map<String, dynamic> body,
  ) => dio.post<Map<String, dynamic>>(path, data: body);

  TypeMatcher<DioException> status(int code, [String? bodyCode]) =>
      isA<DioException>()
          .having((e) => e.response?.statusCode, 'status', code)
          .having(
            (e) => (e.response?.data as Map<String, dynamic>)['code'],
            'code',
            bodyCode ?? isNotNull,
          );

  group('login', () {
    test('accepts the demo account (e-mail is case-insensitive)', () async {
      final response = await post(AuthEndpoints.login, {
        'email': 'DEMO@starkshowcase.dev',
        'password': MockAuthBackend.demoPassword,
      });

      expect(response.data?['accessToken'], startsWith('mock-access-'));
      expect(
        (response.data?['user'] as Map<String, dynamic>)['email'],
        MockAuthBackend.demoEmail,
      );
    });

    test('rejects a wrong password and unknown users with 401', () async {
      await expectLater(
        post(AuthEndpoints.login, {
          'email': MockAuthBackend.demoEmail,
          'password': 'nope',
        }),
        throwsA(status(401, 'invalid_credentials')),
      );
      await expectLater(
        post(AuthEndpoints.login, {'email': 'x@y.co', 'password': 'nope'}),
        throwsA(status(401, 'invalid_credentials')),
      );
    });

    test('rejects a malformed body with 401', () async {
      await expectLater(
        dio.post<dynamic>(AuthEndpoints.login, data: 'oops'),
        throwsA(status(401)),
      );
    });
  });

  Future<String> confirmEmail(String email) async {
    await post(AuthEndpoints.signUpEmail, {'email': email});
    final response = await post(AuthEndpoints.signUpVerify, {
      'email': email,
      'code': MockAuthBackend.confirmationCode,
    });
    return response.data?['verificationToken'] as String;
  }

  group('sign-up: sending the code', () {
    test('answers 204 for a new e-mail, for both endpoints', () async {
      for (final path in [
        AuthEndpoints.signUpEmail,
        AuthEndpoints.signUpResend,
      ]) {
        final response = await post(path, {'email': 'new@test.com'});

        expect(response.statusCode, 204);
      }
    });

    test('rejects registered e-mails with 409', () async {
      await expectLater(
        post(AuthEndpoints.signUpEmail, {'email': MockAuthBackend.demoEmail}),
        throwsA(status(409, 'email_taken')),
      );
    });

    test('rejects malformed e-mails with 422', () async {
      await expectLater(
        post(AuthEndpoints.signUpEmail, {'email': 'nope'}),
        throwsA(status(422, 'validation_error')),
      );
    });
  });

  group('sign-up: confirming the code', () {
    Future<Response<Map<String, dynamic>>> verify(String email, String code) =>
        post(AuthEndpoints.signUpVerify, {'email': email, 'code': code});

    test('returns a verification token for the demo code', () async {
      await post(AuthEndpoints.signUpEmail, {'email': 'v@test.com'});

      final response = await verify(
        'v@test.com',
        MockAuthBackend.confirmationCode,
      );

      expect(
        response.data?['verificationToken'],
        startsWith('mock-verification-'),
      );
    });

    test('rejects a wrong code with invalid_code', () async {
      await post(AuthEndpoints.signUpEmail, {'email': 'v@test.com'});

      await expectLater(
        verify('v@test.com', '000000'),
        throwsA(status(422, 'invalid_code')),
      );
    });

    test('answers an e-mail with no pending code like a wrong code', () async {
      await expectLater(
        verify('nobody@test.com', MockAuthBackend.confirmationCode),
        throwsA(status(422, 'invalid_code')),
      );
    });

    test('discards the code after too many wrong guesses', () async {
      await post(AuthEndpoints.signUpEmail, {'email': 'b@test.com'});
      for (var i = 1; i < MockAuthBackend.maxCodeAttempts; i++) {
        await expectLater(
          verify('b@test.com', '000000'),
          throwsA(status(422, 'invalid_code')),
        );
      }
      await expectLater(
        verify('b@test.com', '000000'),
        throwsA(status(429, 'too_many_attempts')),
      );

      await expectLater(
        verify('b@test.com', MockAuthBackend.confirmationCode),
        throwsA(status(422, 'invalid_code')),
      );
    });

    test('a new code resets the attempts', () async {
      await post(AuthEndpoints.signUpEmail, {'email': 'r@test.com'});
      await expectLater(verify('r@test.com', '000000'), throwsA(status(422)));

      await post(AuthEndpoints.signUpResend, {'email': 'r@test.com'});

      expect(
        (await verify(
          'r@test.com',
          MockAuthBackend.confirmationCode,
        )).statusCode,
        200,
      );
    });

    test('rejects codes that are not six digits with 422', () async {
      await post(AuthEndpoints.signUpEmail, {'email': 'v@test.com'});

      await expectLater(
        verify('v@test.com', '12'),
        throwsA(status(422, 'validation_error')),
      );
    });
  });

  group('username availability', () {
    Future<bool> available(String username) async {
      final response = await dio.get<Map<String, dynamic>>(
        AuthEndpoints.usernameAvailable,
        queryParameters: {'username': username},
      );
      return response.data?['available'] as bool;
    }

    test('reports free and taken usernames, ignoring case', () async {
      expect(await available('free_name'), isTrue);
      expect(await available('DEMO'), isFalse);
    });

    test('rejects malformed usernames with 422', () async {
      await expectLater(
        dio.get<dynamic>(
          AuthEndpoints.usernameAvailable,
          queryParameters: {'username': 'bad name'},
        ),
        throwsA(status(422, 'validation_error')),
      );
    });
  });

  group('register', () {
    Map<String, dynamic> body(String token, {String username = 'ana'}) => {
      'verificationToken': token,
      'name': 'Ana',
      'username': username,
      'password': 'Abcdef1!',
    };

    test('creates an account and returns a session with 201', () async {
      final token = await confirmEmail('ana@test.com');

      final response = await post(AuthEndpoints.register, body(token));

      expect(response.statusCode, 201);
      final user = response.data?['user'] as Map<String, dynamic>;
      expect(user['name'], 'Ana');
      expect(user['email'], 'ana@test.com');
      expect(user['username'], 'ana');
      expect(user['hasAvatar'], isFalse);
      expect(user.containsKey('phone'), isFalse);
    });

    test(
      'takes the e-mail from the token, so the new user can sign in',
      () async {
        final token = await confirmEmail('ana@test.com');
        await post(AuthEndpoints.register, body(token));

        final response = await post(AuthEndpoints.login, {
          'email': 'ana@test.com',
          'password': 'Abcdef1!',
        });

        expect(response.statusCode, 200);
      },
    );

    test('rejects an unknown token with 422', () async {
      await expectLater(
        post(AuthEndpoints.register, body('made-up')),
        throwsA(status(422, 'invalid_verification_token')),
      );
    });

    test('accepts a token only once', () async {
      final token = await confirmEmail('ana@test.com');
      await post(AuthEndpoints.register, body(token));

      await expectLater(
        post(AuthEndpoints.register, body(token, username: 'other')),
        throwsA(status(422, 'invalid_verification_token')),
      );
    });

    test(
      'rejects a taken username with 409 and keeps the token usable',
      () async {
        final token = await confirmEmail('ana@test.com');

        await expectLater(
          post(AuthEndpoints.register, body(token, username: 'DEMO')),
          throwsA(status(409, 'username_taken')),
        );

        final retry = await post(
          AuthEndpoints.register,
          body(token, username: 'ana2'),
        );
        expect(retry.statusCode, 201);
      },
    );

    test('rejects invalid usernames and weak passwords with 422', () async {
      final token = await confirmEmail('ana@test.com');

      await expectLater(
        post(AuthEndpoints.register, body(token, username: 'no spaces')),
        throwsA(status(422, 'validation_error')),
      );
      await expectLater(
        post(AuthEndpoints.register, {...body(token), 'password': 'weak'}),
        throwsA(status(422, 'validation_error')),
      );
      await expectLater(
        post(AuthEndpoints.register, {...body(token), 'name': ' '}),
        throwsA(status(422, 'validation_error')),
      );
    });
  });

  group('avatar', () {
    final jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 1, 2, 3, 0xFF, 0xD9]);

    Future<Map<String, dynamic>> signIn() async {
      final response = await post(AuthEndpoints.login, {
        'email': MockAuthBackend.demoEmail,
        'password': MockAuthBackend.demoPassword,
      });
      return response.data ?? {};
    }

    Future<Response<dynamic>> put(Object? data, String? token) =>
        dio.put<dynamic>(
          AuthEndpoints.avatar,
          data: data,
          options: Options(
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          ),
        );

    test('stores a JPEG for the signed-in user (204)', () async {
      final session = await signIn();

      final response = await put(jpeg, session['accessToken'] as String);

      expect(response.statusCode, 204);
    });

    test('flags the user on the next sign-in', () async {
      final session = await signIn();
      await put(jpeg, session['accessToken'] as String);

      final again = await signIn();

      expect((again['user'] as Map<String, dynamic>)['hasAvatar'], isTrue);
    });

    test('requires a session', () async {
      await expectLater(put(jpeg, null), throwsA(status(401, 'unauthorized')));
      await expectLater(put(jpeg, 'forged'), throwsA(status(401)));
    });

    test('rejects anything that is not a JPEG', () async {
      final session = await signIn();
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0xFF, 0xD9]);

      await expectLater(
        put(png, session['accessToken'] as String),
        throwsA(status(422, 'invalid_image')),
      );
      await expectLater(
        put('text', session['accessToken'] as String),
        throwsA(status(422, 'invalid_image')),
      );
    });
  });

  group('refresh', () {
    Future<Map<String, dynamic>> signIn() async {
      final response = await post(AuthEndpoints.login, {
        'email': MockAuthBackend.demoEmail,
        'password': MockAuthBackend.demoPassword,
      });
      return response.data ?? {};
    }

    test('rotates the token pair', () async {
      final session = await signIn();

      final response = await post(NetworkConstants.refreshPath, {
        'refreshToken': session['refreshToken'],
      });

      expect(response.data?['accessToken'], isNot(session['accessToken']));
      expect(response.data?['refreshToken'], isNot(session['refreshToken']));
    });

    test('invalidates a refresh token after it was used', () async {
      final session = await signIn();
      await post(NetworkConstants.refreshPath, {
        'refreshToken': session['refreshToken'],
      });

      await expectLater(
        post(NetworkConstants.refreshPath, {
          'refreshToken': session['refreshToken'],
        }),
        throwsA(status(401, 'invalid_refresh_token')),
      );
    });

    test('rejects unknown refresh tokens', () async {
      await expectLater(
        post(NetworkConstants.refreshPath, {'refreshToken': 'forged'}),
        throwsA(status(401)),
      );
    });
  });

  group('logout', () {
    Future<String> signInAndGetRefreshToken() async {
      final response = await post(AuthEndpoints.login, {
        'email': MockAuthBackend.demoEmail,
        'password': MockAuthBackend.demoPassword,
      });
      return response.data?['refreshToken'] as String;
    }

    test('answers 204 and revokes the refresh token', () async {
      final refreshToken = await signInAndGetRefreshToken();

      final response = await post(AuthEndpoints.logout, {
        'refreshToken': refreshToken,
      });

      expect(response.statusCode, 204);
      await expectLater(
        post(NetworkConstants.refreshPath, {'refreshToken': refreshToken}),
        throwsA(status(401, 'invalid_refresh_token')),
      );
    });

    test('is idempotent for used and unknown tokens', () async {
      final refreshToken = await signInAndGetRefreshToken();
      await post(AuthEndpoints.logout, {'refreshToken': refreshToken});

      final again = await post(AuthEndpoints.logout, {
        'refreshToken': refreshToken,
      });
      final unknown = await post(AuthEndpoints.logout, {
        'refreshToken': 'never-issued',
      });

      expect(again.statusCode, 204);
      expect(unknown.statusCode, 204);
    });

    test('rejects a missing token with 422', () async {
      await expectLater(
        post(AuthEndpoints.logout, {}),
        throwsA(status(422, 'validation_error')),
      );
    });
  });
}
