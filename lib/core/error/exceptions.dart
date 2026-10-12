/// Base type of every exception thrown by the data layer.
///
/// Exceptions never cross the repository boundary: repositories map them to
/// `Failure`s. The [code] is machine-readable and never shown to the user.
sealed class AppException implements Exception {
  /// Creates an exception identified by [code].
  const AppException(this.code);

  /// Machine-readable identifier of the error.
  final String code;

  @override
  String toString() => 'AppException($code)';
}

/// The backend answered with an unexpected status.
final class ServerException extends AppException {
  /// Creates a server exception, optionally carrying the HTTP [statusCode].
  const ServerException({String code = 'server_error', this.statusCode})
    : super(code);

  /// HTTP status code, when available.
  final int? statusCode;
}

/// The backend could not be reached (offline, timeout, TLS failure).
final class NetworkException extends AppException {
  /// Creates a network exception.
  const NetworkException([super.code = 'network_error']);
}

/// The session is missing, expired or rejected.
final class UnauthorizedException extends AppException {
  /// Creates an unauthorized exception.
  const UnauthorizedException([super.code = 'unauthorized']);
}

/// Local storage failed.
final class CacheException extends AppException {
  /// Creates a cache exception.
  const CacheException([super.code = 'cache_error']);
}

/// Input was rejected by validation.
final class ValidationException extends AppException {
  /// Creates a validation exception.
  const ValidationException([super.code = 'validation_error']);
}
