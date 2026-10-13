import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for the multi-step account creation.
abstract interface class SignUpRepository {
  /// Sends a confirmation code to [email].
  Future<Either<Failure, Unit>> sendConfirmationCode(String email);

  /// Sends the code again; the server throttles it per address.
  Future<Either<Failure, Unit>> resendConfirmationCode(String email);

  /// Checks [code] and returns the single-use verification token.
  Future<Either<Failure, String>> verifyConfirmationCode({
    required String email,
    required String code,
  });

  /// Tells whether [username] is still free.
  Future<Either<Failure, bool>> isUsernameAvailable(String username);

  /// Creates the account proven by [verificationToken], signs in and stores
  /// the session (see `AuthRepository.login` for [rememberSession]).
  Future<Either<Failure, User>> completeSignUp({
    required String verificationToken,
    required String name,
    required String username,
    required String password,
    bool rememberSession = true,
  });
}
