import 'dart:math';

import 'package:demo/core/network/mock/mock_api_interceptor.dart';
import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class FixedRandom implements Random {
  FixedRandom(this.value);

  final double value;

  @override
  double nextDouble() => value;

  @override
  bool nextBool() => throw UnimplementedError();

  @override
  int nextInt(int max) => throw UnimplementedError();
}

void main() {
  late List<Duration> delays;
  late List<MockRequest> seen;

  Dio build({
    MockApiSettings settings = const MockApiSettings(
      latency: Duration(milliseconds: 250),
    ),
    Random? random,
  }) {
    delays = [];
    seen = [];
    return Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..interceptors.add(
        MockApiInterceptor(
          settings: settings,
          random: random,
          delay: (d) async => delays.add(d),
          routes: [
            MockRoute(
              method: 'GET',
              pattern: '/tasks/:id',
              handler: (r) {
                seen.add(r);
                return MockResponse(data: {'id': r.pathParameters['id']});
              },
            ),
            MockRoute(
              method: 'POST',
              pattern: '/tasks',
              handler: (r) => const MockResponse(
                statusCode: 422,
                data: {'code': 'invalid'},
              ),
            ),
          ],
        ),
      );
  }

  Future<Response<dynamic>> get(
    Dio dio, {
    String? scenario,
    Map<String, dynamic>? extra,
  }) {
    return dio.get<dynamic>(
      '/tasks/7',
      queryParameters: {'q': 'x'},
      options: Options(
        headers: {NetworkConstants.mockScenarioHeader: ?scenario},
        extra: extra,
      ),
    );
  }

  TypeMatcher<DioException> status(int code) =>
      isA<DioException>().having((e) => e.response?.statusCode, 'status', code);

  group('MockApiInterceptor routing', () {
    test('serves a matching route with path and query parameters', () async {
      final response = await get(build());

      expect(response.statusCode, 200);
      expect(response.data, {'id': '7'});
      expect(seen.single.queryParameters, {'q': 'x'});
      expect(seen.single.method, 'GET');
    });

    test('answers 404 for unknown routes', () async {
      final dio = build();

      await expectLater(dio.get<dynamic>('/nope'), throwsA(status(404)));
    });

    test(
      'turns handler statuses >= 400 into DioExceptions with the body',
      () async {
        final dio = build();

        await expectLater(
          dio.post<dynamic>('/tasks'),
          throwsA(
            status(422).having(
              (e) => (e.response?.data as Map<String, dynamic>)['code'],
              'code',
              'invalid',
            ),
          ),
        );
      },
    );

    test('applies the configured latency to every request', () async {
      final dio = build();

      await get(dio);
      await get(dio);

      expect(delays, [
        const Duration(milliseconds: 250),
        const Duration(milliseconds: 250),
      ]);
    });
  });

  group('MockApiInterceptor scenarios', () {
    test('server_error answers 500', () async {
      await expectLater(
        get(build(), scenario: 'server_error'),
        throwsA(status(500)),
      );
    });

    test('offline fails as a connection error without a response', () async {
      await expectLater(
        get(build(), scenario: 'offline'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.connectionError)
              .having((e) => e.response, 'response', isNull),
        ),
      );
    });

    test('unauthorized always answers 401', () async {
      await expectLater(
        get(build(), scenario: 'unauthorized'),
        throwsA(status(401)),
      );
      await expectLater(
        get(
          build(),
          scenario: 'unauthorized',
          extra: {RequestExtras.authRetried: true},
        ),
        throwsA(status(401)),
      );
    });

    test(
      'unauthorized_once answers 401 first and succeeds on the retry',
      () async {
        final dio = build();

        await expectLater(
          get(dio, scenario: 'unauthorized_once'),
          throwsA(status(401)),
        );
        final retried = await get(
          dio,
          scenario: 'unauthorized_once',
          extra: {RequestExtras.authRetried: true},
        );

        expect(retried.statusCode, 200);
      },
    );

    test('an unknown scenario header is ignored', () async {
      expect((await get(build(), scenario: 'weird')).statusCode, 200);
    });
  });

  group('MockApiInterceptor random failures', () {
    test('fails when the dice roll is below the failure rate', () async {
      final dio = build(
        settings: const MockApiSettings(
          latency: Duration.zero,
          failureRate: 0.5,
        ),
        random: FixedRandom(0.1),
      );

      await expectLater(get(dio), throwsA(status(500)));
    });

    test('succeeds when the dice roll is above the failure rate', () async {
      final dio = build(
        settings: const MockApiSettings(
          latency: Duration.zero,
          failureRate: 0.5,
        ),
        random: FixedRandom(0.9),
      );

      expect((await get(dio)).statusCode, 200);
    });

    test('a forced scenario wins over the random roll', () async {
      final dio = build(
        settings: const MockApiSettings(latency: Duration.zero, failureRate: 1),
        random: FixedRandom(0),
      );

      await expectLater(
        get(dio, scenario: 'offline'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
