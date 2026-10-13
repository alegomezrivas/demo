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

  /// Hosts that may be reached over plain HTTP in debug builds only.
  ///
  /// `10.0.2.2` is how the Android emulator sees the development machine; the
  /// others serve `adb reverse` and desktop runs. Anything else, and every
  /// profile or release build, is HTTPS only.
  static const Set<String> debugCleartextHosts = {
    '10.0.2.2',
    'localhost',
    '127.0.0.1',
  };
}

/// Keys used in `RequestOptions.extra`.
abstract final class RequestExtras {
  /// Marks requests that must not carry the bearer token (login, refresh).
  static const String skipAuth = 'skip_auth';

  /// Marks a request that was already retried after a token refresh.
  static const String authRetried = 'auth_retried';
}
