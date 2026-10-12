import 'package:demo/core/error/exceptions.dart';
import 'package:demo/core/network/network_constants.dart';
import 'package:demo/core/network/token_refresher.dart';
import 'package:demo/core/security/auth_tokens.dart';
import 'package:dio/dio.dart';

/// [TokenRefresher] that calls the refresh endpoint with a Dio instance
/// **without** the auth interceptor (to avoid refresh loops).
class DioTokenRefresher implements TokenRefresher {
  /// Creates the refresher around a dedicated [_dio].
  const DioTokenRefresher(
    this._dio, {
    this.path = NetworkConstants.refreshPath,
  });

  final Dio _dio;

  /// Refresh endpoint path.
  final String path;

  @override
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {'refreshToken': refreshToken},
      options: Options(extra: {RequestExtras.skipAuth: true}),
    );
    final body = response.data;
    final access = body?['accessToken'];
    final refresh = body?['refreshToken'];
    if (access is! String || refresh is! String) {
      throw const ServerException(code: 'invalid_refresh_response');
    }
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }
}
