import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failures.dart';

/// Converts data-layer errors into domain [Failure]s.
abstract final class FailureMapper {
  /// Maps any thrown [error] to a [Failure].
  ///
  /// Unknown error types become [UnexpectedFailure] so no technical detail
  /// leaks upwards.
  static Failure fromError(Object error) {
    return switch (error) {
      ServerException(:final code) => ServerFailure(code),
      NetworkException(:final code) => NetworkFailure(code),
      UnauthorizedException(:final code) => UnauthorizedFailure(code),
      CacheException(:final code) => CacheFailure(code),
      ValidationException(:final code) => ValidationFailure(code),
      _ => const UnexpectedFailure(),
    };
  }
}
