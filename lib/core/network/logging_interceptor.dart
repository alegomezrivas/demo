import 'package:demo/core/utils/logging/app_logger.dart';
import 'package:dio/dio.dart';

/// Logs request outcomes without headers, bodies or query strings.
class LoggingInterceptor extends Interceptor {
  /// Creates the interceptor.
  const LoggingInterceptor(this._logger);

  final AppLogger _logger;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.debug('--> ${options.method} ${options.uri.path}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    _logger.debug(
      '<-- ${response.statusCode} ${options.method} ${options.uri.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    _logger.warning(
      '<-- ${err.response?.statusCode ?? err.type.name} '
      '${options.method} ${options.uri.path}',
    );
    handler.next(err);
  }
}
