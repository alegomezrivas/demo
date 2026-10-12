import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/dio_exception_mapper.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/features/auth/data/datasources/auth_endpoints.dart';
import 'package:demo/features/auth/data/models/auth_response_dto.dart';
import 'package:demo/features/auth/data/models/login_request_dto.dart';
import 'package:demo/features/auth/data/models/register_request_dto.dart';
import 'package:dio/dio.dart';

/// Remote access to the authentication API; throws [AppException]s only.
abstract interface class AuthRemoteDataSource {
  /// Signs in with credentials.
  Future<AuthResponseDto> login(LoginRequestDto request);

  /// Creates an account.
  Future<AuthResponseDto> register(RegisterRequestDto request);
}

/// [AuthRemoteDataSource] backed by Dio.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// Creates the data source.
  const AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthResponseDto> login(LoginRequestDto request) =>
      _post(AuthEndpoints.login, request.toJson());

  @override
  Future<AuthResponseDto> register(RegisterRequestDto request) =>
      _post(AuthEndpoints.register, request.toJson());

  Future<AuthResponseDto> _post(String path, Map<String, dynamic> body) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        path,
        data: body,
        // Credentials endpoints must not carry (or refresh) a bearer token.
        options: Options(extra: {RequestExtras.skipAuth: true}),
      );
    } on DioException catch (error) {
      throw DioExceptionMapper.map(error);
    }

    final data = response.data;
    if (data == null) throw const ServerException(code: 'empty_response');
    try {
      return AuthResponseDto.fromJson(data);
      // ignore: avoid_catching_errors, generated fromJson throws TypeError on bad data
    } on TypeError {
      // The body did not match the contract; never leak its content.
      throw const ServerException(code: 'invalid_response');
    }
  }
}
