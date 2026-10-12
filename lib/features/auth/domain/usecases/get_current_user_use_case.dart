import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Returns the signed-in user restored from local storage, or null.
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  /// Creates the use case.
  const GetCurrentUserUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User?>> call(NoParams params) =>
      _repository.restoreSession();
}
