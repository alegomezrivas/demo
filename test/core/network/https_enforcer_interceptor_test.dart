import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/https_enforcer_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;

  Dio build(String baseUrl) {
    adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json({'ok': true}));
    return Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter
      ..interceptors.add(const HttpsEnforcerInterceptor());
  }

  group('HttpsEnforcerInterceptor', () {
    test('lets HTTPS requests through', () async {
      final response = await build('https://api.test').get<dynamic>('/ping');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(1));
    });

    test('rejects cleartext HTTP without touching the network', () async {
      final dio = build('http://api.test');

      await expectLater(
        dio.get<dynamic>('/ping'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<NetworkException>().having(
              (e) => e.code,
              'code',
              'insecure_connection',
            ),
          ),
        ),
      );
      expect(adapter.requests, isEmpty);
    });

    test('rejects an absolute HTTP URL even with an HTTPS base URL', () async {
      final dio = build('https://api.test');

      await expectLater(
        dio.get<dynamic>('http://evil.test/ping'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.requests, isEmpty);
    });
  });
}
