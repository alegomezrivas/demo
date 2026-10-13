import 'package:demo/core/error/exceptions.dart';
import 'package:dio/dio.dart';

/// Rejects every request that is not sent over HTTPS.
///
/// The only exception is [cleartextHosts]: an explicit allow-list of local
/// development hosts that the client factory fills in debug builds. It is
/// empty by default, so profile and release builds stay strictly HTTPS.
class HttpsEnforcerInterceptor extends Interceptor {
  /// Creates the interceptor, optionally allowing HTTP to [cleartextHosts].
  const HttpsEnforcerInterceptor({this.cleartextHosts = const {}});

  /// Hosts (exact match, no wildcards) that may be contacted over plain HTTP.
  final Set<String> cleartextHosts;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_isAllowed(options.uri)) {
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

  bool _isAllowed(Uri uri) {
    if (uri.scheme == 'https') return true;
    return uri.scheme == 'http' && cleartextHosts.contains(uri.host);
  }
}
