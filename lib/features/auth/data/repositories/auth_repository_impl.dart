import 'package:demo/core/error/failures.dart';
import 'package:demo/core/error/guarded_call.dart';
import 'package:demo/core/utils/input_sanitizer.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// [AuthRepository] that combines the remote API and local persistence.
///
/// User input is sanitized here, right before it is sent to the backend.
/// Passwords are never modified.
class AuthRepositoryImpl implements AuthRepository {
  /// Creates the repository.
  ///
  /// [serverLogoutTimeout] bounds how long signing out waits for the server.
  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required AuthLocalDataSource local,
    this.serverLogoutTimeout = const Duration(seconds: 5),
  }) : _remote = remote,
       _local = local;

  /// Longest wait for the server to acknowledge a logout.
  final Duration serverLogoutTimeout;

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    bool rememberSession = true,
  }) {
    return guardedCall(() async {
      final response = await _remote.login(
        LoginRequestDto(email: InputSanitizer.email(email), password: password),
      );
      return _persist(response, remember: rememberSession);
    });
  }

  @override
  Future<Either<Failure, Unit>> logout() {
    return guardedCall(() async {
      await _revokeOnServer();
      await _local.clear();
      return unit;
    });
  }

  @override
  Future<Either<Failure, User?>> restoreSession() {
    return guardedCall(() async => (await _local.readUser())?.toEntity());
  }

  /// Tells the server to revoke the session, on a best-effort basis.
  ///
  /// Signing out must always work, even offline, so a failure or a slow server
  /// (bounded by [serverLogoutTimeout], a `TimeoutException`) never blocks it:
  /// the local session is wiped right after. The refresh token then simply
  /// expires on the server.
  Future<void> _revokeOnServer() async {
    try {
      final refreshToken = await _local.readRefreshToken();
      if (refreshToken == null) return;
      await _remote.logout(refreshToken).timeout(serverLogoutTimeout);
    } on Exception {
      // Any failure (offline, 5xx, timeout, unreadable storage) is ignored:
      // the caller still wipes the local session. See above.
    }
  }

  Future<User> _persist(
    AuthResponseDto response, {
    required bool remember,
  }) async {
    await _local.saveSession(
      tokens: response.tokens,
      user: response.user,
      persist: remember,
    );
    return response.user.toEntity();
  }
}
