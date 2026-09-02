import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart' show ClubBottomNav, ClubNavItem;
import 'package:tabala/views/trainer/performance_view.dart';
import 'package:tabala/views/trainer/players_view.dart';
import 'package:tabala/views/trainer/profile_view.dart';
import 'package:tabala/views/trainer/sessions_board_view.dart';
import 'package:tabala/views/trainer/trainer_home_view.dart';

/// The trainer's shell. The performance tab is new: `/trainer/kpi-records`
/// and `/trainer/salaries` were both live with no screen behind them, so a
/// trainer had no way to see their own targets or payslips.
class TrainerMainView extends StatefulWidget {
  TrainerMainView({super.key});

  @override
  State<TrainerMainView> createState() => _TrainerMainViewState();
}

class _TrainerMainViewState extends State<TrainerMainView> {
  int _index = 0;

  /// Fresh instances per build, not a `static const` list - see the note in
  /// PlayerMainView. Const-canonicalised children are skipped on rebuild,
  /// which stops a theme switch from reaching the screens below.
  List<Widget> get _screens => [
        TrainerHomeView(),
        SessionsBoardView(),
        PlayersView(),
        TrainerPerformanceView(),
        TrainerProfileView(),
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
          ClubNavItem(Icons.home_rounded, Icons.home_outlined, 'home'.tr()),
          ClubNavItem(Icons.view_kanban_rounded, Icons.view_kanban_outlined, 'sessions'.tr()),
          ClubNavItem(Icons.groups_rounded, Icons.groups_outlined, 'players'.tr()),
          ClubNavItem(Icons.insights_rounded, Icons.insights_outlined, 'performance'.tr()),
          ClubNavItem(Icons.person_rounded, Icons.person_outline_rounded, 'profile'.tr()),
        ],
      ),
    );
  }
}
