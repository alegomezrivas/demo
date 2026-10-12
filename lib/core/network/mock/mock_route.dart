/// Request seen by a mock handler.
class MockRequest {
  /// Creates a request description.
  const MockRequest({
    required this.method,
    required this.path,
    required this.pathParameters,
    required this.queryParameters,
    required this.headers,
    this.data,
  });

  /// HTTP method in upper case.
  final String method;

  /// Request path (no query string).
  final String path;

  /// Values of `:name` segments of the route.
  final Map<String, String> pathParameters;

  /// Query string parameters.
  final Map<String, dynamic> queryParameters;

  /// Request headers.
  final Map<String, dynamic> headers;

  /// Decoded request body.
  final Object? data;
}

/// Response produced by a mock handler.
class MockResponse {
  /// Creates a response.
  const MockResponse({this.statusCode = 200, this.data});

  /// HTTP status code; values >= 400 become `DioException`s.
  final int statusCode;

  /// Response body.
  final Object? data;
}

/// Function that builds the response of a route.
typedef MockHandler = MockResponse Function(MockRequest request);

/// A mocked endpoint: method + path pattern (`/tasks/:id`) + handler.
class MockRoute {
  /// Creates a route.
  MockRoute({
    required String method,
    required this.pattern,
    required this.handler,
  }) : method = method.toUpperCase(),
       _segments = _split(pattern);

  /// HTTP method in upper case.
  final String method;

  /// Path pattern; segments starting with `:` capture a value.
  final String pattern;

  /// Builds the response.
  final MockHandler handler;

  final List<String> _segments;

  /// Returns the captured parameters when the route matches, otherwise null.
  Map<String, String>? match(String requestMethod, String path) {
    if (requestMethod.toUpperCase() != method) return null;
    final segments = _split(path);
    if (segments.length != _segments.length) return null;
    final params = <String, String>{};
    for (var i = 0; i < segments.length; i++) {
      final expected = _segments[i];
      if (expected.startsWith(':')) {
        params[expected.substring(1)] = Uri.decodeComponent(segments[i]);
      } else if (expected != segments[i]) {
        return null;
      }
    }
    return params;
  }

  static List<String> _split(String path) =>
      path.split('/').where((segment) => segment.isNotEmpty).toList();
}
