import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/dio_exception_mapper.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/data/models/email_request_dto.dart';
import 'package:demo/features/auth/data/models/username_availability_dto.dart';
import 'package:demo/features/auth/data/models/verification_response_dto.dart';
import 'package:demo/features/auth/data/models/verify_code_request_dto.dart';
import 'package:dio/dio.dart';

/// Remote access to the pre-account sign-up steps; throws [AppException]s only.
abstract interface class SignUpRemoteDataSource {
  /// Asks the server to send a confirmation code.
  Future<void> sendCode(EmailRequestDto request);

  /// Asks the server to send the code again.
  Future<void> resendCode(EmailRequestDto request);

  /// Exchanges e-mail + code for a verification token.
  Future<VerificationResponseDto> verifyCode(VerifyCodeRequestDto request);

  /// Tells whether [username] is free.
  Future<UsernameAvailabilityDto> isUsernameAvailable(String username);
}

/// [SignUpRemoteDataSource] backed by Dio.
class SignUpRemoteDataSourceImpl implements SignUpRemoteDataSource {
  /// Creates the data source.
  const SignUpRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  // Nobody is signed in yet, so none of these requests carries (or refreshes)
  // a bearer token.
  static final Options _anonymous = Options(
    extra: {RequestExtras.skipAuth: true},
  );

  @override
  Future<void> sendCode(EmailRequestDto request) =>
      _send<void>('POST', AuthEndpoints.signUpEmail, request.toJson());

  @override
  Future<void> resendCode(EmailRequestDto request) =>
      _send<void>('POST', AuthEndpoints.signUpResend, request.toJson());

  @override
  Future<VerificationResponseDto> verifyCode(
    VerifyCodeRequestDto request,
  ) async {
    final data = await _send<Map<String, dynamic>>(
      'POST',
      AuthEndpoints.signUpVerify,
      request.toJson(),
    );
    return _parse(data, VerificationResponseDto.fromJson);
  }

  @override
  Future<UsernameAvailabilityDto> isUsernameAvailable(String username) async {
    final data = await _send<Map<String, dynamic>>(
      'GET',
      AuthEndpoints.usernameAvailable,
      null,
      query: {'username': username},
    );
    return _parse(data, UsernameAvailabilityDto.fromJson);
  }

  Future<T?> _send<T>(
    String method,
    String path,
    Map<String, dynamic>? body, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final response = await _dio.request<T>(
        path,
        data: body,
        queryParameters: query,
        options: _anonymous.copyWith(method: method),
      );
      return response.data;
    } on DioException catch (error) {
      throw DioExceptionMapper.map(error);
    }
  }

  R _parse<R>(
    Map<String, dynamic>? data,
    R Function(Map<String, dynamic>) from,
  ) {
    if (data == null) throw const ServerException(code: 'empty_response');
    try {
      return from(data);
      // ignore: avoid_catching_errors, generated fromJson throws TypeError on bad data
    } on TypeError {
      // The body did not match the contract; never leak its content.
      throw const ServerException(code: 'invalid_response');
    }
  }
}
