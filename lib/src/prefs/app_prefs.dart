import 'package:shared_preferences/shared_preferences.dart';

/// Small wrapper around SharedPreferences for non-sensitive local state.
/// Anything sensitive (auth token) belongs in AppSecPrefs instead.
class AppPrefs {
  AppPrefs._();

  static const _onboardingSeenKey = 'onboarding_seen';
  static const _localeKey = 'locale_code';
  static const _themeModeKey = 'theme_mode';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  static Future<String?> savedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_localeKey);
  }

  static Future<void> saveLocale(String localeCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, localeCode);
  }

  /// One of 'light' | 'dark' | 'system', or null on a fresh install.
  static Future<String?> savedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeModeKey);
  }

  static Future<void> saveThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode);
  }
}
