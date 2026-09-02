import 'package:flutter/material.dart';

import 'package:tabala/src/prefs/app_prefs.dart';

/// Lets the user switch between light/dark/system theme mode, and remembers
/// the choice across launches.
///
/// The persistence lives in AppPrefs; this class is the reactive half that
/// widgets listen to via Provider. Loading is fire-and-forget from the
/// constructor: the app starts on the last-known mode as soon as the read
/// completes, which is fast enough that it lands before first paint in
/// practice, and falls back to `system` if nothing was stored.
class AppThemeProvider extends ChangeNotifier {
  AppThemeProvider() {
    _restore();
  }

  ThemeMode _mode = ThemeMode.system;
  bool _restored = false;

  ThemeMode get mode => _mode;

  /// True once the stored preference has been read. The splash screen waits
  /// on this so the user never sees a light flash before the dark theme
  /// they picked kicks in.
  bool get isRestored => _restored;

  Future<void> _restore() async {
    final stored = await AppPrefs.savedThemeMode();
    _mode = _parse(stored);
    _restored = true;
    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode newMode) async {
    if (_mode == newMode) return;
    _mode = newMode;
    notifyListeners();
    await AppPrefs.saveThemeMode(_serialize(newMode));
  }

  /// Convenience for a single toggle control. `system` is treated as
  /// "currently light" for the purposes of the first tap.
  Future<void> toggle({required bool isCurrentlyDark}) {
    return changeTheme(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  static ThemeMode _parse(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _serialize(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
