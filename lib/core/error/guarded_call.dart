import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failure_mapper.dart';
import 'package:demo/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

/// Runs [action] and turns any exception into a [Failure].
///
/// Repositories use it so exceptions from data sources never escape the data
/// layer; unknown errors become a generic [UnexpectedFailure] whose message
/// never exposes technical details.
Future<Either<Failure, T>> guardedCall<T>(Future<T> Function() action) async {
  try {
    return right(await action());
  } on AppException catch (error) {
    return left(FailureMapper.fromError(error));
  } on Exception catch (error) {
    return left(FailureMapper.fromError(error));
  }
}
