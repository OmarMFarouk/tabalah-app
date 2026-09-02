import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io' show HttpHeaders;

import 'package:dio/dio.dart';

import 'package:tabala/src/app_scope.dart';
import 'package:tabala/src/sec_prefs/app_sec_prefs.dart';
import 'api_config.dart';
import 'api_exception.dart';

/// Every backend response follows `{ success, message, ...data }` (see the
/// Laravel `Controller::success()/error()` helpers). This client unwraps that
/// envelope and throws a single [ApiException] on any failure, so cubits
/// never touch Dio directly.
class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiBaseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          // Without this Laravel treats the call as a browser request:
          // validation failures come back as a 302 redirect to a login page
          // instead of a 422 with JSON, and `expectsJson()` is false so even
          // the exception handler renders an HTML error page.
          'X-Requested-With': 'XMLHttpRequest',
        },

        // Take every response, including 4xx and 5xx, rather than letting
        // Dio throw before the body is read. The API puts its real error
        // message in the body of those responses, and this is what makes it
        // reachable.
        validateStatus: (_) => true,

        // Ask for the raw string and decode it here.
        //
        // Dio only JSON-decodes when the response carries a JSON
        // content-type. Shared hosting (cPanel/LiteSpeed) frequently returns
        // `text/html` on its own error pages, and some PHP handlers omit the
        // header entirely - in which case Dio hands back a String, the
        // `body is Map` check below fails, and the caller gets a null-cast
        // crash or a meaningless message. Decoding manually removes that
        // dependency on a header the app doesn't control.
        responseType: ResponseType.plain,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AppSecPrefs.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
          }

          // Content an admin typed - sport and membership names, payment
          // methods - is stored per language server-side, so the server
          // needs to know which one to render. Sent on every request rather
          // than per call site: any endpoint can carry catalogue text, and
          // one that quietly didn't would show Arabic inside an English
          // screen, which is the bug this whole header exists to fix.
          options.headers['X-App-Locale'] = AppScope.locale;

          handler.next(options);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._internal();

  late final Dio _dio;

  /// Set once from the app root so a 401 anywhere can drop the user back to
  /// the login screen and clear their stored session.
  void Function()? onUnauthorized;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _send('GET', path, () => _dio.get(path, queryParameters: query));

  Future<Map<String, dynamic>> post(String path, {Object? data}) =>
      _send('POST', path, () => _dio.post(path, data: data));

  Future<Map<String, dynamic>> put(String path, {Object? data}) =>
      _send('PUT', path, () => _dio.put(path, data: data));

  Future<Map<String, dynamic>> patch(String path, {Object? data}) =>
      _send('PATCH', path, () => _dio.patch(path, data: data));

  Future<Map<String, dynamic>> delete(String path) =>
      _send('DELETE', path, () => _dio.delete(path));

  /// Multipart upload of one file under [field].
  ///
  /// Goes through the same [_send] as everything else, so a LiteSpeed error
  /// page or an expired token is handled here exactly as it is on a JSON
  /// call — the only difference is the body Dio builds.
  Future<Map<String, dynamic>> upload(
    String path, {
    required String filePath,
    String field = 'avatar',
  }) async {
    final form = FormData.fromMap({
      field: await MultipartFile.fromFile(filePath),
    });

    return _send('POST', path, () => _dio.post(path, data: form));
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Future<Response> Function() request,
  ) async {
    final target = '$method ${ApiConfig.apiBaseUrl}$path';

    Response response;
    try {
      response = await request();
    } on DioException catch (e) {
      throw _transportError(e, target);
    }

    final status = response.statusCode ?? 0;
    final raw = response.data?.toString() ?? '';

    _log('$target -> $status');
    _log(raw.length > 600 ? '${raw.substring(0, 600)}…' : raw);

    final decoded = _decode(raw);

    // Not JSON at all. Almost always a base-URL or server-config problem
    // rather than an API error, so say which.
    if (decoded == null) {
      throw ApiException(
        _nonJsonMessage(status, raw),
        statusCode: status,
        diagnostic:
            '$target returned non-JSON (${raw.length} bytes): '
            '${_snippet(raw)}',
      );
    }

    if (status == 401) onUnauthorized?.call();

    if (status < 200 || status >= 300) {
      final message = decoded['message'];
      throw ApiException(
        message is String && message.isNotEmpty
            ? message
            : 'Request failed ($status).',
        statusCode: status,
        diagnostic: '$target -> $status',
      );
    }

    return decoded;
  }

  /// Decodes a JSON object, or null if the body isn't one.
  ///
  /// Also tolerates a leading BOM or stray whitespace/output before the
  /// payload, which is what a stray `echo` or a warning printed by a PHP
  /// extension looks like on the wire.
  Map<String, dynamic>? _decode(String raw) {
    final trimmed = raw.replaceFirst('\uFEFF', '').trim();
    if (trimmed.isEmpty) return null;

    final start = trimmed.indexOf('{');
    if (start < 0) return null;

    try {
      final value = jsonDecode(trimmed.substring(start));
      return value is Map<String, dynamic> ? value : null;
    } on FormatException {
      return null;
    }
  }

  String _nonJsonMessage(int status, String raw) {
    final looksLikeHtml = raw.trimLeft().toLowerCase().startsWith('<');

    if (status == 404) {
      return 'The API endpoint was not found. Check the base URL '
          '(${ApiConfig.apiBaseUrl}).';
    }
    if (status == 419) {
      return 'The server rejected the request as unverified (419).';
    }
    if (status >= 500) {
      return 'The server hit an error ($status). Check the Laravel log.';
    }
    if (looksLikeHtml) {
      return 'The server returned a web page instead of API data. '
          'The base URL is probably pointing at the wrong place.';
    }
    return 'The server sent a response the app could not read ($status).';
  }

  /// Transport-level failures: nothing usable came back at all.
  ApiException _transportError(DioException e, String target) {
    String message;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'The server took too long to respond. Please try again.';
        break;

      case DioExceptionType.badCertificate:
        // Worth its own message: this is the classic "works in Postman,
        // fails on the phone". Desktop clients fetch a missing intermediate
        // certificate on the fly; Android does not, so a chain that is
        // incomplete on the server passes on a laptop and fails on a device.
        message =
            'The server\'s security certificate could not be verified. '
            'The certificate chain on the host is likely incomplete.';
        break;

      case DioExceptionType.connectionError:
        message = 'Could not reach the server. Check your connection.';
        break;

      case DioExceptionType.cancel:
        message = 'The request was cancelled.';
        break;

      default:
        message = 'Could not complete the request.';
    }

    _log('$target FAILED: ${e.type} ${e.message ?? ''} ${e.error ?? ''}');

    return ApiException(
      message,
      statusCode: e.response?.statusCode,
      diagnostic: '$target failed with ${e.type}: ${e.error ?? e.message}',
    );
  }

  String _snippet(String raw) {
    final flat = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    return flat.length <= 180 ? flat : '${flat.substring(0, 180)}…';
  }

  void _log(String line) {
    if (ApiConfig.verboseLogging) dev.log(line, name: 'API');
  }
}
