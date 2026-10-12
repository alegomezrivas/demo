import 'dart:async';

import 'package:demo/core/network/auth_interceptor.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_token_storage.dart';
import '../../helpers/mocks.dart';

void main() {
  const oldTokens = AuthTokens(accessToken: 'old', refreshToken: 'refresh-old');
  const newTokens = AuthTokens(accessToken: 'new', refreshToken: 'refresh-new');

  late InMemoryTokenStorage storage;
  late MockTokenRefresher refresher;
  late SessionExpiredNotifier session;
  late int expiredCount;
  late FakeHttpAdapter adapter;
  late Dio dio;

  /// Builds a client whose backend accepts only the `new` access token.
  void build({FutureOr<ResponseBody> Function(RequestOptions)? backend}) {
    adapter = FakeHttpAdapter(
      backend ??
          (options) {
            final authorized = options.headers['Authorization'] == 'Bearer new';
            return authorized
                ? FakeHttpAdapter.json({'ok': true})
                : FakeHttpAdapter.json({'code': 'unauthorized'}, status: 401);
          },
    );
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: storage,
        tokenRefresher: refresher,
        retry: dio.fetch,
        sessionNotifier: session,
      ),
    );
  }

  setUp(() {
    storage = InMemoryTokenStorage(oldTokens);
    refresher = MockTokenRefresher();
    session = SessionExpiredNotifier();
    expiredCount = 0;
    session.onExpired.listen((_) => expiredCount++);
    when(refresher.refresh(any)).thenAnswer((_) async => newTokens);
  });

  tearDown(() => session.dispose());

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  group('AuthInterceptor request handling', () {
    test('adds the bearer token when a session exists', () async {
      build(backend: (_) => FakeHttpAdapter.json({}));

      await dio.get<dynamic>('/tasks');

      expect(adapter.requests.single.headers['Authorization'], 'Bearer old');
    });

    test('sends no Authorization header without a session', () async {
      storage.tokens = null;
      build(backend: (_) => FakeHttpAdapter.json({}));

      await dio.get<dynamic>('/tasks');

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('skips the header for requests marked skipAuth', () async {
      build(backend: (_) => FakeHttpAdapter.json({}));

      await dio.post<dynamic>(
        '/auth/login',
        options: Options(extra: {RequestExtras.skipAuth: true}),
      );

      expect(
        adapter.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });
  });

  group('AuthInterceptor 401 handling', () {
    test('refreshes the token and retries the request exactly once', () async {
      build();

      final response = await dio.get<dynamic>('/tasks');

      expect(response.statusCode, 200);
      expect(adapter.requests, hasLength(2));
      expect(adapter.requests.last.headers['Authorization'], 'Bearer new');
      expect(adapter.requests.last.extra[RequestExtras.authRetried], isTrue);
      verify(refresher.refresh('refresh-old')).called(1);
      expect(storage.tokens, newTokens);
      await pump();
      expect(expiredCount, 0);
    });

    test('shares a single refresh between concurrent 401s', () async {
      build();

      final results = await Future.wait([
        dio.get<dynamic>('/a'),
        dio.get<dynamic>('/b'),
        dio.get<dynamic>('/c'),
      ]);

      expect(results.map((r) => r.statusCode), everyElement(200));
      verify(refresher.refresh(any)).called(1);
    });

    test(
      'reuses tokens renewed by another request instead of refreshing again',
      () async {
        var first = true;
        build(
          backend: (options) {
            if (first) {
              first = false;
              // Simulates another request having renewed the session meanwhile.
              storage.tokens = newTokens;
              return FakeHttpAdapter.json({}, status: 401);
            }
            return FakeHttpAdapter.json({'ok': true});
          },
        );

        final response = await dio.get<dynamic>('/tasks');

        expect(response.statusCode, 200);
        verifyNever(refresher.refresh(any));
        expect(adapter.requests.last.headers['Authorization'], 'Bearer new');
      },
    );

    test('signs out when the refresh fails', () async {
      when(refresher.refresh(any))
          .thenThrow(DioException(requestOptions: RequestOptions()));
      build();

      await expectLater(
        dio.get<dynamic>('/tasks'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );
      await pump();

      expect(storage.tokens, isNull);
      expect(expiredCount, 1);
      expect(adapter.requests, hasLength(1));
    });

    test('signs out when there is no stored session to refresh', () async {
      storage.tokens = null;
      build(backend: (_) => FakeHttpAdapter.json({}, status: 401));

      await expectLater(
        dio.get<dynamic>('/tasks'),
        throwsA(isA<DioException>()),
      );
      await pump();

      verifyNever(refresher.refresh(any));
      expect(expiredCount, 1);
    });

    test('does not loop when the retried request is rejected again', () async {
      build(backend: (_) => FakeHttpAdapter.json({}, status: 401));

      await expectLater(
        dio.get<dynamic>('/tasks'),
        throwsA(isA<DioException>()),
      );
      await pump();

      expect(adapter.requests, hasLength(2));
      verify(refresher.refresh(any)).called(1);
      expect(storage.tokens, isNull);
      expect(expiredCount, 1);
    });

    test(
      'ignores 401s of requests marked skipAuth (e.g. wrong password)',
      () async {
        build(backend: (_) => FakeHttpAdapter.json({}, status: 401));

        await expectLater(
          dio.post<dynamic>(
            '/auth/login',
            options: Options(extra: {RequestExtras.skipAuth: true}),
          ),
          throwsA(isA<DioException>()),
        );
        await pump();

        verifyNever(refresher.refresh(any));
        expect(storage.tokens, oldTokens);
        expect(expiredCount, 0);
      },
    );

    test('does not refresh for non-401 errors', () async {
      build(backend: (_) => FakeHttpAdapter.json({}, status: 500));

      await expectLater(
        dio.get<dynamic>('/tasks'),
        throwsA(isA<DioException>()),
      );

      verifyNever(refresher.refresh(any));
      expect(adapter.requests, hasLength(1));
    });

    test(
      'surfaces the retry error when the retried call fails differently',
      () async {
        var calls = 0;
        build(
          backend: (_) => ++calls == 1
              ? FakeHttpAdapter.json({}, status: 401)
              : FakeHttpAdapter.json({'code': 'boom'}, status: 500),
        );

        await expectLater(
          dio.get<dynamic>('/tasks'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status',
              500,
            ),
          ),
        );
        expect(storage.tokens, newTokens);
      },
    );
  });

  test('NetworkConstants exposes sane timeouts', () {
    expect(
      NetworkConstants.connectTimeout,
      lessThan(NetworkConstants.receiveTimeout),
    );
  });
}
