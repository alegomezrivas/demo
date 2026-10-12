import 'dart:async';

import 'package:demo/core/error/exceptions.dart';
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
/// * If the refresh token is rejected (or the retried request is still
///   rejected) the tokens are cleared and [SessionExpiredNotifier] fires.
/// * Transient failures (offline, timeout, 5xx) keep the session.
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

  Future<_Renewal>? _inFlightRefresh;

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

    switch (await _renewTokens(options)) {
      case _Renewed(:final tokens):
        try {
          handler.resolve(await _retry(_withToken(options, tokens)));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      case _Rejected():
        await _expireSession();
        handler.next(err);
      case _Unavailable():
        // The refresh endpoint could not be reached or failed: the session
        // may still be valid, so keep it and report a connectivity problem.
        handler.next(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            error: const NetworkException('refresh_unavailable'),
          ),
        );
    }
  }

  /// Returns the tokens to retry with, refreshing only when needed.
  Future<_Renewal> _renewTokens(RequestOptions failed) async {
    final stored = await _storage.read();
    final usedToken = _bearerOf(failed);
    if (stored != null &&
        usedToken != null &&
        stored.accessToken != usedToken) {
      // Another request already renewed the token; just reuse it.
      return _Renewed(stored);
    }
    return await (_inFlightRefresh ??= _refresh().whenComplete(
      () => _inFlightRefresh = null,
    ));
  }

  Future<_Renewal> _refresh() async {
    final stored = await _storage.read();
    if (stored == null) return _Rejected();
    try {
      final renewed = await _refresher.refresh(stored.refreshToken);
      await _storage.save(renewed);
      return _Renewed(renewed);
    } on DioException catch (error) {
      // Only an explicit rejection of the refresh token ends the session;
      // timeouts, offline and server errors must not log the user out.
      final status = error.response?.statusCode;
      return status == 401 || status == 403 ? _Rejected() : _Unavailable();
    } on Exception {
      return _Unavailable();
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

/// Outcome of trying to renew the tokens.
sealed class _Renewal;

/// New tokens are available.
final class _Renewed extends _Renewal {
  _Renewed(this.tokens);

  final AuthTokens tokens;
}

/// The server refused the refresh token: the session is over.
final class _Rejected extends _Renewal;

/// The refresh could not be completed (network or server problem).
final class _Unavailable extends _Renewal;
