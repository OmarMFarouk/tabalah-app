import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/theme/app_theme_provider.dart';

/// The top bar shared by the player and trainer home screens: club identity
/// on one side, quick display toggles on the other.
///
/// Sign-out deliberately lives only on the profile tab. A destructive action
/// one mis-tap away from the home screen's scroll area is the wrong trade,
/// and the profile screen is where people look for it anyway.
class HomeHeader extends StatelessWidget {
  final String role;
  final String? name;
  final String? photoUrl;

  const HomeHeader({super.key, required this.role, this.name, this.photoUrl});

  @override
  Widget build(BuildContext context) {
    // Read brightness off the theme rather than the provider: this widget's
    // build is the only place a context.watch would be legal, and the theme
    // already carries the resolved answer including ThemeMode.system.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const ClubLogo(size: 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('club_name'.tr(), style: AppStyles.bold11Gold),
                const SizedBox(height: 2),
                Text(
                  name ?? role.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold18Black,
                ),
              ],
            ),
          ),
          _iconAction(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            onTap: () => context.read<AppThemeProvider>().toggle(isCurrentlyDark: isDark),
          ),
          const SizedBox(width: 8),
          _iconAction(
            label: context.locale.languageCode.toUpperCase(),
            onTap: () => context.setLocale(
              context.locale.languageCode == 'en' ? const Locale('ar') : const Locale('en'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconAction({
    IconData? icon,
    String? label,
    Color? tint,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: icon != null
            ? Icon(icon, size: 18, color: tint ?? AppColors.subtextcolor)
            : Text(label ?? '', style: AppStyles.bold12Black),
      ),
    );
  }
}
