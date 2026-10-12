import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/dio_client_factory.dart';
import 'package:demo/core/network/mock/mock_api_interceptor.dart';
import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/certificate_pinner.dart';
import 'package:demo/core/security/security_policy.dart';
import 'package:demo/core/utils/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_token_storage.dart';

class FakeCertificate implements X509Certificate {
  FakeCertificate(List<int> der) : der = Uint8List.fromList(der);

  @override
  final Uint8List der;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AppConfig config({
  bool mock = true,
  bool pinning = false,
  List<String> pins = const [],
  String baseUrl = 'https://api.test',
}) {
  return AppConfig(
    environment: AppEnvironment.dev,
    apiBaseUrl: baseUrl,
    useMockApi: mock,
    pinningEnabled: pinning,
    pinnedSha256: pins,
    rootPolicy: SecurityPolicy.warn,
  );
}

DioClientFactory factory(
  AppConfig appConfig, {
  InMemoryTokenStorage? storage,
  SessionExpiredNotifier? session,
  bool isRelease = false,
  FakeHttpAdapter? adapter,
}) {
  return DioClientFactory(
    config: appConfig,
    tokenStorage: storage ?? InMemoryTokenStorage(),
    sessionNotifier: session ?? SessionExpiredNotifier(),
    logger: ConsoleAppLogger(minLevel: LogLevel.none),
    isRelease: isRelease,
    adapterBuilder: adapter == null ? null : () => adapter,
    mockSettings: const MockApiSettings(latency: Duration.zero),
    mockRoutes: [
      MockRoute(
        method: 'GET',
        pattern: '/ping',
        handler: (r) =>
            MockResponse(data: {'auth': r.headers['Authorization']}),
      ),
      MockRoute(
        method: 'POST',
        pattern: NetworkConstants.refreshPath,
        handler: (_) => const MockResponse(
          data: {'accessToken': 'fresh', 'refreshToken': 'fresh-refresh'},
        ),
      ),
    ],
  );
}

void main() {
  group('DioClientFactory mock gating', () {
    test('attaches the mock only when enabled outside release builds', () {
      expect(factory(config()).usesMock, isTrue);
      expect(factory(config(mock: false)).usesMock, isFalse);
      expect(factory(config(), isRelease: true).usesMock, isFalse);
    });

    test('never uses the mock in release even if the flag is set', () async {
      final adapter = FakeHttpAdapter(
        (_) => FakeHttpAdapter.json({'real': true}),
      );
      final dio = factory(config(), isRelease: true, adapter: adapter).create();

      final response = await dio.get<dynamic>('/ping');

      expect(response.data, {'real': true});
      expect(adapter.requests, hasLength(1));
    });

    test(
      'serves requests from the mock without touching the network',
      () async {
        final adapter = FakeHttpAdapter(
          (_) => FakeHttpAdapter.json({'real': true}),
        );
        final dio = factory(config(), adapter: adapter).create();

        final response = await dio.get<dynamic>('/ping');

        expect(response.data, {'auth': null});
        expect(adapter.requests, isEmpty);
      },
    );
  });

  group('DioClientFactory configuration', () {
    test('applies base URL and timeouts from config', () {
      final dio = factory(config(baseUrl: 'https://example.org/api')).create();

      expect(dio.options.baseUrl, 'https://example.org/api');
      expect(dio.options.connectTimeout, NetworkConstants.connectTimeout);
      expect(dio.options.receiveTimeout, NetworkConstants.receiveTimeout);
    });

    test('rejects cleartext base URLs', () async {
      final dio = factory(config(baseUrl: 'http://api.test')).create();

      await expectLater(
        dio.get<dynamic>('/ping'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<NetworkException>(),
          ),
        ),
      );
    });

    test('sends the stored bearer token', () async {
      final storage = InMemoryTokenStorage(
        const AuthTokens(accessToken: 'abc', refreshToken: 'r'),
      );
      final dio = factory(config(), storage: storage).create();

      final response = await dio.get<dynamic>('/ping');

      expect(response.data, {'auth': 'Bearer abc'});
    });
  });

  group('DioClientFactory token refresh through the mock backend', () {
    test('refreshes on a mocked 401 and retries with the new token', () async {
      final storage = InMemoryTokenStorage(
        const AuthTokens(accessToken: 'stale', refreshToken: 'r'),
      );
      final dio = factory(config(), storage: storage).create();

      final response = await dio.get<dynamic>(
        '/ping',
        options: Options(
          headers: {NetworkConstants.mockScenarioHeader: 'unauthorized_once'},
        ),
      );

      expect(response.data, {'auth': 'Bearer fresh'});
      expect(storage.tokens?.refreshToken, 'fresh-refresh');
    });

    test('signs out when the mock keeps answering 401', () async {
      final storage = InMemoryTokenStorage(
        const AuthTokens(accessToken: 'stale', refreshToken: 'r'),
      );
      final session = SessionExpiredNotifier();
      final expired = expectLater(session.onExpired, emits(isNull));
      final dio = factory(
        config(),
        storage: storage,
        session: session,
      ).create();

      await expectLater(
        dio.get<dynamic>(
          '/ping',
          options: Options(
            headers: {NetworkConstants.mockScenarioHeader: 'unauthorized'},
          ),
        ),
        throwsA(isA<DioException>()),
      );

      await expired;
      expect(storage.tokens, isNull);
      await session.dispose();
    });
  });

  group('DioClientFactory certificate pinning', () {
    ValidateCertificate? validatorFor(AppConfig appConfig) {
      final adapter =
          factory(appConfig).buildPinnedAdapter() as IOHttpClientAdapter;
      return adapter.validateCertificate;
    }

    final der = utf8.encode('server-cert');

    test('does not validate certificates when pinning is disabled', () {
      expect(validatorFor(config()), isNull);
    });

    test('accepts the pinned certificate and rejects others', () {
      final validate = validatorFor(
        config(pinning: true, pins: [CertificatePinner.fingerprint(der)]),
      );

      expect(validate?.call(FakeCertificate(der), 'api.test', 443), isTrue);
      expect(
        validate?.call(FakeCertificate(utf8.encode('evil')), 'api.test', 443),
        isFalse,
      );
      expect(validate?.call(null, 'api.test', 443), isFalse);
    });

    test('fails closed when pinning is enabled with an empty pin list', () {
      final validate = validatorFor(config(pinning: true));

      expect(validate, isNotNull);
      expect(validate?.call(FakeCertificate(der), 'api.test', 443), isFalse);
    });
  });
}
