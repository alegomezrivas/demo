import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for authentication and session persistence.
abstract interface class AuthRepository {
  /// Signs in and stores the session on success.
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  });

  /// Creates an account, signs in and stores the session on success.
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  });

  /// Ends the session and wipes local session data.
  Future<Either<Failure, Unit>> logout();

  /// Returns the stored user, or null when there is no session.
  Future<Either<Failure, User?>> restoreSession();
}
