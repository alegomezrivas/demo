/// Behaviours the mock API can be forced into with a request header.
enum MockScenario {
  /// Serve the registered route normally.
  none,

  /// Answer 500.
  serverError,

  /// Fail as if the device had no connection.
  offline,

  /// Always answer 401.
  unauthorized,

  /// Answer 401 once; the retry after a token refresh succeeds.
  unauthorizedOnce;

  /// Parses a header value (`server_error`, `offline`, ...); unknown -> [none].
  static MockScenario parse(Object? value) {
    return switch (value) {
      'server_error' => MockScenario.serverError,
      'offline' => MockScenario.offline,
      'unauthorized' => MockScenario.unauthorized,
      'unauthorized_once' => MockScenario.unauthorizedOnce,
      _ => MockScenario.none,
    };
  }
}
