import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/repositories/sign_up_repository.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:fpdart/fpdart.dart';

/// Input of [SendConfirmationCodeUseCase].
class SendCodeParams {
  /// Creates the parameters.
  const SendCodeParams({required this.email, this.isResend = false});

  /// Address that receives the code.
  final String email;

  /// True when the person asked for the code again.
  final bool isResend;
}

/// Sends (or re-sends) the e-mail confirmation code.
class SendConfirmationCodeUseCase implements UseCase<Unit, SendCodeParams> {
  /// Creates the use case.
  const SendConfirmationCodeUseCase(this._repository);

  final SignUpRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SendCodeParams params) async {
    if (!AuthRules.isValidEmail(params.email.trim())) {
      return left(const ValidationFailure('invalid_email'));
    }
    return params.isResend
        ? _repository.resendConfirmationCode(params.email)
        : _repository.sendConfirmationCode(params.email);
  }
}
