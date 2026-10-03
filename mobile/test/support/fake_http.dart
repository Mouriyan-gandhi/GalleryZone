import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A scripted stand-in for the network. Records every request and answers it
/// with whatever [handler] returns (or throws), so API code can be tested
/// without a socket.
class FakeHttp implements HttpClientAdapter {
  FakeHttp(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}

  Dio dio() => Dio()..httpClientAdapter = this;
}

ResponseBody jsonBody(Object? body, {int status = 200}) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

/// What a request that never reached the server looks like.
Never offline(RequestOptions options) => throw DioException(
      requestOptions: options,
      type: DioExceptionType.connectionError,
    );
