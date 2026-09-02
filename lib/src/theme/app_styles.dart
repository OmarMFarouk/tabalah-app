import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/theme_signal.dart';

/// Every text style in the app, by weight/size/colour.
///
/// Two things changed here versus the original file, and both were needed to
/// make light/dark + Arabic work without editing ~200 call sites:
///
/// 1. The members are now **getters**, not `static final` fields. A field is
///    evaluated once, the first time it is touched, and then frozen for the
///    life of the isolate - which means a style created while the app was in
///    light mode would keep its black ink forever after the user flipped to
///    dark. A getter is re-evaluated on every build, so it tracks the theme.
///
/// 2. The typeface is chosen per locale. Poppins has no Arabic glyphs, so an
///    Arabic UI rendered in it falls back to whatever the platform picks and
///    looks inconsistent. Tajawal is a proper Arabic/Latin pair, so the
///    Arabic build gets real typography instead of a fallback.
///
/// The "Black"/"White" in the names is kept for source compatibility, but
/// "Black" now means *primary ink for the current theme* (near-black on
/// light, near-white on dark). "White" still means literally white, because
/// those styles sit on top of the green/gold brand surfaces, which stay dark
/// in both themes.
class AppStyles {
  AppStyles._();

  // ── Typeface ───────────────────────────────────────────────────────────

