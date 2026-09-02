import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/sessions_board_cubit.dart';
import 'package:tabala/models/membership_session_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/status_ui.dart';
import 'package:tabala/views/trainer/session_detail_view.dart';

/// The trainer's kanban board. Long-press a card to drag it into another
/// status column; the move is optimistic and reconciled against the server.
class SessionsBoardView extends StatefulWidget {
  const SessionsBoardView({super.key});

  @override
  State<SessionsBoardView> createState() => _SessionsBoardViewState();
}

class _SessionsBoardViewState extends State<SessionsBoardView> {
  late final SessionsBoardCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = SessionsBoardCubit()..load();
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
        appBar: AppBar(title: Text('sessions'.tr())),
        body: BlocBuilder<SessionsBoardCubit, AsyncState<SessionsBoard>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: _cubit.load,
              isEmpty: state.hasData && state.data!.isEmpty,
              emptyMessage: 'no_sessions_in_window'.tr(),
              child: state.hasData ? _board(state.data!) : const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  Widget _board(SessionsBoard board) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            'board_window_hint'.tr(),
            style: AppStyles.regular12Grey,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: kSessionColumns
                  .map((status) => _column(status, board.column(status)))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _column(String status, List<MembershipSessionModel> sessions) {
    final tone = StatusUi.session(status);

    return Container(
      width: 274,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: DragTarget<MembershipSessionModel>(
        onWillAcceptWithDetails: (details) => details.data.status != status,
        onAcceptWithDetails: (details) async {
          final error = await _cubit.reschedule(details.data, status: status);
          if (error != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: AppColors.redcolor),
            );
          }
        },
        builder: (context, candidate, rejected) {
          final targeted = candidate.isNotEmpty;

          return Container(
            constraints: const BoxConstraints(minHeight: 200),
            decoration: BoxDecoration(
              color: targeted
                  ? tone.withValues(alpha: .10)
                  : AppColors.surfacecolor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: targeted ? tone : AppColors.borderColor,
                width: targeted ? 1.6 : 1,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(StatusUi.label(status), style: AppStyles.bold14Black),
                    ),
                    StatusChip(label: '${sessions.length}', color: tone),
                  ],
                ),
                const SizedBox(height: 12),
                if (sessions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 26),
                    child: Text(
                      targeted ? 'drop_here'.tr() : 'empty_column'.tr(),
                      style: AppStyles.regular12Grey,
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...sessions.map(_draggableCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _draggableCard(MembershipSessionModel session) {
    return LongPressDraggable<MembershipSessionModel>(
      data: session,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 244, child: _card(session, elevated: true)),
      ),
      childWhenDragging: Opacity(opacity: .3, child: _card(session)),
      child: GestureDetector(
        onTap: () => _open(session.id),
        onLongPress: () {},
        child: _card(session),
      ),
    );
  }

  Widget _card(MembershipSessionModel session, {bool elevated = false}) {
    final tone = StatusUi.session(session.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardcolor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .22),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  session.membershipName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold14Black,
                ),
              ),
              if (session.isToday)
                StatusChip(label: 'today'.tr(), color: AppColors.goldInk),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            session.sportName ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.regular12Grey,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.event_rounded, size: 13, color: StatusUi.readable(context, tone)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  AppDate.friendlyDate(session.sessionDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.medium12Grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 13, color: StatusUi.readable(context, tone)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  session.timeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.medium12Grey,
                ),
              ),
              if (session.attendancesCount != null)
                StatusChip(
                  label: '${session.attendancesCount}',
                  color: AppColors.bluecolor,
                  icon: Icons.how_to_reg_rounded,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _open(int sessionId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SessionDetailView(sessionId: sessionId)),
    );
    if (mounted) _cubit.load(refresh: true);
  }
}
