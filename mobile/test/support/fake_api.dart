import 'package:dio/dio.dart';
import 'package:gallery_zone/core/api/api_client.dart';

import 'fake_http.dart';

/// A tiny router over [FakeHttp]: register `'METHOD /path'` handlers, then
/// build an [ApiClient] that talks to them. Every request is recorded, so a
/// test can assert on what was sent as well as on what came back.
class FakeApi {
  final _routes = <String, ResponseBody Function(RequestOptions)>{};
  late final FakeHttp http = FakeHttp(_handle);

  List<RequestOptions> get requests => http.requests;

  /// Answers `route` ("POST /v1/orders") with [body] as JSON.
  void json(String route, Object? body, {int status = 200}) =>
      _routes[route] = (_) => jsonBody(body, status: status);

  /// Answers `route` with whatever [respond] builds from the request.
  void on(String route, ResponseBody Function(RequestOptions options) respond) => _routes[route] = respond;

  /// Fails `route` with an RFC 7807 problem, as the real API does.
  void problem(String route, int status, String code, String title, {String? detail}) =>
      _routes[route] = (_) => jsonBody({
            'type': 'about:blank',
            'title': title,
            'status': status,
            'code': code,
            'detail': ?detail,
          }, status: status);

  ResponseBody _handle(RequestOptions options) {
    final handler = _routes['${options.method} ${options.path}'];
    if (handler == null) {
      throw StateError('Unexpected request: ${options.method} ${options.path}');
    }
    return handler(options);
  }

  /// The client under test. Signed in as default (a fixed token).
  ApiClient client({String? token = 'tok', IdTokenSource? tokenSource, void Function()? onSessionExpired}) =>
      ApiClient(
        baseUrl: 'https://api.test',
        idToken: tokenSource ?? ({bool forceRefresh = false}) async => token,
        onSessionExpired: onSessionExpired,
        dio: http.dio(),
      );

  /// `"POST /v1/orders"` for each request, in order.
  List<String> get calls => [for (final r in requests) '${r.method} ${r.path}'];

  /// The JSON bodies sent to `route`, in order.
  List<Object?> bodiesOf(String route) => [
        for (final r in requests)
          if ('${r.method} ${r.path}' == route) r.data,
      ];

  /// The query parameters of the last request to `route`.
  Map<String, dynamic> queryOf(String route) =>
      requests.lastWhere((r) => '${r.method} ${r.path}' == route).queryParameters;
}