  static TextStyle _font({
    required double size,
    required FontWeight weight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    final builder = ThemeSignal.isArabic
        ? GoogleFonts.tajawal
        : GoogleFonts.poppins;
    return builder(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// The family name the ThemeData should use, so Material's own widgets
  /// (dialogs, menus, tooltips) match the rest of the app.
  static String? get fontFamily => regular14Black.fontFamily;

  // ── Ink shortcuts ──────────────────────────────────────────────────────

  static Color get _ink => AppColors.textcolor;
  static Color get _sub => AppColors.subtextcolor;

  // ── Regular (400) ──────────────────────────────────────────────────────

  static TextStyle get regular12Grey =>
      _font(size: 11, weight: FontWeight.w400, color: _sub);
  static TextStyle get regular12White =>
      _font(size: 12, weight: FontWeight.w400, color: AppColors.whitecolor);

  static TextStyle get regular14White =>
      _font(size: 14, weight: FontWeight.w400, color: AppColors.whitecolor);
  static TextStyle get regular14Black =>
      _font(size: 14, weight: FontWeight.w400, color: _ink);
  static TextStyle get regular14Grey =>
      _font(size: 14, weight: FontWeight.w400, color: _sub);
  static TextStyle get regular14Yellow =>
      _font(size: 14, weight: FontWeight.w400, color: AppColors.yellowcolor);
  static TextStyle get regular14Red =>
      _font(size: 14, weight: FontWeight.w400, color: AppColors.redcolor);
  static TextStyle get regular14Gold =>
      _font(size: 14, weight: FontWeight.w400, color: AppColors.goldInk);

  static TextStyle get regular16White =>
      _font(size: 16, weight: FontWeight.w400, color: AppColors.whitecolor);
  static TextStyle get regular16Black =>
      _font(size: 16, weight: FontWeight.w400, color: _ink);
  static TextStyle get regular16Grey =>
      _font(size: 16, weight: FontWeight.w400, color: _sub);

  static TextStyle get regular20White =>
      _font(size: 20, weight: FontWeight.w400, color: AppColors.whitecolor);

  // ── Medium (600) ───────────────────────────────────────────────────────

  static TextStyle get medium12White =>
      _font(size: 12, weight: FontWeight.w600, color: AppColors.whitecolor);
  static TextStyle get medium12Black =>
      _font(size: 12, weight: FontWeight.w600, color: _ink);
  static TextStyle get medium12Grey =>
      _font(size: 12, weight: FontWeight.w600, color: _sub);

  static TextStyle get medium14White =>
      _font(size: 14, weight: FontWeight.w600, color: AppColors.whitecolor);
  static TextStyle get medium14Black =>
      _font(size: 14, weight: FontWeight.w600, color: _ink);
  static TextStyle get medium14Grey =>
      _font(size: 14, weight: FontWeight.w600, color: _sub);
  static TextStyle get medium14Yellow =>
      _font(size: 14, weight: FontWeight.w600, color: AppColors.yellowcolor);
  static TextStyle get medium14Red =>
      _font(size: 14, weight: FontWeight.w600, color: AppColors.redcolor);
  static TextStyle get medium14Gold =>
      _font(size: 14, weight: FontWeight.w600, color: AppColors.goldInk);
  static TextStyle get medium14Primary =>
      _font(size: 14, weight: FontWeight.w600, color: AppColors.brandInk);

  static TextStyle get medium16White =>
      _font(size: 16, weight: FontWeight.w600, color: AppColors.whitecolor);
  static TextStyle get medium16Black =>
      _font(size: 16, weight: FontWeight.w600, color: _ink);
  static TextStyle get medium16Grey =>
      _font(size: 16, weight: FontWeight.w600, color: _sub);
  static TextStyle get medium16Yellow =>
      _font(size: 16, weight: FontWeight.w600, color: AppColors.yellowcolor);
  static TextStyle get medium16Red =>
      _font(size: 16, weight: FontWeight.w600, color: AppColors.redcolor);
  static TextStyle get medium16Primary =>
      _font(size: 16, weight: FontWeight.w600, color: AppColors.brandInk);

  static TextStyle get medium18White =>
      _font(size: 18, weight: FontWeight.w600, color: AppColors.whitecolor);
  static TextStyle get medium18Black =>
      _font(size: 18, weight: FontWeight.w600, color: _ink);

  static TextStyle get medium20White =>
      _font(size: 20, weight: FontWeight.w600, color: AppColors.whitecolor);
  static TextStyle get medium20Black =>
      _font(size: 20, weight: FontWeight.w600, color: _ink);
  static TextStyle get medium20Primary =>
      _font(size: 20, weight: FontWeight.w600, color: AppColors.brandInk);

  static TextStyle get medium24White =>
      _font(size: 24, weight: FontWeight.w600, color: AppColors.whitecolor);

  // ── Bold (700) ─────────────────────────────────────────────────────────

  /// Gold eyebrow label for use **on the page** - a card, a header, a
  /// scaffold. Routes through [AppColors.goldInk], which deepens the gold in
  /// light mode; the brand value measures 2.10:1 on white and is effectively
  /// invisible there.
  static TextStyle get bold11Gold => _font(
    size: 11,
    weight: FontWeight.bold,
    color: AppColors.goldInk,
    letterSpacing: .6,
  );

  static TextStyle get bold12White =>
      _font(size: 12, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold12Black =>
      _font(size: 12, weight: FontWeight.bold, color: _ink);
  static TextStyle get bold12Grey =>
      _font(size: 12, weight: FontWeight.bold, color: _sub);
  static TextStyle get bold12Gold =>
      _font(size: 12, weight: FontWeight.bold, color: AppColors.goldInk);

  static TextStyle get bold14White =>
      _font(size: 14, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold14Black =>
      _font(size: 14, weight: FontWeight.bold, color: _ink);
  static TextStyle get bold14Grey =>
      _font(size: 14, weight: FontWeight.bold, color: _sub);
  static TextStyle get bold14Yellow =>
      _font(size: 14, weight: FontWeight.bold, color: AppColors.yellowcolor);
  static TextStyle get bold14Red =>
      _font(size: 14, weight: FontWeight.bold, color: AppColors.redcolor);
  static TextStyle get bold14Gold =>
      _font(size: 14, weight: FontWeight.bold, color: AppColors.goldInk);
  static TextStyle get bold14Primary =>
      _font(size: 14, weight: FontWeight.bold, color: AppColors.brandInk);

  static TextStyle get bold16White =>
      _font(size: 16, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold16Black =>
      _font(size: 16, weight: FontWeight.bold, color: _ink);
  static TextStyle get bold16Grey =>
      _font(size: 16, weight: FontWeight.bold, color: _sub);
  static TextStyle get bold16Yellow =>
      _font(size: 16, weight: FontWeight.bold, color: AppColors.yellowcolor);
  static TextStyle get bold16Red =>
      _font(size: 16, weight: FontWeight.bold, color: AppColors.redcolor);
  static TextStyle get bold16Gold =>
      _font(size: 16, weight: FontWeight.bold, color: AppColors.goldInk);
  static TextStyle get bold16Primary =>
      _font(size: 16, weight: FontWeight.bold, color: AppColors.brandInk);

  static TextStyle get bold18White =>
      _font(size: 18, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold18Black =>
      _font(size: 18, weight: FontWeight.bold, color: _ink);
  static TextStyle get bold18Gold =>
      _font(size: 18, weight: FontWeight.bold, color: AppColors.goldInk);

  static TextStyle get bold20White =>
      _font(size: 20, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold20Black =>
      _font(size: 20, weight: FontWeight.bold, color: _ink);
  static TextStyle get bold20Yellow =>
      _font(size: 20, weight: FontWeight.bold, color: AppColors.yellowcolor);
  static TextStyle get bold20Red =>
      _font(size: 20, weight: FontWeight.bold, color: AppColors.redcolor);
  static TextStyle get bold20Gold =>
      _font(size: 20, weight: FontWeight.bold, color: AppColors.goldInk);
  static TextStyle get bold20Primary =>
      _font(size: 20, weight: FontWeight.bold, color: AppColors.brandInk);

  static TextStyle get bold24White =>
      _font(size: 24, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold24Black =>
      _font(size: 24, weight: FontWeight.bold, color: _ink);
  static TextStyle get bold24Gold =>
      _font(size: 24, weight: FontWeight.bold, color: AppColors.goldInk);

  static TextStyle get bold28White =>
      _font(size: 28, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold28Black =>
      _font(size: 28, weight: FontWeight.bold, color: _ink);

  static TextStyle get bold32White =>
      _font(size: 32, weight: FontWeight.bold, color: AppColors.whitecolor);
  static TextStyle get bold32Black =>
      _font(size: 32, weight: FontWeight.bold, color: _ink);
  static TextStyle get bold32Primary =>
      _font(size: 32, weight: FontWeight.bold, color: AppColors.brandInk);
  static TextStyle get bold32Gold =>
      _font(size: 32, weight: FontWeight.bold, color: AppColors.goldInk);
}
