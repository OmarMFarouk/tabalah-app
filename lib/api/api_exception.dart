/// Every failure from ApiClient is normalized into this, so cubits and
/// widgets only ever need to catch one type and read `.message`.
class ApiException implements Exception {
  /// Safe to show a user.
  final String message;

  final int? statusCode;

  /// Detail for the developer: the request that failed, the Dio error type,
  /// and a snippet of whatever the server actually returned. Never shown in
  /// the UI, but printed to the console and worth attaching to a bug report.
  final String? diagnostic;

  const ApiException(this.message, {this.statusCode, this.diagnostic});

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isValidationError => statusCode == 422;
  bool get isNotFound => statusCode == 404;

  /// True when the server replied with something that isn't the API at all -
  /// an HTML error page, a login wall, a redirect target. Usually a routing
  /// or base-URL problem rather than a bug in the app.
  bool get isNotJson =>
      statusCode != null && diagnostic?.contains('non-JSON') == true;

  @override
  String toString() => diagnostic == null ? message : '$message ($diagnostic)';
}
