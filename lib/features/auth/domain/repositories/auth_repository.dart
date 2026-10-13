import 'package:demo/core/error/failures.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

/// Contract for signing in and out and for session persistence.
abstract interface class AuthRepository {
  /// Signs in and stores the session on success.
  ///
  /// With [rememberSession] false the tokens live in memory only: they are
  /// gone when the app is closed and nothing is written to secure storage.
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    bool rememberSession = true,
  });

  /// Ends the session and wipes local session data (memory and storage).
  Future<Either<Failure, Unit>> logout();

  /// Returns the stored user, or null when there is no persisted session.
  Future<Either<Failure, User?>> restoreSession();
}
