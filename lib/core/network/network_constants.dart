/// Network-wide constants.
abstract final class NetworkConstants {
  /// Maximum time to establish a connection.
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Maximum time to receive a response.
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Request header that forces a mock scenario (dev/staging only).
  static const String mockScenarioHeader = 'x-mock-scenario';

  /// Path of the token refresh endpoint.
  static const String refreshPath = '/auth/refresh';
}

/// Keys used in `RequestOptions.extra`.
abstract final class RequestExtras {
  /// Marks requests that must not carry the bearer token (login, refresh).
  static const String skipAuth = 'skip_auth';

  /// Marks a request that was already retried after a token refresh.
  static const String authRetried = 'auth_retried';
}
