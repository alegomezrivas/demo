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

  group('register', () {
    final body = {
      'name': 'Ana',
      'email': 'ana@test.com',
      'password': 'Abcdef1!',
      'phone': '300',
    };

    test('creates an account and returns a session with 201', () async {
      final response = await post(AuthEndpoints.register, body);

      expect(response.statusCode, 201);
      expect((response.data?['user'] as Map<String, dynamic>)['phone'], '300');
    });

    test('lets the new user sign in afterwards', () async {
      await post(AuthEndpoints.register, body);

      final response = await post(AuthEndpoints.login, {
        'email': 'ana@test.com',
        'password': 'Abcdef1!',
      });

      expect(response.statusCode, 200);
    });

    test('rejects duplicated e-mails with 409', () async {
      await post(AuthEndpoints.register, body);

      await expectLater(
        post(AuthEndpoints.register, body),
        throwsA(status(409, 'email_taken')),
      );
    });

    test('rejects the demo e-mail with 409', () async {
      await expectLater(
        post(AuthEndpoints.register, {
          ...body,
          'email': MockAuthBackend.demoEmail,
        }),
        throwsA(status(409, 'email_taken')),
      );
    });

    test('rejects missing fields with 422', () async {
      await expectLater(
        post(AuthEndpoints.register, {
          'name': '',
          'email': 'a@b.co',
          'password': 'x',
        }),
        throwsA(status(422, 'validation_error')),
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
