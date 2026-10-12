import 'package:flutter/foundation.dart';

/// Domain-level error returned in the left side of `Either<Failure, T>`.
///
/// Failures carry a machine-readable [code]; user-facing text is produced in
/// the presentation layer so it can be localized and kept generic.
@immutable
sealed class Failure {
  /// Creates a failure identified by [code].
  const Failure(this.code);

  /// Machine-readable identifier of the error.
  final String code;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      other is Failure &&
      other.code == code;

  @override
  int get hashCode => Object.hash(runtimeType, code);

  @override
  String toString() => 'Failure($code)';
}

/// The backend answered with an error.
final class ServerFailure extends Failure {
  /// Creates a server failure.
  const ServerFailure([super.code = 'server_error']);
}

/// The backend could not be reached.
final class NetworkFailure extends Failure {
  /// Creates a network failure.
  const NetworkFailure([super.code = 'network_error']);
}

/// The session is missing or expired.
final class UnauthorizedFailure extends Failure {
  /// Creates an unauthorized failure.
  const UnauthorizedFailure([super.code = 'unauthorized']);
}

/// Local storage failed.
final class CacheFailure extends Failure {
  /// Creates a cache failure.
  const CacheFailure([super.code = 'cache_error']);
}

/// Input was rejected by validation.
final class ValidationFailure extends Failure {
  /// Creates a validation failure.
  const ValidationFailure([super.code = 'validation_error']);
}

/// Anything not covered by the other failures.
final class UnexpectedFailure extends Failure {
  /// Creates an unexpected failure.
  const UnexpectedFailure([super.code = 'unexpected']);
}
