import 'dart:async';
import 'dart:math';

import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/mock/mock_scenario.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:dio/dio.dart';

/// Tunable behaviour of [MockApiInterceptor].
class MockApiSettings {
  /// Creates settings.
  const MockApiSettings({
    this.latency = const Duration(milliseconds: 400),
    this.failureRate = 0,
  });

  /// Artificial delay applied to every request.
  final Duration latency;

  /// Probability (0..1) of a random 500 when no scenario header is sent.
  final double failureRate;
}

/// Fake backend for development: it answers requests without any network.
///
/// It simulates latency, 500 errors, no connection and 401s (to exercise the
/// token refresh). It is only attached when `USE_MOCK_API` is set and the
/// build is not release.
class MockApiInterceptor extends Interceptor {
  /// Creates the interceptor.
  MockApiInterceptor({
    required List<MockRoute> routes,
    this.settings = const MockApiSettings(),
    Random? random,
    Future<void> Function(Duration duration)? delay,
  }) : _routes = List.unmodifiable(routes),
       _random = random ?? Random(),
       _delay = delay ?? Future<void>.delayed;

  /// Behaviour settings.
  final MockApiSettings settings;

  final List<MockRoute> _routes;
  final Random _random;
  final Future<void> Function(Duration duration) _delay;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    await _delay(settings.latency);

    switch (_scenarioFor(options)) {
      case MockScenario.offline:
        handler.reject(
          DioException.connectionError(
            requestOptions: options,
            reason: 'mock offline',
          ),
          true,
        );
      case MockScenario.serverError:
        handler.reject(_error(options, 500, 'internal_error'), true);
      case MockScenario.unauthorized:
        handler.reject(_error(options, 401, 'unauthorized'), true);
      case MockScenario.unauthorizedOnce:
        if (options.extra[RequestExtras.authRetried] == true) {
          _serve(options, handler);
        } else {
          handler.reject(_error(options, 401, 'unauthorized'), true);
        }
      case MockScenario.none:
        _serve(options, handler);
    }
  }

  MockScenario _scenarioFor(RequestOptions options) {
    final forced = MockScenario.parse(
      options.headers[NetworkConstants.mockScenarioHeader],
    );
    if (forced != MockScenario.none) return forced;
    if (settings.failureRate > 0 &&
        _random.nextDouble() < settings.failureRate) {
      return MockScenario.serverError;
    }
    return MockScenario.none;
  }

  void _serve(RequestOptions options, RequestInterceptorHandler handler) {
    final path = options.uri.path;
    for (final route in _routes) {
      final params = route.match(options.method, path);
      if (params == null) continue;
      final result = route.handler(
        MockRequest(
          method: options.method.toUpperCase(),
          path: path,
          pathParameters: params,
          queryParameters: options.uri.queryParameters,
          headers: options.headers,
          data: options.data,
        ),
      );
      if (result.statusCode >= 400) {
        handler.reject(
          DioException.badResponse(
            statusCode: result.statusCode,
            requestOptions: options,
            response: _response(options, result.statusCode, result.data),
          ),
          true,
        );
      } else {
        handler.resolve(
          _response(options, result.statusCode, result.data),
          true,
        );
      }
      return;
    }
    handler.reject(_error(options, 404, 'not_found'), true);
  }

  DioException _error(RequestOptions options, int status, String code) {
    return DioException.badResponse(
      statusCode: status,
      requestOptions: options,
      response: _response(options, status, {'code': code}),
    );
  }

  Response<dynamic> _response(
    RequestOptions options,
    int status,
    Object? data,
  ) {
    return Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
    );
  }
}
