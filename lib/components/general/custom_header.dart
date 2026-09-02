// `hide TextDirection` is required, not cosmetic. easy_localization
// re-exports package:intl, and intl declares its own `TextDirection` class
// whose members are RTL/LTR - which collides with the dart:ui enum that
// material.dart exports and that `Directionality.of` actually returns.
// Without the hide, `TextDirection.rtl` either fails to resolve or binds to
// the wrong type.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/theme/app_theme_provider.dart';

/// The header on the auth screens: club crest in the middle, language and
/// theme toggles either side, and an optional back affordance.
///
/// The back arrow flips direction with the locale. That is not cosmetic -
/// in an RTL layout "back" points right, and an arrow pointing the wrong
/// way reads as "forward" to an Arabic speaker.
class CustomHeader extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;

  const CustomHeader({super.key, this.showBack = false, this.onBack});

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _pill(
                  onTap: () => context.setLocale(
                    context.locale.languageCode == 'en'
                        ? const Locale('ar')
                        : const Locale('en'),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.locale.languageCode.toUpperCase(),
                        style: AppStyles.bold12Black,
                      ),
                      const SizedBox(width: 5),
                      Icon(Icons.language_rounded,
                          size: 16, color: AppColors.subtextcolor),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _pill(
                  onTap: () => context
                      .read<AppThemeProvider>()
                      .toggle(isCurrentlyDark: isDark),
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 16,
                    color: AppColors.subtextcolor,
                  ),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('club_name'.tr(), style: AppStyles.bold14Gold),
                const SizedBox(height: 2),
                Text('club_info'.tr(), style: AppStyles.regular12Grey),
              ],
            ),
            const ClubLogo(size: 44),
          ],
        ),
        const SizedBox(height: 18),
        if (showBack)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GestureDetector(
              onTap: onBack ?? () => Navigator.pop(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRtl ? Icons.arrow_forward_rounded : Icons.arrow_back_rounded,
                    size: 18,
                    color: AppColors.subtextcolor,
                  ),
                  const SizedBox(width: 6),
                  Text('back'.tr(), style: AppStyles.medium14Grey),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _pill({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: child,
      ),
    );
  }
}
