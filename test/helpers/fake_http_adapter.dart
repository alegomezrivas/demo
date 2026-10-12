import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Scripted [HttpClientAdapter] that records every request it receives.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.onRequest);

  final FutureOr<ResponseBody> Function(RequestOptions options) onRequest;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return await onRequest(options);
  }

  @override
  void close({bool force = false}) {}

  /// Builds a JSON response body.
  static ResponseBody json(Object body, {int status = 200}) {
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
