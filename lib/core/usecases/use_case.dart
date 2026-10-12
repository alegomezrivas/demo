import 'package:demo/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Contract of an application use case.
///
/// [Output] is the success value and [Params] the input; use [NoParams] when
/// nothing is needed.
abstract interface class UseCase<Output, Params> {
  /// Runs the use case.
  Future<Either<Failure, Output>> call(Params params);
}

/// Marker for use cases without input.
final class NoParams {
  /// Creates the marker.
  const NoParams();
}
