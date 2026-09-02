import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/home_header.dart';
import 'package:tabala/components/home/home_carousels.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/trainer_home_cubit.dart';
import 'package:tabala/models/trainer_home_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/cubits/session_detail_cubit.dart';
import 'package:tabala/views/trainer/scan_player_qr_view.dart';
import 'package:tabala/views/trainer/session_detail_view.dart';

/// The trainer's day. A horizontal day strip picks the date, a carousel
/// shows the classes on it, and the roster of the first class is expanded
/// underneath so the common case - "open the app, take the register" - is
/// one tap away.
class TrainerHomeView extends StatefulWidget {
  const TrainerHomeView({super.key});

  @override
  State<TrainerHomeView> createState() => _TrainerHomeViewState();
}

class _TrainerHomeViewState extends State<TrainerHomeView> {
  late final TrainerHomeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = TrainerHomeCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openSession(int sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionDetailView(sessionId: sessionId)),
    );
    if (mounted) _cubit.load(refresh: true);
  }

  /// Take the register straight from the home page.
  ///
  /// The scan endpoint needs a session, but the home page has no single
  /// one in view, so the class is inferred from the clock: whichever of the
  /// day's sessions the API would currently accept attendance for. One
  /// match is used silently, several put a picker up, none is an error the
  /// trainer can act on.
  Future<void> _scanFromHome(TrainerHomeData data) async {
    final open = data.sessions.where((s) => s.isOpenForAttendance).toList();

    if (open.isEmpty) {
      _toast('no_active_session_to_scan'.tr());
      return;
    }

    final session = open.length == 1 ? open.first : await _pickSession(open);
    if (session == null || !mounted) return;

    final cubit = SessionDetailCubit();
    await cubit.load(session.sessionId);
    if (!mounted) {
      await cubit.close();
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScanPlayerQrView(cubit: cubit)),
    );

    await cubit.close();
    if (mounted) _cubit.load(refresh: true);
  }

  Future<TrainerDaySession?> _pickSession(List<TrainerDaySession> sessions) {
    return showModalBottomSheet<TrainerDaySession>(
      context: context,
      backgroundColor: AppColors.surfacecolor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text('which_session'.tr(), style: AppStyles.bold18Black),
            ),
            ...sessions.map(
              (s) => ListTile(
                leading: Icon(Icons.sports_rounded, color: AppColors.goldInk),
                title: Text(s.membershipName, style: AppStyles.medium14Black),
                subtitle: Text(s.timeLabel, style: AppStyles.regular14Grey),
                onTap: () => Navigator.pop(sheetContext, s),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<TrainerHomeCubit, AsyncState<TrainerHomeData>>(
            builder: (context, state) {
              return RefreshIndicator(
                color: AppColors.goldInk,
                backgroundColor: AppColors.surfacecolor,
                onRefresh: () => _cubit.load(refresh: true),
                child: ListView(
                  padding: EdgeInsets.only(
                    bottom: ClubBottomNav.scrollPadding(context),
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    HomeHeader(role: 'coach', name: user?.name, photoUrl: user?.photo),
                    const SizedBox(height: 12),
                    DayStrip(
                      selected: _cubit.selectedDay,
                      onSelect: (day) => _cubit.selectDay(day),
                    ),
                    if (state.isBusy)
                      const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: AsyncStateView(isLoading: true, child: SizedBox()),
                      )
                    else if (state.hasError && !state.hasData)
                      AsyncStateView(
                        isLoading: false,
                        errorMessage: state.error,
                        onRetry: _cubit.load,
                        child: const SizedBox(),
                      )
                    else if (state.hasData)
                      ..._content(state.data!),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _content(TrainerHomeData data) {
    if (data.sessions.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: ClubCard(
            child: EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'no_sessions_today'.tr(),
              message: 'no_sessions_on_day'.tr(
                args: [AppDate.friendlyDate(_cubit.selectedDay)],
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ];
    }

    final first = data.sessions.first;

    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: ClubGradientPanel(
          child: Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'sessions'.tr(),
                  value: '${data.sessions.length}',
                  icon: Icons.sports_rounded,
                  onDark: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'players'.tr(),
                  value: '${data.playerCount}',
                  icon: Icons.groups_rounded,
                  onDark: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'attendance_rate'.tr(),
                  value: '${data.averageAttendanceRate.round()}%',
                  icon: Icons.trending_up_rounded,
                  onDark: true,
                ),
              ),
            ],
          ),
        ),
      ),
      // Taking the register is the job the trainer opens the app to do, so
      // it sits above the fold rather than behind a session tap.
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _scanFromHome(data),
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: Text('scan_player_attendance'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldInk,
              foregroundColor: AppColors.surfacecolor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
      SectionHeader(
        title: 'todays_sessions'.tr(),
        subtitle: AppDate.friendlyDate(data.date),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      ),
      CarouselRail(
        height: 178,
        children: data.sessions
            .map((s) => TrainerSessionCarouselCard(
                  session: s,
                  onTap: () => _openSession(s.sessionId),
                ))
            .toList(),
      ),

      // The first class's roster, inlined. Attendance rates here are the
      // player's rate across this trainer's memberships overall, not for
      // this one session - the backend computes them that way.
      SectionHeader(
        title: first.membershipName,
        subtitle: 'roster_of_next_class'.tr(),
        actionLabel: 'view_all'.tr(),
        onAction: () => _openSession(first.sessionId),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            if (first.players.isEmpty)
              ClubCard(
                child: Text('no_players_enrolled'.tr(), style: AppStyles.regular14Grey),
              )
            else
              ...first.players.take(5).map(
                    (p) => RosterRow(
                      name: p.name,
                      initial: p.initial,
                      subtitle: '${'attendance_rate'.tr()} · ${p.attendanceRate.round()}%',
                      onTap: () => _openSession(first.sessionId),
                    ),
                  ),
            if (first.players.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton(
                  onPressed: () => _openSession(first.sessionId),
                  child: Text(
                    'and_more'.tr(args: ['${first.players.length - 5}']),
                    style: AppStyles.medium14Primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    ];
  }
}
