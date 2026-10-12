import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Ends the current session.
class LogoutUseCase implements UseCase<Unit, NoParams> {
  /// Creates the use case.
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.logout();
}
