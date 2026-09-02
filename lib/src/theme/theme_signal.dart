import 'package:flutter/material.dart';

/// A tiny global mirror of "what brightness / language are we rendering in
/// right now".
///
/// Why this exists: `AppColors` and `AppStyles` are consumed as *static*
/// members from roughly two hundred call sites across the app
/// (`AppStyles.bold16Black`, `AppColors.scaffoldcolor`, ...). Static members
/// have no BuildContext, so on their own they can never answer "am I in dark
/// mode?" - which is exactly what a light/dark theme needs them to answer.
///
/// Rather than thread a context through every one of those call sites, the
/// app root writes the current brightness and language here on every build,
/// and the static getters read it back. Because Flutter rebuilds the whole
/// subtree when the theme or locale changes, and because the getters are
/// evaluated *during* that rebuild, the values are always in step with what
/// MaterialApp is actually rendering.
///
/// This is the same reasoning as reading `Theme.of(context).brightness`
/// instead of watching a cubit: one source of truth, safe to read anywhere.
class ThemeSignal {
  ThemeSignal._();

  static bool _isDark = false;
  static bool _isArabic = false;

  static bool get isDark => _isDark;

  static bool get isArabic => _isArabic;

  /// Called once per frame from the app root, before MaterialApp builds its
  /// descendants.
  static void sync({required Brightness brightness, required Locale locale}) {
    _isDark = brightness == Brightness.dark;
    _isArabic = locale.languageCode == 'ar';
  }

  /// Pick between a light-mode and a dark-mode value.
  static T pick<T>(T light, T dark) => _isDark ? dark : light;
}
