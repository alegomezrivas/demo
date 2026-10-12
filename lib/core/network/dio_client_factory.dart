import 'dart:io';

import 'package:demo/core/config/app_config.dart';
import 'package:demo/core/network/auth_interceptor.dart';
import 'package:demo/core/network/dio_token_refresher.dart';
import 'package:demo/core/network/https_enforcer_interceptor.dart';
import 'package:demo/core/network/logging_interceptor.dart';
import 'package:demo/core/network/mock/mock_api_interceptor.dart';
import 'package:demo/core/network/mock/mock_route.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/core/security/certificate_pinner.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:demo/core/utils/logging/app_logger.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Builds the app's configured [Dio] client.
///
/// Interceptor order: HTTPS enforcer -> auth -> logging -> mock. The mock is
/// attached only when the config enables it and the build is not release.
class DioClientFactory {
  /// Creates the factory.
  DioClientFactory({
    required this.config,
    required this.tokenStorage,
    required this.sessionNotifier,
    required this.logger,
    this.mockRoutes = const [],
    this.mockSettings = const MockApiSettings(),
    this.isRelease = kReleaseMode,
    this.adapterBuilder,
  });

  /// Runtime configuration.
  final AppConfig config;

  /// Token persistence used by the auth interceptor.
  final TokenStorage tokenStorage;

  /// Notified when the session cannot be renewed.
  final SessionExpiredNotifier sessionNotifier;

  /// Logger used by the logging interceptor.
  final AppLogger logger;

  /// Endpoints served by the mock backend.
  final List<MockRoute> mockRoutes;

  /// Latency / failure settings of the mock backend.
  final MockApiSettings mockSettings;

  /// Whether this is a release build (the mock is then forbidden).
  final bool isRelease;

  /// Overrides the HTTP adapter (tests).
  final HttpClientAdapter Function()? adapterBuilder;

  /// Whether the mock interceptor will be attached.
  bool get usesMock => config.useMockApi && !isRelease;

  /// Creates the client used by repositories.
  Dio create() {
    final refreshDio = _baseDio()..interceptors.add(LoggingInterceptor(logger));
    if (usesMock) refreshDio.interceptors.add(_mock());

    final dio = _baseDio();
    dio.interceptors
      ..add(
        AuthInterceptor(
          tokenStorage: tokenStorage,
          tokenRefresher: DioTokenRefresher(refreshDio),
          retry: dio.fetch,
          sessionNotifier: sessionNotifier,
        ),
      )
      ..add(LoggingInterceptor(logger));
    if (usesMock) dio.interceptors.add(_mock());
    return dio;
  }

  /// A client with transport security (HTTPS only, pinning) and no auth.
  Dio _baseDio() {
    final dio =
        Dio(
            BaseOptions(
              baseUrl: config.apiBaseUrl,
              connectTimeout: NetworkConstants.connectTimeout,
              receiveTimeout: NetworkConstants.receiveTimeout,
              headers: {Headers.acceptHeader: Headers.jsonContentType},
            ),
          )
          ..httpClientAdapter = adapterBuilder?.call() ?? buildPinnedAdapter()
          ..interceptors.add(const HttpsEnforcerInterceptor());
    return dio;
  }

  MockApiInterceptor _mock() =>
      MockApiInterceptor(routes: mockRoutes, settings: mockSettings);

  /// Adapter that enforces certificate pinning according to the config.
  @visibleForTesting
  HttpClientAdapter buildPinnedAdapter() {
    final pinner = CertificatePinner.fromConfig(config);
    return IOHttpClientAdapter(
      createHttpClient: HttpClient.new,
      validateCertificate: pinner.enabled
          ? (certificate, host, port) => pinner.isTrusted(certificate)
          : null,
    );
  }
}
