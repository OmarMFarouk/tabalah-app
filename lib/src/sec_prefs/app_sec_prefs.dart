import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage so the rest of the app never talks to the
/// storage plugin directly - only to this class.
class AppSecPrefs {
  AppSecPrefs._();

  static final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'auth_token';
  static const _roleKey = 'auth_role';
  static const _guardianKey = 'auth_is_guardian';

  /// [isGuardian] marks a parent-portal session.
  ///
  /// It has to be stored, not just held in memory: a guardian token
  /// authenticates as the player it belongs to, so on the next cold start
  /// the API would happily answer `/guardian/me` *and* look like a normal
  /// player session. Without this flag the app would restore a parent
  /// straight into the full member experience, buttons and all.
  static Future<void> saveSession({
    required String token,
    required String role,
    bool isGuardian = false,
  }) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
    await _storage.write(key: _guardianKey, value: isGuardian ? '1' : '0');
  }

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<String?> readRole() => _storage.read(key: _roleKey);

  static Future<bool> readIsGuardian() async =>
      (await _storage.read(key: _guardianKey)) == '1';

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _guardianKey);
  }
}
