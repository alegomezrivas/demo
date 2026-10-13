import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/repositories/sign_up_repository.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:fpdart/fpdart.dart';

/// Input of [VerifyConfirmationCodeUseCase].
class VerifyCodeParams {
  /// Creates the parameters.
  const VerifyCodeParams({required this.email, required this.code});

  /// Address the code was sent to.
  final String email;

  /// The digits typed by the person.
  final String code;
}

/// Confirms the e-mail and yields the verification token for the last step.
class VerifyConfirmationCodeUseCase
    implements UseCase<String, VerifyCodeParams> {
  /// Creates the use case.
  const VerifyConfirmationCodeUseCase(this._repository);

  final SignUpRepository _repository;

  @override
  Future<Either<Failure, String>> call(VerifyCodeParams params) async {
    if (!AuthRules.isValidCode(params.code)) {
      return left(const ValidationFailure('invalid_code'));
    }
    return _repository.verifyConfirmationCode(
      email: params.email,
      code: params.code,
    );
  }
}
