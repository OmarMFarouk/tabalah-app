/// Central place for anything environment-specific.
class ApiConfig {
  ApiConfig._();

  /// Override at build time without editing this file:
  ///
  ///   flutter run --dart-define=API_BASE_URL=https://host/api/v1
  ///
  /// Local development values, for reference:
  /// - Android emulator reaches the host machine via `10.0.2.2`
  /// - iOS simulator / physical device: the machine's LAN IP
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tabalahacademy.com/api/v1',
  );

  /// Generous on purpose. The API is on shared hosting, where the first
  /// request after an idle spell pays for a cold PHP start on top of DNS
  /// and the TLS handshake. Timing out early on a write like registration
  /// is the worst case: the account is created server-side, the app shows
  /// a failure, and the retry is refused for an address the user has just
  /// taken from themselves.
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 45);

  /// Prints method, URL, status and a body snippet for every call.
  ///
  /// Defaults to on in debug and off in release. Turn it on explicitly with
  /// `--dart-define=API_LOGGING=true` when chasing a server-side problem in
  /// a release build.
  static const bool verboseLogging = bool.fromEnvironment(
    'API_LOGGING',
    defaultValue: true,
  );
}
