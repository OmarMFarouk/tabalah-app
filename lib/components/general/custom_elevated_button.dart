import 'package:flutter/material.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// The app's primary button.
///
/// Gains three things over the original: a built-in busy state (so callers
/// stop hand-rolling "text: loading ? ... : ..."), an optional gold gradient
/// fill for the hero call to action, and colours that follow the theme
/// instead of being frozen to the light palette.
class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? bgColor;
  final TextStyle? textStyle;
  final Color? borderColor;
  final bool icon;
  final Widget? iconImage;
  final MainAxisAlignment mainAxisAlign;

  /// Shows a spinner and blocks taps.
  final bool isBusy;

  /// Fills with the club's gold gradient. Reserved for the single most
  /// important action on a screen - subscribe, pay, check in.
  final bool gold;

  final double height;

  const CustomElevatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.iconImage,
    this.icon = false,
    this.borderColor,
    this.textStyle,
    this.bgColor,
    this.mainAxisAlign = MainAxisAlignment.center,
    this.isBusy = false,
    this.gold = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isBusy;

    final label = isBusy
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation(
                gold ? AppColors.clubGreenDeep : AppColors.whitecolor,
              ),
            ),
          )
        : (icon
            ? Row(
                mainAxisAlignment: mainAxisAlign,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (iconImage != null) iconImage!,
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      text,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle ?? _defaultStyle,
                    ),
                  ),
                ],
              )
            : Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: textStyle ?? _defaultStyle,
              ));

    if (gold) {
      return SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? AppColors.goldGradient
                  : [AppColors.borderColor, AppColors.borderColor],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ElevatedButton(
            onPressed: enabled ? onPressed : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: label,
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor ?? AppColors.primarycolor,
          disabledBackgroundColor: AppColors.borderColor,
          disabledForegroundColor: AppColors.greycolor,
          elevation: 0,
          side: BorderSide(color: borderColor ?? bgColor ?? AppColors.primarycolor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: label,
      ),
    );
  }

  TextStyle get _defaultStyle =>
      gold ? AppStyles.bold16Black.copyWith(color: AppColors.clubGreenDeep) : AppStyles.medium16White;
}
