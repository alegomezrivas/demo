import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:demo/features/auth/data/models/complete_sign_up_request_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_adapter.dart';

void main() {
  const login = LoginRequestDto(email: 'a@b.co', password: 'pw');
  final okBody = {
    'user': {
      'id': '1',
      'name': 'Ana',
      'email': 'a@b.co',
      'username': 'ana',
      'hasAvatar': false,
    },
    'accessToken': 'a',
    'refreshToken': 'r',
  };

  late FakeHttpAdapter adapter;

  AuthRemoteDataSourceImpl build(
    ResponseBody Function(RequestOptions) handler,
  ) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    return AuthRemoteDataSourceImpl(dio);
  }

  group('login', () {
    test('posts credentials without auth and parses the response', () async {
      final source = build((_) => FakeHttpAdapter.json(okBody));

      final response = await source.login(login);

      expect(response.user.name, 'Ana');
      expect(response.accessToken, 'a');
      final request = adapter.requests.single;
      expect(request.path, AuthEndpoints.login);
      expect(request.method, 'POST');
      expect(request.data, {'email': 'a@b.co', 'password': 'pw'});
      expect(request.extra[RequestExtras.skipAuth], isTrue);
    });

    test('maps 401 to UnauthorizedException', () async {
      final source = build(
        (_) =>
            FakeHttpAdapter.json({'code': 'invalid_credentials'}, status: 401),
      );

      await expectLater(
        source.login(login),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('maps server errors keeping only the code', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'boom'}, status: 500),
      );

      await expectLater(
        source.login(login),
        throwsA(isA<ServerException>().having((e) => e.code, 'code', 'boom')),
      );
    });

    test('maps connection errors to NetworkException', () async {
      final source = build(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'down',
        ),
      );

      await expectLater(source.login(login), throwsA(isA<NetworkException>()));
    });

    test('rejects a body that does not match the contract', () async {
      final source = build((_) => FakeHttpAdapter.json({'user': 'oops'}));

      await expectLater(
        source.login(login),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    });

    test('rejects an empty body', () async {
      final source = build((_) => ResponseBody.fromString('', 200));

      await expectLater(
        source.login(login),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'empty_response',
          ),
        ),
      );
    });
  });

  group('register', () {
    test('posts the account data and parses the response', () async {
      final source = build((_) => FakeHttpAdapter.json(okBody, status: 201));

      final response = await source.register(
        const CompleteSignUpRequestDto(
          verificationToken: 'tok',
          name: 'Ana',
          username: 'ana',
          password: 'pw',
        ),
      );

      expect(response.refreshToken, 'r');
      final request = adapter.requests.single;
      expect(request.path, AuthEndpoints.register);
      expect(request.data, {
        'verificationToken': 'tok',
        'name': 'Ana',
        'username': 'ana',
        'password': 'pw',
      });
      expect(request.extra[RequestExtras.skipAuth], isTrue);
    });

    test(
      'surfaces a conflict as ServerException with the backend code',
      () async {
        final source = build(
          (_) => FakeHttpAdapter.json({'code': 'email_taken'}, status: 409),
        );

        await expectLater(
          source.register(
            const CompleteSignUpRequestDto(
              verificationToken: 'tok',
              name: 'A',
              username: 'ana',
              password: 'pw',
            ),
          ),
          throwsA(
            isA<ServerException>()
                .having((e) => e.code, 'code', 'email_taken')
                .having((e) => e.statusCode, 'status', 409),
          ),
        );
      },
    );
  });

  group('logout', () {
    test('posts the refresh token without auth', () async {
      final source = build((_) => ResponseBody.fromString('', 204));

      await source.logout('refresh-1');

      final request = adapter.requests.single;
      expect(request.path, AuthEndpoints.logout);
      expect(request.method, 'POST');
      expect(request.data, {'refreshToken': 'refresh-1'});
      expect(request.extra[RequestExtras.skipAuth], isTrue);
    });

    test('maps server errors keeping only the code', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'rate_limited'}, status: 429),
      );

      await expectLater(
        source.logout('r'),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'rate_limited')
              .having((e) => e.statusCode, 'statusCode', 429),
        ),
      );
    });

    test('maps connection errors to NetworkException', () async {
      final source = build(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'down',
        ),
      );

      await expectLater(source.logout('r'), throwsA(isA<NetworkException>()));
    });
  });
}
