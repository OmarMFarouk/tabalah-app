import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/home_header.dart';
import 'package:tabala/components/home/home_carousels.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/player_home_cubit.dart';
import 'package:tabala/models/player_home_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/views/guardian/guardian_main_view.dart';
import 'package:tabala/views/player/membership_detail_view.dart';
import 'package:tabala/views/player/my_qr_view.dart';

/// The player's home. Everything on this screen comes from the single
/// `/player/homepage` call, laid out as three horizontal rails - memberships,
/// today's sessions, coaches - above a quick-actions block.
class PlayerHomeView extends StatefulWidget {
  const PlayerHomeView({super.key});

  @override
  State<PlayerHomeView> createState() => _PlayerHomeViewState();
}

class _PlayerHomeViewState extends State<PlayerHomeView> {
  late final PlayerHomeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PlayerHomeCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
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
          child: BlocBuilder<PlayerHomeCubit, AsyncState<PlayerHomeData>>(
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
                    HomeHeader(
                      role: 'player',
                      name: user?.name,
                      photoUrl: user?.photo,
                    ),
                    if (state.isBusy)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: AsyncStateView(
                          isLoading: true,
                          child: SizedBox(),
                        ),
                      )
                    else if (state.hasError && !state.hasData)
                      AsyncStateView(
                        isLoading: false,
                        errorMessage: state.error,
                        onRetry: _cubit.load,
                        child: const SizedBox(),
                      )
                    else if (state.hasData)
                      ..._content(state.data!, user?.name ?? ''),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _content(PlayerHomeData data, String name) {
    return [
      // No-ops for a normal member; see GuardianBanner.
      const GuardianBanner(padding: EdgeInsets.fromLTRB(16, 4, 16, 0)),
      _greeting(name),
      _overviewStrip(data),

      // ── Memberships rail ────────────────────────────────────────────
      SectionHeader(
        title: 'my_memberships'.tr(),
        subtitle: 'membership_rail_hint'.tr(),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
      ),
      if (data.memberships.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClubCard(
            child: EmptyState(
              icon: Icons.card_membership_rounded,
              title: 'no_memberships_yet'.tr(),
              message: 'browse_sports_prompt'.tr(),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        )
      else
        CarouselRail(
          height: 186,
          children: data.memberships
              .map(
                (m) => MembershipCarouselCard(
                  membership: m,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MembershipDetailView(membershipId: m.id),
                    ),
                  ),
                ),
              )
              .toList(),
        ),

      // ── Today's sessions rail ───────────────────────────────────────
      SectionHeader(
        title: 'todays_sessions'.tr(),
        subtitle: AppDate.friendlyDate(DateTime.now()),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      ),
      if (data.todaySessions.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClubCard(
            child: Row(
              children: [
                Icon(
                  Icons.self_improvement_rounded,
                  color: AppColors.greycolor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'no_sessions_today'.tr(),
                    style: AppStyles.regular14Grey,
                  ),
                ),
              ],
            ),
          ),
        )
      else
        CarouselRail(
          height: 152,
          children: data.todaySessions
              .map((s) => SessionCarouselCard(session: s))
              .toList(),
        ),

      // ── Coaches rail ────────────────────────────────────────────────
      if (data.trainers.isNotEmpty) ...[
        SectionHeader(
          title: 'your_trainers'.tr(),
          subtitle: 'trainers_count'.tr(args: ['${data.trainers.length}']),
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        ),
        CarouselRail(
          height: 176,
          children: data.trainers
              .map((t) => TrainerCarouselCard(trainer: t))
              .toList(),
        ),
      ],

    ];
  }

  void _openMyQr() {
    final player = context.read<AuthCubit>().currentUser;
    final token = player?.player?.qrToken;

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('qr_unavailable'.tr())));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MyQrView(qrToken: token, playerName: player?.name ?? ''),
      ),
    );
  }

  /// The greeting, with the member's QR alongside it.
  ///
  /// The code is what a trainer scans to take the register, so it sits at
  /// the top of the screen rather than in a block below the rails. The name
  /// column is [Expanded] and the chip sizes to its own content, so a long
  /// name ellipsizes instead of overflowing the row on a narrow phone.
  ///
  /// Shown to guardians too: a parent holding the phone at the door is the
  /// person who needs to present it. Their token authenticates as the
  /// player, so `player_qr_token` is the child's own code.
  Widget _greeting(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greetingKey().tr(), style: AppStyles.regular14Grey),
                const SizedBox(height: 4),
                Text(
                  name.isEmpty ? 'player'.tr() : name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold24Black,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _qrChip(),
        ],
      ),
    );
  }

  /// Compact entry point to the member's QR. Kept to an icon and a short
  /// label so it survives the widest name the row can hold.
  Widget _qrChip() {
    return ClubCard(
      onTap: _openMyQr,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      border: Border.all(
        color: AppColors.primary.withValues(alpha: .45),
        width: 1.4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.qr_code_2_rounded, size: 26, color: AppColors.goldInk),
          const SizedBox(height: 4),
          Text(
            'my_qr_code'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.medium14Black,
          ),
        ],
      ),
    );
  }

  /// Saudi days start early - training is commonly before Fajr-adjacent
  /// hours or after Maghrib - so the greeting bands are deliberately wider
  /// than a nine-to-five app's would be.
  String _greetingKey() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'good_morning';
    if (hour < 17) return 'good_afternoon';
    return 'good_evening';
  }

  /// The three headline numbers, on the club gradient so the top of the
  /// screen reads as the member's card.
  Widget _overviewStrip(PlayerHomeData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: ClubGradientPanel(
        child: Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'attendance_rate'.tr(),
                value: '${data.overallAttendanceRate.round()}%',
                icon: Icons.trending_up_rounded,
                onDark: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'active_plans'.tr(),
                value: '${data.memberships.length}',
                icon: Icons.card_membership_rounded,
                onDark: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: StatTile(
                label: 'today'.tr(),
                value: '${data.todaySessions.length}',
                icon: Icons.event_available_rounded,
                onDark: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

}
