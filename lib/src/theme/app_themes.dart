import 'package:flutter/material.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'app_styles.dart';

/// The two Material themes for the app.
///
/// These are built as *methods*, not `static final` fields, for the same
/// reason AppStyles uses getters: they read colour and typography values
/// that depend on the current brightness/locale, and a field would freeze
/// whichever set happened to be current the first time it was touched.
/// AppRoot calls these on every build, which is cheap.
class AppThemes {
  AppThemes._();

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scaffold: const Color(0xFFF4F6F4),
        surface: const Color(0xFFFFFFFF),
        brand: AppColors.clubGreen,
        onBrand: AppColors.whitecolor,
        border: const Color(0xFFDCE4DD),
        ink: const Color(0xFF0A180F),
        subInk: const Color(0xFF4A6150),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scaffold: AppColors.backGround,
        surface: AppColors.surface,
        brand: AppColors.primary,
        // Gold is a light colour, so anything sitting on it needs dark ink.
        onBrand: AppColors.clubGreenDeep,
        border: const Color(0xFF1F402B),
        ink: const Color(0xFFF1F5F2),
        subInk: const Color(0xFF8BA292),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color scaffold,
    required Color surface,
    required Color brand,
    required Color onBrand,
    required Color border,
    required Color ink,
    required Color subInk,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffold,
      primaryColor: brand,
      canvasColor: surface,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: brand,
        onPrimary: onBrand,
        secondary: AppColors.primary,
        onSecondary: AppColors.clubGreenDeep,
        error: isDark ? AppColors.red : const Color(0xFFC0392B),
        onError: Colors.white,
        surface: surface,
        onSurface: ink,
        surfaceContainerHighest: isDark ? AppColors.card : const Color(0xFFEDF1EE),
        outline: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppStyles.bold18Black,
        iconTheme: IconThemeData(color: ink),
      ),
      textTheme: TextTheme(
        bodySmall: AppStyles.regular12Grey,
        bodyMedium: AppStyles.regular14Black,
        bodyLarge: AppStyles.regular16Black,
        titleSmall: AppStyles.medium14Black,
        titleMedium: AppStyles.bold16Black,
        titleLarge: AppStyles.bold20Black,
        labelLarge: AppStyles.medium14Black,
      ),
      iconTheme: IconThemeData(color: subInk),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brand,
          foregroundColor: onBrand,
          disabledBackgroundColor: border,
          disabledForegroundColor: subInk,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: AppStyles.medium16White,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: brand),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.card : const Color(0xFF10241A),
        contentTextStyle: AppStyles.medium14White,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.card : const Color(0xFFEDF1EE),
        side: BorderSide(color: border),
        labelStyle: AppStyles.medium12Black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: AppStyles.regular14Grey,
        labelStyle: AppStyles.regular14Grey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: brand, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? AppColors.red : const Color(0xFFC0392B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: isDark ? AppColors.red : const Color(0xFFC0392B)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: brand,
        circularTrackColor: border,
        linearTrackColor: border,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      fontFamily: AppStyles.fontFamily,
    );
  }
}
