import 'package:flutter/material.dart';

/// Central place for the app's supported locales, so main.dart and any
/// language-picker UI reference the same list.
class AppLocalization {
  AppLocalization._();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('ar'),
  ];

  static const Locale fallbackLocale = Locale('en');

  static const String translationsPath = 'assets/translation';

  static bool isRtl(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }
}
