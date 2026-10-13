import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/https_enforcer_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  late FakeHttpAdapter adapter;

  Dio build(
    String baseUrl, {
    Set<String> cleartextHosts = const {},
  }) {
    adapter = FakeHttpAdapter((_) => FakeHttpAdapter.json({'ok': true}));
    return Dio(BaseOptions(baseUrl: baseUrl))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        HttpsEnforcerInterceptor(cleartextHosts: cleartextHosts),
      );
  }

  Matcher insecureConnection() => throwsA(
    isA<DioException>().having(
      (e) => e.error,
      'error',
      isA<NetworkException>().having(
        (e) => e.code,
        'code',
        'insecure_connection',
      ),
    ),
  );

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

  group('HttpsEnforcerInterceptor with allowed cleartext hosts', () {
    const hosts = {'10.0.2.2', 'localhost'};

    test('lets HTTP through to an allowed host', () async {
      final dio = build('http://10.0.2.2:5556', cleartextHosts: hosts);

      final response = await dio.get<dynamic>('/ping');

      expect(response.statusCode, 200);
      expect(
        adapter.requests.single.uri.toString(),
        'http://10.0.2.2:5556/ping',
      );
    });

    test('still rejects HTTP to any other host', () async {
      final dio = build('http://api.test', cleartextHosts: hosts);

      await expectLater(dio.get<dynamic>('/ping'), insecureConnection());
      expect(adapter.requests, isEmpty);
    });

    test('rejects an absolute HTTP URL to a host outside the list', () async {
      final dio = build('http://10.0.2.2:5556', cleartextHosts: hosts);

      await expectLater(
        dio.get<dynamic>('http://evil.test/ping'),
        insecureConnection(),
      );
      expect(adapter.requests, isEmpty);
    });

    test('does not match look-alike hosts or subdomains', () async {
      for (final host in [
        'http://10.0.2.20',
        'http://evil.10.0.2.2',
        'http://localhost.evil.test',
        'http://notlocalhost',
      ]) {
        await expectLater(
          build(host, cleartextHosts: hosts).get<dynamic>('/ping'),
          insecureConnection(),
          reason: host,
        );
      }
      expect(adapter.requests, isEmpty);
    });

    test('does not open other schemes on an allowed host', () async {
      final dio = build('ftp://10.0.2.2', cleartextHosts: hosts);

      await expectLater(dio.get<dynamic>('/ping'), insecureConnection());
    });

    test('keeps accepting HTTPS everywhere', () async {
      final dio = build('https://api.test', cleartextHosts: hosts);

      final response = await dio.get<dynamic>('/ping');

      expect(response.statusCode, 200);
    });

    test('rejects HTTP to the emulator host by default', () async {
      final dio = build('http://10.0.2.2:5556');

      await expectLater(dio.get<dynamic>('/ping'), insecureConnection());
      expect(adapter.requests, isEmpty);
    });
  });
}
