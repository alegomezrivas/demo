import 'package:demo/core/error/exceptions.dart';
import 'package:dio/dio.dart';

/// Rejects every request that is not sent over HTTPS.
class HttpsEnforcerInterceptor extends Interceptor {
  /// Creates the interceptor.
  const HttpsEnforcerInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.uri.scheme != 'https') {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          error: const NetworkException('insecure_connection'),
        ),
        true,
      );
      return;
    }
    handler.next(options);
  }
}
