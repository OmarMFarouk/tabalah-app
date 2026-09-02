import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/trainer_players_cubit.dart';
import 'package:tabala/models/trainer_player_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/status_ui.dart';

/// One player's record, limited to the signed-in trainer's own memberships.
class PlayerDetailView extends StatefulWidget {
  final int userId;

  const PlayerDetailView({super.key, required this.userId});

  @override
  State<PlayerDetailView> createState() => _PlayerDetailViewState();
}

class _PlayerDetailViewState extends State<PlayerDetailView> {
  late final TrainerPlayerDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = TrainerPlayerDetailCubit()..load(widget.userId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(title: Text('player'.tr())),
        body: BlocBuilder<TrainerPlayerDetailCubit, AsyncState<TrainerPlayerDetail>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: () => _cubit.load(widget.userId),
              child: state.hasData ? _content(state.data!) : const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  Widget _content(TrainerPlayerDetail player) {
    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _cubit.load(widget.userId, refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ClubGradientPanel(
            child: Column(
              children: [
                ClubAvatar(
                  initial: player.initial,
                  photoUrl: (player.avatar?.startsWith('http') ?? false)
                      ? player.avatar
                      : null,
                  size: 70,
                  ring: true,
                ),
                const SizedBox(height: 12),
                Text(player.name, style: AppStyles.bold20Black.copyWith(color: PanelInk.strong(context))),
                const SizedBox(height: 4),
                Text(
                  player.email ?? '—',
                  style: AppStyles.regular14Grey.copyWith(color: PanelInk.muted(context)),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'attendance_rate'.tr(),
                        value: '${player.attendanceRate.round()}%',
                        icon: Icons.trending_up_rounded,
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'height_hint'.tr(),
                        value: player.height == null ? '—' : '${player.height}',
                        icon: Icons.height_rounded,
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'weight_hint'.tr(),
                        value: player.weight == null ? '—' : '${player.weight}',
                        icon: Icons.monitor_weight_outlined,
                        onDark: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'attendance_history'.tr(),
            subtitle: 'your_classes_only'.tr(),
          ),
          if (player.attendances.isEmpty)
            ClubCard(
              child: EmptyState(
                icon: Icons.fact_check_outlined,
                title: 'no_attendance_yet'.tr(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          else
            ...player.attendances.map(_attendanceRow),
        ],
      ),
    );
  }

  Widget _attendanceRow(TrainerPlayerAttendance a) {
    final tone = StatusUi.attendance(a.status);

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(StatusUi.attendanceIcon(a.status), size: 18, color: StatusUi.readable(context, tone)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.membershipName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold14Black,
                ),
                const SizedBox(height: 2),
                Text(
                  AppDate.friendlyDateTime(a.date),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.regular12Grey,
                ),
                if (a.note != null) ...[
                  const SizedBox(height: 3),
                  Text(a.note!, style: AppStyles.regular12Grey),
                ],
              ],
            ),
          ),
          StatusChip(label: StatusUi.label(a.status), color: tone),
        ],
      ),
    );
  }
}
