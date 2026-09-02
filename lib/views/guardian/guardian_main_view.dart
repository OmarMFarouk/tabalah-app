import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/src/app_scope.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/attendance_view.dart';
import 'package:tabala/views/player/payments_view.dart';
import 'package:tabala/views/player/player_home_view.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/views/player/profile_view.dart';

/// The parent's shell: the member's own screens, minus everything that
/// does something.
///
/// The screens themselves are the player's, not copies. A guardian token
/// authenticates as the player it watches and the API mirrors the player's
/// read routes under `/guardian`, so these views already fetch the right
/// data without knowing anything about parents; what each one does know is
/// to hide its action affordances when [AppScope.isGuardian] is set. Copies
/// would have been simpler to write and would have drifted out of step with
/// the member app by the second change to either.
///
/// Four tabs, not five: the sports catalogue is gone. Everything on it leads
/// to a checkout a parent cannot complete, and a screen whose every button
/// is disabled is worse than one that isn't there.
class GuardianMainView extends StatefulWidget {
  GuardianMainView({super.key});

  @override
  State<GuardianMainView> createState() => _GuardianMainViewState();
}

class _GuardianMainViewState extends State<GuardianMainView> {
  int _index = 0;

  /// Built fresh on every build for the same reason the player shell does
  /// it - see the note there on const-canonicalised widgets and themes.
  List<Widget> get _screens => [
    PlayerHomeView(),
    AttendanceView(),
    PaymentsView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: ClubBottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        items: [
          ClubNavItem(
            Icons.home_rounded,
            Icons.home_outlined,
            'guardian_overview'.tr(),
          ),
          ClubNavItem(
            Icons.fact_check_rounded,
            Icons.fact_check_outlined,
            'attendance'.tr(),
          ),
          ClubNavItem(
            Icons.receipt_long_rounded,
            Icons.receipt_long_outlined,
            'wallet'.tr(),
          ),
          ClubNavItem(
            Icons.family_restroom_rounded,
            Icons.family_restroom_outlined,
            'parent_portal'.tr(),
          ),
        ],
      ),
    );
  }
}

/// The standing reminder that this session can only look.
///
/// Shown at the top of every guardian screen rather than once at sign-in:
/// a parent who opens the app a week later has no memory of a one-off
/// dialog, and the difference between "the button is missing" and "the
/// button is missing *because* this is a parent view" is the difference
/// between a clear product and a broken one.
class GuardianBanner extends StatelessWidget {
  const GuardianBanner({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    if (!AppScope.isGuardian) return const SizedBox.shrink();

    final name = AppScope.watchingPlayerName ?? '';

    return Padding(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: .10),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: .30)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.visibility_rounded,
              size: 18,
              color: AppColors.goldInk,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'guardian_banner_title'.tr(),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'guardian_banner_desc'.tr(args: [name]),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
