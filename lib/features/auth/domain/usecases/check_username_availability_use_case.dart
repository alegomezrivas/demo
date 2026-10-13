import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/repositories/sign_up_repository.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:fpdart/fpdart.dart';

/// Asks whether a username is free; malformed ones never reach the server.
class CheckUsernameAvailabilityUseCase implements UseCase<bool, String> {
  /// Creates the use case.
  const CheckUsernameAvailabilityUseCase(this._repository);

  final SignUpRepository _repository;

  @override
  Future<Either<Failure, bool>> call(String username) async {
    if (!AuthRules.isValidUsername(username.trim())) {
      return left(const ValidationFailure('invalid_username'));
    }
    return _repository.isUsernameAvailable(username);
  }
}
