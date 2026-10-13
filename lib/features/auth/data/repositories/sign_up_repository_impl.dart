import 'package:demo/core/error/failures.dart';
import 'package:demo/core/error/guarded_call.dart';
import 'package:demo/core/utils/input_sanitizer.dart';
import 'package:demo/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:demo/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:demo/features/auth/data/datasources/sign_up_remote_data_source.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/complete_sign_up_request_dto.dart';
import 'package:demo/features/auth/data/models/email_request_dto.dart';
import 'package:demo/features/auth/data/models/user_dto.dart';
import 'package:demo/features/auth/data/models/verify_code_request_dto.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/sign_up_repository.dart';
import 'package:demo/features/auth/domain/rules/auth_rules.dart';
import 'package:fpdart/fpdart.dart';

/// [SignUpRepository] over the sign-up endpoints and the session store.
///
/// User input is sanitized here, right before it is sent to the backend.
/// Passwords and codes are never modified.
class SignUpRepositoryImpl implements SignUpRepository {
  /// Creates the repository.
  const SignUpRepositoryImpl({
    required SignUpRemoteDataSource signUp,
    required AuthRemoteDataSource auth,
    required AuthLocalDataSource local,
  }) : _signUp = signUp,
       _auth = auth,
       _local = local;

  final SignUpRemoteDataSource _signUp;
  final AuthRemoteDataSource _auth;
  final AuthLocalDataSource _local;

  @override
  Future<Either<Failure, Unit>> sendConfirmationCode(String email) {
    return guardedCall(() async {
      await _signUp.sendCode(
        EmailRequestDto(email: InputSanitizer.email(email)),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, Unit>> resendConfirmationCode(String email) {
    return guardedCall(() async {
      await _signUp.resendCode(
        EmailRequestDto(email: InputSanitizer.email(email)),
      );
      return unit;
    });
  }

  @override
  Future<Either<Failure, String>> verifyConfirmationCode({
    required String email,
    required String code,
  }) {
    return guardedCall(() async {
      final response = await _signUp.verifyCode(
        VerifyCodeRequestDto(email: InputSanitizer.email(email), code: code),
      );
      return response.verificationToken;
    });
  }

  @override
  Future<Either<Failure, bool>> isUsernameAvailable(String username) {
    return guardedCall(() async {
      final response = await _signUp.isUsernameAvailable(_username(username));
      return response.available;
    });
  }

  @override
  Future<Either<Failure, User>> completeSignUp({
    required String verificationToken,
    required String name,
    required String username,
    required String password,
    bool rememberSession = true,
  }) {
    return guardedCall(() async {
      final response = await _auth.register(
        CompleteSignUpRequestDto(
          verificationToken: verificationToken,
          name: InputSanitizer.text(name, maxLength: AuthRules.maxNameLength),
          username: _username(username),
          password: password,
        ),
      );
      return _persist(response, remember: rememberSession);
    });
  }

  String _username(String value) =>
      InputSanitizer.text(value, maxLength: 30).toLowerCase();

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
