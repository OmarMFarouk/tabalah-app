import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';

import 'package:tabala/src/theme/theme_signal.dart';

/// Money formatting for a Saudi club.
///
/// `payments.currency` defaults to `SAR` and the seeder stamps the same, so
/// rows normally carry riyals. [format] treats SAR as the club's currency
/// and only falls back to showing an explicit ISO code when a row says
/// something else - that way a payment taken in another currency is visible
/// rather than silently mislabelled as riyals.
class AppMoney {
  AppMoney._();

  static const String defaultCurrency = 'SAR';

  /// The riyal sign. Arabic UI gets the native `ر.س`; the Latin UI gets
  /// `SAR` so it reads cleanly next to Western digits.
  static String get symbol => ThemeSignal.isArabic ? 'ر.س' : 'SAR';

  static String _formatNumber(num amount) {
    final pattern = amount == amount.roundToDouble() ? '#,##0' : '#,##0.00';
    return NumberFormat(pattern, ThemeSignal.isArabic ? 'ar' : 'en').format(amount);
  }

  /// `1,450 SAR` / `١٬٤٥٠ ر.س`, or the translated "Free" for zero.
  static String format(num? amount, {String? currency, bool showFreeLabel = true}) {
    final value = amount ?? 0;
    if (showFreeLabel && value <= 0) return 'free'.tr();

    final code = (currency ?? defaultCurrency).toUpperCase();
    final label = code == defaultCurrency ? symbol : code;

    return ThemeSignal.isArabic
        ? '${_formatNumber(value)} $label'
        : '${_formatNumber(value)} $label';
  }

  /// Same as [format] but always prints a number, never "Free" - used for
  /// totals and receipts where a literal 0 is meaningful.
  static String amount(num? value, {String? currency}) =>
      format(value, currency: currency, showFreeLabel: false);
}
