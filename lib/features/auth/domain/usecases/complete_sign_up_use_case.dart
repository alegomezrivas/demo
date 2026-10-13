import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/sign_up_repository.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:fpdart/fpdart.dart';

/// Input of [CompleteSignUpUseCase].
class CompleteSignUpParams {
  /// Creates the parameters.
  const CompleteSignUpParams({
    required this.verificationToken,
    required this.name,
    required this.username,
    required this.password,
    this.rememberSession = true,
  });

  /// Proof of the confirmed e-mail.
  final String verificationToken;

  /// Display name.
  final String name;

  /// Public handle.
  final String username;

  /// Plain password (never logged or stored).
  final String password;

  /// Keep the session across app restarts (otherwise memory only).
  final bool rememberSession;
}

/// Creates the account and signs the new user in.
class CompleteSignUpUseCase implements UseCase<User, CompleteSignUpParams> {
  /// Creates the use case.
  const CompleteSignUpUseCase(this._repository);

  final SignUpRepository _repository;

  @override
  Future<Either<Failure, User>> call(CompleteSignUpParams params) async {
    if (params.verificationToken.isEmpty || params.name.trim().isEmpty) {
      return left(const ValidationFailure('empty_fields'));
    }
    if (!AuthRules.isValidUsername(params.username.trim())) {
      return left(const ValidationFailure('invalid_username'));
    }
    if (AuthRules.passwordProblems(params.password).isNotEmpty) {
      return left(const ValidationFailure('weak_password'));
    }
    return _repository.completeSignUp(
      verificationToken: params.verificationToken,
      name: params.name,
      username: params.username,
      password: params.password,
      rememberSession: params.rememberSession,
    );
  }
}
