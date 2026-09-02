import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Needed again when the session-QR sheet below is restored.
// import 'package:qr_flutter/qr_flutter.dart';

import 'package:tabala/components/general/attendance_status.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/session_detail_cubit.dart';
import 'package:tabala/models/membership_session_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/status_ui.dart';
import 'package:tabala/views/trainer/scan_player_qr_view.dart';

/// One session: the roster, four-way attendance marking per player, the
/// display QR for self check-in, and a scanner for the reverse direction.
class SessionDetailView extends StatefulWidget {
  final int sessionId;

  const SessionDetailView({super.key, required this.sessionId});

  @override
  State<SessionDetailView> createState() => _SessionDetailViewState();
}

class _SessionDetailViewState extends State<SessionDetailView> {
  late final SessionDetailCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SessionDetailCubit()..load(widget.sessionId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openScanner() async {
    final scanned = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ScanPlayerQrView(cubit: _cubit)),
    );

    if (scanned == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('attendance_marked'.tr())),
      );
    }
  }

  // Kept for when player self check-in is re-enabled.
  // Future<void> _showQrSheet() async {
  //   // Fetch before opening so the sheet never appears empty; the token is
  //   // cached on the state afterwards.
  //   if (_cubit.state.qrToken == null) await _cubit.loadQr();
  //   if (!mounted) return;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (sheetContext) => BlocProvider.value(
  //       value: _cubit,
  //       child: BlocBuilder<SessionDetailCubit, SessionDetailState>(
  //         builder: (context, state) {
  //           return Padding(
  //             padding: const EdgeInsets.fromLTRB(28, 26, 28, 34),
  //             child: Column(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text('session_qr_title'.tr(), style: AppStyles.bold18Black),
  //                 const SizedBox(height: 6),
  //                 Text(
  //                   'session_qr_desc'.tr(),
  //                   style: AppStyles.regular14Grey,
  //                   textAlign: TextAlign.center,
  //                 ),
  //                 const SizedBox(height: 22),
  //                 if (state.qrToken == null)
  //                   CircularProgressIndicator(color: AppColors.goldInk)
  //                 else
  //                   Container(
  //                     padding: const EdgeInsets.all(18),
  //                     decoration: BoxDecoration(
  //                       // Always white behind a QR: scanners need the
  //                       // contrast and inverted codes fail on many readers.
  //                       color: Colors.white,
  //                       borderRadius: BorderRadius.circular(22),
  //                       border: Border.all(
  //                         color: AppColors.primary.withValues(alpha: .4),
  //                         width: 2,
  //                       ),
  //                     ),
  //                     child: QrImageView(
  //                       data: state.qrToken!,
  //                       size: 216,
  //                       version: QrVersions.auto,
  //                       backgroundColor: Colors.white,
  //                     ),
  //                   ),
  //                 const SizedBox(height: 18),
  //                 TextButton.icon(
  //                   onPressed: () => _cubit.regenerateQr(),
  //                   icon: const Icon(Icons.refresh_rounded, size: 18),
  //                   label: Text('regenerate_qr'.tr(), style: AppStyles.bold14Gold),
  //                 ),
  //                 Text(
  //                   'regenerate_qr_hint'.tr(),
  //                   textAlign: TextAlign.center,
  //                   style: AppStyles.regular12Grey,
  //                 ),
  //               ],
  //             ),
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(
          title: Text('session_details'.tr()),
          // Self check-in is switched off: the register is taken by the
          // trainer scanning each player, not by players scanning a code
          // the whole class can see. Restore this with _showQrSheet below
          // if that flow comes back.
          // actions: [
          //   IconButton(
          //     icon: const Icon(Icons.qr_code_rounded),
          //     onPressed: _showQrSheet,
          //   ),
          // ],
        ),
        body: BlocBuilder<SessionDetailCubit, SessionDetailState>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isLoading && !state.hasData,
              errorMessage: state.hasData ? null : state.error,
              onRetry: () => _cubit.load(widget.sessionId),
              child: state.hasData ? _content(state) : const SizedBox(),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openScanner,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.clubGreenDeep,
          icon: const Icon(Icons.qr_code_scanner_rounded),
          label: Text(
            'scan_player'.tr(),
            style: AppStyles.bold14Black.copyWith(color: AppColors.clubGreenDeep),
          ),
        ),
      ),
    );
  }

  Widget _content(SessionDetailState state) {
    final session = state.session!;

    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _cubit.load(widget.sessionId, refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ClubGradientPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (session.sportName ?? '').toUpperCase(),
                        style: AppStyles.bold11Gold,
                      ),
                    ),
                    StatusChip(
                      label: StatusUi.label(session.status),
                      color: StatusUi.session(session.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(session.membershipName ?? '—', style: AppStyles.bold20Black.copyWith(color: PanelInk.strong(context))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.event_rounded, size: 15, color: AppColors.goldInk),
                    const SizedBox(width: 6),
                    Text(
                      AppDate.friendlyDate(session.sessionDate),
                      style: AppStyles.medium14Black.copyWith(color: PanelInk.strong(context)),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.schedule_rounded, size: 15, color: AppColors.goldInk),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        session.timeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.medium14Black.copyWith(color: PanelInk.strong(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'players'.tr(),
                        value: '${state.players.length}',
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'marked'.tr(),
                        value: '${state.markedCount}',
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'present'.tr(),
                        value: '${state.presentCount}',
                        onDark: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader(
            title: 'players'.tr(),
            subtitle: 'tap_status_to_mark'.tr(),
          ),
          if (state.players.isEmpty)
            ClubCard(
              child: EmptyState(
                icon: Icons.group_off_rounded,
                title: 'no_players_enrolled'.tr(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            )
          else
            ...state.players.map(_playerRow),
        ],
      ),
    );
  }

  Widget _playerRow(SessionPlayerModel player) {
    final current = player.isMarked
        ? AttendanceStatusX.fromApiValue(player.attendanceStatus)
        : null;

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(initial: player.initial, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold14Black,
                ),
              ),
              if (!player.isMarked)
                StatusChip(label: 'not_marked'.tr(), color: AppColors.greycolor),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: AttendanceStatus.values.map((status) {
              final selected = current == status;
              final tone = StatusUi.attendance(status.apiValue);

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _mark(player, status),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? StatusUi.readable(context, tone)
                            : tone.withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? StatusUi.readable(context, tone)
                              : tone.withValues(alpha: .3),
                        ),
                      ),
                      child: Text(
                        status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppStyles.medium12Black.copyWith(
                          color: selected
                              ? Colors.white
                              : StatusUi.readable(context, tone),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _mark(SessionPlayerModel player, AttendanceStatus status) async {
    final error = await _cubit.mark(userId: player.userId, status: status.apiValue);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.redcolor),
      );
    }
  }
}
