import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/error/failure_mapper.dart';
import 'package:demo/core/error/failures.dart';
import 'package:demo/core/utils/input_sanitizer.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
import 'package:demo/features/auth/data/models/register_request_dto.dart';
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
  const AuthRepositoryImpl({required this._remote, required this._local});

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final response = await _remote.login(
        LoginRequestDto(email: InputSanitizer.email(email), password: password),
      );
      return await _persist(response);
    });
  }

  @override
  Future<Either<Failure, User>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) {
    return _guard(() async {
      final cleanPhone = phone == null ? null : InputSanitizer.phone(phone);
      final response = await _remote.register(
        RegisterRequestDto(
          name: InputSanitizer.text(name, maxLength: 100),
          email: InputSanitizer.email(email),
          password: password,
          phone: (cleanPhone?.isEmpty ?? true) ? null : cleanPhone,
        ),
      );
      return await _persist(response);
    });
  }

  @override
  Future<Either<Failure, Unit>> logout() {
    return _guard(() async {
      await _local.clear();
      return unit;
    });
  }

  @override
  Future<Either<Failure, User?>> restoreSession() {
    return _guard(() async => (await _local.readUser())?.toEntity());
  }

  Future<User> _persist(AuthResponseDto response) async {
    await _local.saveSession(tokens: response.tokens, user: response.user);
    return response.user.toEntity();
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return right(await action());
    } on AppException catch (error) {
      return left(FailureMapper.fromError(error));
    } on Exception catch (error) {
      return left(FailureMapper.fromError(error));
    }
  }
}
