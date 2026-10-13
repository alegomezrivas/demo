import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/data/datasources/sign_up_remote_data_source.dart';
import 'package:demo/features/auth/data/models/email_request_dto.dart';
import 'package:demo/features/auth/data/models/verify_code_request_dto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;

  SignUpRemoteDataSourceImpl build(
    ResponseBody Function(RequestOptions) handler,
  ) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    return SignUpRemoteDataSourceImpl(dio);
  }

  const email = EmailRequestDto(email: 'a@b.co');

  group('sendCode / resendCode', () {
    test('post the e-mail anonymously', () async {
      final source = build((_) => ResponseBody.fromString('', 204));

      await source.sendCode(email);
      await source.resendCode(email);

      expect(adapter.requests.map((r) => r.path), [
        AuthEndpoints.signUpEmail,
        AuthEndpoints.signUpResend,
      ]);
      for (final request in adapter.requests) {
        expect(request.method, 'POST');
        expect(request.data, {'email': 'a@b.co'});
        expect(request.extra[RequestExtras.skipAuth], isTrue);
      }
    });

    test('surface a taken e-mail with its code', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'email_taken'}, status: 409),
      );

      await expectLater(
        source.sendCode(email),
        throwsA(
          isA<ServerException>()
              .having((e) => e.code, 'code', 'email_taken')
              .having((e) => e.statusCode, 'status', 409),
        ),
      );
    });

    test('surface the resend throttle', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'resend_too_soon'}, status: 429),
      );

      await expectLater(
        source.resendCode(email),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'resend_too_soon',
          ),
        ),
      );
    });

    test('map connection errors to NetworkException', () async {
      final source = build(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'down',
        ),
      );

      await expectLater(
        source.sendCode(email),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('verifyCode', () {
    const request = VerifyCodeRequestDto(email: 'a@b.co', code: '123456');

    test('posts e-mail and code and parses the token', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'verificationToken': 'tok'}),
      );

      final response = await source.verifyCode(request);

      expect(response.verificationToken, 'tok');
      final sent = adapter.requests.single;
      expect(sent.path, AuthEndpoints.signUpVerify);
      expect(sent.data, {'email': 'a@b.co', 'code': '123456'});
      expect(sent.extra[RequestExtras.skipAuth], isTrue);
    });

    test('surfaces wrong and expired codes with their code', () async {
      for (final code in [
        'invalid_code',
        'code_expired',
        'too_many_attempts',
      ]) {
        final source = build(
          (_) => FakeHttpAdapter.json(
            {'code': code},
            status: code == 'too_many_attempts' ? 429 : 422,
          ),
        );

        await expectLater(
          source.verifyCode(request),
          throwsA(isA<ServerException>().having((e) => e.code, 'code', code)),
        );
      }
    });

    test('rejects an empty body', () async {
      final source = build((_) => ResponseBody.fromString('', 200));

      await expectLater(
        source.verifyCode(request),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'empty_response',
          ),
        ),
      );
    });

    test('rejects a body that does not match the contract', () async {
      final source = build((_) => FakeHttpAdapter.json({'unexpected': 1}));

      await expectLater(
        source.verifyCode(request),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    });
  });

  group('isUsernameAvailable', () {
    test('sends the username as a query parameter', () async {
      final source = build((_) => FakeHttpAdapter.json({'available': true}));

      final response = await source.isUsernameAvailable('ana');

      expect(response.available, isTrue);
      final sent = adapter.requests.single;
      expect(sent.method, 'GET');
      expect(sent.path, AuthEndpoints.usernameAvailable);
      expect(sent.queryParameters, {'username': 'ana'});
      expect(sent.extra[RequestExtras.skipAuth], isTrue);
    });

    test('parses a taken username', () async {
      final source = build((_) => FakeHttpAdapter.json({'available': false}));

      expect((await source.isUsernameAvailable('demo')).available, isFalse);
    });

    test('rejects a malformed body', () async {
      final source = build((_) => FakeHttpAdapter.json({'available': 'yes'}));

      await expectLater(
        source.isUsernameAvailable('ana'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'invalid_response',
          ),
        ),
      );
    });

    test('maps validation errors', () async {
      final source = build(
        (_) => FakeHttpAdapter.json({'code': 'validation_error'}, status: 422),
      );

      await expectLater(
        source.isUsernameAvailable('x'),
        throwsA(
          isA<ServerException>().having(
            (e) => e.code,
            'code',
            'validation_error',
          ),
        ),
      );
    });
  });
}
