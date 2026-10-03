import 'package:dio/dio.dart';

import 'api_error.dart';
import 'json_utils.dart';

/// Supplies the Firebase ID token each request carries. [forceRefresh] asks
/// for a fresh one after the API refused the token it was given.
///
/// Returns `null` when nobody is signed in — the request then goes out
/// without a credential, which is exactly right for the public routes.
typedef IdTokenSource = Future<String?> Function({bool forceRefresh});

/// The one HTTP client every `Remote*` repository uses — the Dart twin of
/// `lib/api.ts` on the website.
///
///  * attaches `Authorization: Bearer <Firebase ID token>` when signed in;
///  * turns the API's RFC 7807 error bodies into an [ApiError];
///  * on a 401 it asks once for a freshly refreshed token and retries, and
///    only if that fails too does it report the session as over
///    ([onSessionExpired]) — a stale token is routine (they last an hour),
///    a rejected fresh one is not.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this._idToken,
    this.onSessionExpired,
    Dio? dio,
    Duration timeout = const Duration(seconds: 20),
  }) : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl
      ..connectTimeout = timeout
      ..receiveTimeout = timeout
      ..sendTimeout = timeout
      ..headers['Accept'] = 'application/json';
  }

  final Dio _dio;
  final IdTokenSource _idToken;

  /// Called when a request that *carried a credential* was refused with 401
  /// even after a refresh. The session layer signs the person out.
  final void Function()? onSessionExpired;

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) =>
      _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(String path, {Object? body, bool auth = true}) =>
      _send('POST', path, body: body, auth: auth);

  Future<dynamic> patch(String path, {Object? body, bool auth = true}) =>
      _send('PATCH', path, body: body, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) => _send('DELETE', path, auth: auth);

  /// [get], decoded as one JSON object.
  Future<Map<String, dynamic>> getMap(String path, {Map<String, dynamic>? query, bool auth = true}) async =>
      asMap(await get(path, query: query, auth: auth));

  /// [get], decoded as a list of JSON objects.
  Future<List<Map<String, dynamic>>> getList(String path, {Map<String, dynamic>? query, bool auth = true}) async =>
      asMapList(await get(path, query: query, auth: auth));

  /// Sends raw bytes — the image upload routes take the file itself as the
  /// body, with its content type in the header, not a JSON envelope.
  Future<dynamic> postBytes(
    String path,
    List<int> bytes, {
    required Map<String, String> headers,
    Duration timeout = const Duration(seconds: 120),
  }) =>
      _send('POST', path, body: bytes, headers: headers, timeout: timeout);

  /// PUTs [bytes] to an absolute, pre-signed URL (the artwork image bucket).
  /// No credential is sent: the signature in the URL is the credential, and
  /// our bearer token must never leave for another host.
  Future<void> putToSignedUrl(
    String url,
    List<int> bytes, {
    required Map<String, String> headers,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    await _send('PUT', url, body: bytes, headers: headers, auth: false, timeout: timeout);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    Map<String, String>? headers,
    bool auth = true,
    Duration? timeout,
  }) async {
    var token = auth ? await _idToken() : null;
    for (var attempt = 0;; attempt++) {
      try {
        final response = await _dio.request<dynamic>(
          path,
          data: body,
          queryParameters: query,
          options: Options(
            method: method,
            headers: {
              ...?headers,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            sendTimeout: timeout,
            receiveTimeout: timeout,
          ),
        );
        return response.data;
      } on DioException catch (error) {
        final sentCredential = token != null;
        if (sentCredential && error.response?.statusCode == 401 && attempt == 0) {
          token = await _idToken(forceRefresh: true);
          if (token != null) continue;
        }
        final failure = _toApiError(error);
        if (sentCredential && failure.isUnauthorized) onSessionExpired?.call();
        throw failure;
      }
    }
  }
}

ApiError _toApiError(DioException error) {
  final response = error.response;
  if (response == null) {
    return const ApiError(
      status: 0,
      code: 'network_error',
      message: "Can't reach GalleryZone. Check your connection and try again.",
    );
  }
  final status = response.statusCode ?? 0;
  final data = response.data;
  if (data is Map && data['code'] is String && data['title'] is String) {
    final detail = data['detail'];
    final title = data['title'] as String;
    return ApiError(
      status: status,
      code: data['code'] as String,
      title: title,
      message: detail is String && detail.isNotEmpty ? detail : title,
    );
  }
  if (status == 429) {
    return const ApiError(
      status: 429,
      code: 'rate_limited',
      message: 'Too many requests — wait a moment and try again.',
    );
  }
  return ApiError(status: status, code: 'http_$status', message: 'Something went wrong ($status). Please try again.');
}
