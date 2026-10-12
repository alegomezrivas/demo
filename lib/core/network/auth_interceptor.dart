import 'dart:async';

import 'package:demo/core/network/network_constants.dart';
import 'package:demo/core/network/session_expired_notifier.dart';
import 'package:demo/core/network/token_refresher.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:demo/core/security/token_storage.dart';
import 'package:dio/dio.dart';

/// Re-sends a request (normally `dio.fetch`).
typedef RequestRetrier = Future<Response<dynamic>> Function(
  RequestOptions options,
);

/// Adds the bearer token and renews it once when the server answers 401.
///
/// * Concurrent 401s share a single refresh call.
/// * A request is retried at most once.
/// * If the refresh fails (or the retried request is still rejected) the
///   tokens are cleared and [SessionExpiredNotifier] fires.
class AuthInterceptor extends Interceptor {
  /// Creates the interceptor.
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required TokenRefresher tokenRefresher,
    required this._retry,
    required SessionExpiredNotifier sessionNotifier,
  }) : _storage = tokenStorage,
       _refresher = tokenRefresher,
       _session = sessionNotifier;

  final TokenStorage _storage;
  final TokenRefresher _refresher;
  final RequestRetrier _retry;
  final SessionExpiredNotifier _session;

  Future<AuthTokens?>? _inFlightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[RequestExtras.skipAuth] != true) {
      final tokens = await _storage.read();
      if (tokens != null) {
        options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized || options.extra[RequestExtras.skipAuth] == true) {
      handler.next(err);
      return;
    }

    if (options.extra[RequestExtras.authRetried] == true) {
      // A freshly renewed token was rejected: the session is unusable.
      await _expireSession();
      handler.next(err);
      return;
    }

    final tokens = await _renewTokens(options);
    if (tokens == null) {
      await _expireSession();
      handler.next(err);
      return;
    }

    try {
      handler.resolve(await _retry(_withToken(options, tokens)));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  /// Returns the tokens to retry with, refreshing only when needed.
  Future<AuthTokens?> _renewTokens(RequestOptions failed) async {
    final stored = await _storage.read();
    final usedToken = _bearerOf(failed);
    if (stored != null &&
        usedToken != null &&
        stored.accessToken != usedToken) {
      // Another request already renewed the token; just reuse it.
      return stored;
    }
    return await (_inFlightRefresh ??= _refresh().whenComplete(
      () => _inFlightRefresh = null,
    ));
  }

  Future<AuthTokens?> _refresh() async {
    final stored = await _storage.read();
    if (stored == null) return null;
    try {
      final renewed = await _refresher.refresh(stored.refreshToken);
      await _storage.save(renewed);
      return renewed;
    } on Exception {
      // Any refresh failure (rejected token, network) ends the session.
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _storage.clear();
    _session.notifyExpired();
  }

  RequestOptions _withToken(RequestOptions options, AuthTokens tokens) {
    return options.copyWith(
      headers: {
        ...options.headers,
        'Authorization': 'Bearer ${tokens.accessToken}',
      },
      extra: {...options.extra, RequestExtras.authRetried: true},
    );
  }

  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring('Bearer '.length);
    }
    return null;
  }
}
