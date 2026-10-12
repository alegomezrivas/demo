import 'package:demo/core/error/failures.dart';
import 'package:demo/core/usecases/use_case.dart';
import 'package:demo/features/auth/domain/entities/user.dart';
import 'package:demo/features/auth/domain/repositories/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

/// Input of [RegisterUseCase].
class RegisterParams {
  /// Creates the parameters.
  const RegisterParams({
    required this.name,
    required this.email,
    required this.password,
    this.phone,
  });

  /// Display name.
  final String name;

  /// E-mail address.
  final String email;

  /// Plain password (never logged or stored).
  final String password;

  /// Optional phone number.
  final String? phone;
}

/// Creates an account and signs the user in.
class RegisterUseCase implements UseCase<User, RegisterParams> {
  /// Creates the use case.
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, User>> call(RegisterParams params) async {
    if (params.name.trim().isEmpty ||
        params.email.trim().isEmpty ||
        params.password.isEmpty) {
      return left(const ValidationFailure('empty_fields'));
    }
    return await _repository.register(
      name: params.name,
      email: params.email,
      password: params.password,
      phone: params.phone,
    );
  }
}
