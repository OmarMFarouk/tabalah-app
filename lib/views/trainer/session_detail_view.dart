import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/components/general/assessment_widgets.dart';
import 'package:tabala/components/general/attendance_status.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/session_detail_cubit.dart';
import 'package:tabala/models/membership_session_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/status_ui.dart';
import 'package:tabala/views/trainer/scan_player_qr_view.dart';

/// One session: the roster, four-way attendance per player, each player's
/// health flag, and the trainer's assessment of each player for the session.
///
/// Self check-in (players scanning a session QR) is switched off: the
/// register is taken by the trainer scanning each player. The cubit still
/// carries loadQr/regenerateQr for when that flow comes back.
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(title: Text('session_details'.tr())),
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
                Text(
                  session.membershipName ?? '—',
                  style: AppStyles.bold20Black.copyWith(color: PanelInk.strong(context)),
                ),
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
                        label: 'present'.tr(),
                        value: '${state.presentCount}',
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'assessed'.tr(),
                        value: '${state.assessedCount}/${state.players.length}',
                        onDark: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Said once at the top, so the trainer knows before the session
          // starts rather than on reaching that player's row.
          if (state.flaggedCount > 0) ...[
            const SizedBox(height: 12),
            ClubCard(
              color: AppColors.lightRed,
              border: Border.all(color: AppColors.redcolor.withValues(alpha: .35)),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.medical_information_rounded, color: AppColors.redcolor),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'players_with_condition'.tr(args: ['${state.flaggedCount}']),
                      style: AppStyles.medium14Black,
                    ),
                  ),
                ],
              ),
            ),
          ],

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
            ...state.players.map((p) => _playerRow(session, p)),
        ],
      ),
    );
  }

  Widget _playerRow(MembershipSessionModel session, SessionPlayerModel player) {
    final current = player.isMarked
        ? AttendanceStatusX.fromApiValue(player.attendanceStatus)
        : null;

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      border: player.hasHealthCondition
          ? Border.all(color: AppColors.redcolor.withValues(alpha: .45))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClubAvatar(initial: player.initial, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppStyles.bold14Black,
                    ),
                    if (player.hasHealthCondition) ...[
                      const SizedBox(height: 4),
                      HealthFlag(note: player.healthCondition, dense: true),
                    ],
                  ],
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
                          color: selected ? Colors.white : StatusUi.readable(context, tone),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: AppColors.borderColor),
          const SizedBox(height: 4),
          Row(
            children: [
              if (player.isAssessed) ...[
                RatingStars(value: player.rating!, size: 16),
                const SizedBox(width: 6),
                Text(player.rating!.toStringAsFixed(1), style: AppStyles.bold14Black),
              ] else
                Text('not_assessed'.tr(), style: AppStyles.regular12Grey),
              const Spacer(),
              TextButton.icon(
                onPressed: session.canBeAssessed ? () => _assess(player) : null,
                icon: Icon(
                  player.isAssessed ? Icons.edit_rounded : Icons.star_rate_rounded,
                  size: 18,
                ),
                label: Text(player.isAssessed ? 'edit_assessment'.tr() : 'assess'.tr()),
                style: TextButton.styleFrom(foregroundColor: AppColors.goldInk),
              ),
            ],
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

  Future<void> _assess(SessionPlayerModel player) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfacecolor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AssessSheet(cubit: _cubit, player: player),
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('assessment_saved'.tr())),
      );
    }
  }
}

/// Rating one player for this session. Its own widget so the note field's
/// controller lives exactly as long as the sheet.
class _AssessSheet extends StatefulWidget {
  final SessionDetailCubit cubit;
  final SessionPlayerModel player;

  const _AssessSheet({required this.cubit, required this.player});

  @override
  State<_AssessSheet> createState() => _AssessSheetState();
}

class _AssessSheetState extends State<_AssessSheet> {
  late double _rating = widget.player.rating ?? 4;
  late final TextEditingController _note =
      TextEditingController(text: widget.player.ratingNote ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final error = await widget.cubit.assess(
      userId: widget.player.userId,
      rating: _rating,
      note: _note.text,
    );

    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _saving = false;
      _error = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 22, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClubAvatar(initial: player.initial, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('assess_player'.tr(), style: AppStyles.bold18Black),
                      const SizedBox(height: 2),
                      Text(player.name, style: AppStyles.regular14Grey),
                    ],
                  ),
                ),
              ],
            ),
            if (player.hasHealthCondition && player.healthCondition != null) ...[
              const SizedBox(height: 14),
              HealthNoteCard(note: player.healthCondition!),
            ],
            const SizedBox(height: 18),
            Center(child: Text(_rating.toStringAsFixed(1), style: AppStyles.bold32Gold)),
            const SizedBox(height: 4),
            Directionality(
              textDirection: ui.TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = _rating >= i + 1;
                  final half = !filled && _rating > i;
                  return IconButton(
                    onPressed: () => setState(() => _rating = i + 1.0),
                    icon: Icon(
                      filled
                          ? Icons.star_rounded
                          : (half ? Icons.star_half_rounded : Icons.star_border_rounded),
                      size: 34,
                      color: AppColors.goldInk,
                    ),
                  );
                }),
              ),
            ),
            Slider(
              value: _rating,
              min: 0.5,
              max: 5,
              divisions: 9,
              activeColor: AppColors.primarycolor,
              inactiveColor: AppColors.borderColor,
              label: _rating.toStringAsFixed(1),
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 8),
            CustomTextFormField(
              controller: _note,
              hinttext: 'assessment_note_hint'.tr(),
              maxlines: 3,
              maxLength: 1000,
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: AppStyles.regular14Red, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 18),
            CustomElevatedButton(
              gold: true,
              isBusy: _saving,
              text: 'save_assessment'.tr(),
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
