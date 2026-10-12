import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/dio_token_refresher.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  Dio build(FakeHttpAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter;

  group('DioTokenRefresher', () {
    test(
      'posts the refresh token without auth and parses the new pair',
      () async {
        final adapter = FakeHttpAdapter(
          (_) =>
              FakeHttpAdapter.json({'accessToken': 'a2', 'refreshToken': 'r2'}),
        );

        final tokens = await DioTokenRefresher(build(adapter)).refresh('r1');

        expect(tokens, const AuthTokens(accessToken: 'a2', refreshToken: 'r2'));
        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, NetworkConstants.refreshPath);
        expect(request.data, {'refreshToken': 'r1'});
        expect(request.extra[RequestExtras.skipAuth], isTrue);
      },
    );

    test('rejects a malformed response', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json({'accessToken': 'a2'}),
      );

      await expectLater(
        DioTokenRefresher(build(adapter)).refresh('r1'),
        throwsA(isA<ServerException>()),
      );
    });

    test('propagates HTTP failures', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json({'code': 'revoked'}, status: 401),
      );

      await expectLater(
        DioTokenRefresher(build(adapter)).refresh('r1'),
        throwsA(isA<DioException>()),
      );
    });

    test('supports a custom path', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json({'accessToken': 'a', 'refreshToken': 'r'}),
      );

      await DioTokenRefresher(
        build(adapter),
        path: '/v2/refresh',
      ).refresh('r1');

      expect(adapter.requests.single.path, '/v2/refresh');
    });
  });
}
