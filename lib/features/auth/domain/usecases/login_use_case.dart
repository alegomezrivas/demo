import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Input of [LoginUseCase].
class LoginParams {
  /// Creates the parameters.
  const LoginParams({required this.email, required this.password});

  /// E-mail address.
  final String email;

  /// Plain password (never logged or stored).
  final String password;
}

/// Signs a user in.
class LoginUseCase implements UseCase<User, LoginParams> {
  /// Creates the use case.
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(LoginParams params) async {
    if (params.email.trim().isEmpty || params.password.isEmpty) {
      return left(const ValidationFailure('empty_credentials'));
    }
    return _repository.login(
      email: params.email,
      password: params.password,
    );
  }
}
