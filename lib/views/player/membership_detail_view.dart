import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/membership_detail_cubit.dart';
import 'package:tabala/models/membership_detail_model.dart';
import 'package:tabala/src/app_scope.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/app_money.dart';
import 'package:tabala/src/utils/status_ui.dart';
import 'package:tabala/views/player/checkout_view.dart';
import 'package:tabala/views/player/rate_session_view.dart';

class MembershipDetailView extends StatefulWidget {
  final int membershipId;

  const MembershipDetailView({super.key, required this.membershipId});

  @override
  State<MembershipDetailView> createState() => _MembershipDetailViewState();
}

class _MembershipDetailViewState extends State<MembershipDetailView> {
  late final MembershipDetailCubit _cubit;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _cubit = MembershipDetailCubit()..load(widget.membershipId);
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
        appBar: AppBar(
          title: Text('membership'.tr()),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            // Returns whether an enrollment happened, so the sports list
            // behind this screen refreshes its enrollment_status badges.
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: BlocBuilder<MembershipDetailCubit, AsyncState<MembershipDetail>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: () => _cubit.load(widget.membershipId),
              child: state.hasData ? _content(state.data!) : const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  Widget _content(MembershipDetail m) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              ClubGradientPanel(
                // The club's artwork for this plan, behind the gradient.
                imageUrl: m.imageUrl,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SportMark(
                          imageUrl: m.sportImageUrl,
                          icon: m.sportIcon,
                          size: 34,
                          radius: 11,
                          onPanel: true,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            (m.sportName ?? '').toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppStyles.bold11Gold,
                          ),
                        ),
                        StatusChip(
                          label: StatusUi.label(m.enrollmentStatus),
                          color: StatusUi.membershipRelation(m.enrollmentStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(m.name, style: AppStyles.bold24Black.copyWith(color: PanelInk.strong(context))),
                    if (m.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        m.description!,
                        style: AppStyles.regular14Grey.copyWith(color: PanelInk.muted(context)),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            label: 'price'.tr(),
                            value: AppMoney.format(m.price),
                            icon: Icons.payments_rounded,
                            onDark: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(
                            label: 'duration'.tr(),
                            value: m.durationDays == null
                                ? 'open_ended'.tr()
                                : 'days_count'.tr(args: ['${m.durationDays}']),
                            icon: Icons.calendar_month_rounded,
                            onDark: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatTile(
                            label: 'type'.tr(),
                            value: m.type.tr(),
                            icon: Icons.tune_rounded,
                            onDark: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (m.trainerName != null) ...[
                SectionHeader(title: 'coach'.tr()),
                ClubCard(
                  child: Row(
                    children: [
                      ClubAvatar(
                        initial: m.trainerName![0].toUpperCase(),
                        photoUrl: (m.trainerAvatar?.startsWith('http') ?? false)
                            ? m.trainerAvatar
                            : null,
                        size: 48,
                        ring: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.trainerName!, style: AppStyles.bold16Black),
                            const SizedBox(height: 2),
                            Text(m.sportName ?? 'coach'.tr(),
                                style: AppStyles.regular12Grey),
                          ],
                        ),
                      ),
                      if (m.trainerRatingLabel != null)
                        StatusChip(
                          label: m.trainerRatingLabel!,
                          color: AppColors.goldInk,
                          icon: Icons.star_rounded,
                        ),
                    ],
                  ),
                ),
              ],

              SectionHeader(title: 'schedule'.tr()),
              if (m.schedules.isEmpty)
                ClubCard(
                  child: Text('no_schedule_yet'.tr(), style: AppStyles.regular14Grey),
                )
              else
                ClubCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < m.schedules.length; i++) ...[
                        if (i > 0) Divider(color: AppColors.borderColor, height: 22),
                        Row(
                          children: [
                            Icon(
                              m.schedules[i].isWeekly
                                  ? Icons.event_repeat_rounded
                                  : Icons.event_rounded,
                              size: 17,
                              color: AppColors.goldInk,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                m.schedules[i].dayLabel,
                                style: AppStyles.medium14Black,
                              ),
                            ),
                            Text(
                              m.schedules[i].timeLabel,
                              style: AppStyles.regular14Grey,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

              SectionHeader(
                title: 'upcoming_sessions'.tr(),
                subtitle: m.upcomingSessions.isEmpty
                    ? null
                    : 'next_sessions_count'.tr(args: ['${m.upcomingSessions.length}']),
              ),
              if (m.upcomingSessions.isEmpty)
                ClubCard(
                  child: Text('no_upcoming_sessions'.tr(), style: AppStyles.regular14Grey),
                )
              else
                ...m.upcomingSessions.map((s) => _sessionRow(m, s)),

              const SizedBox(height: 12),
            ],
          ),
        ),
        _bottomCta(m),
      ],
    );
  }

  Widget _sessionRow(MembershipDetail m, UpcomingSession session) {
    final tone = StatusUi.session(session.status);

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      // Rating is only accepted for a session the member actually attended,
      // and only makes sense once it has happened - so the tap target is
      // limited to completed sessions of a membership they are enrolled in.
      // Rating a session is the member's own judgement to give, and the
      // endpoint refuses a guardian token anyway.
      onTap: (m.isEnrolled &&
              session.status == 'completed' &&
              !AppScope.isGuardian)
          ? () => _rate(m, session)
          : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(StatusUi.sessionIcon(session.status), size: 19, color: StatusUi.readable(context, tone)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppDate.friendlyDate(session.sessionDate),
                  style: AppStyles.bold14Black,
                ),
                const SizedBox(height: 2),
                Text(
                  AppDate.timeRange(session.startTime, session.endTime),
                  style: AppStyles.regular12Grey,
                ),
              ],
            ),
          ),
          if (m.isEnrolled && session.status == 'completed' && !AppScope.isGuardian)
            Icon(Icons.star_outline_rounded, size: 20, color: AppColors.goldInk)
          else
            StatusChip(label: StatusUi.label(session.status), color: tone),
        ],
      ),
    );
  }

  Future<void> _rate(MembershipDetail m, UpcomingSession session) async {
    final rated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => RateSessionView(
          sessionId: session.id,
          sessionLabel: AppDate.friendlySession(
            session.sessionDate,
            session.startTime,
            session.endTime,
          ),
          trainerName: m.trainerName,
        ),
      ),
    );

    if (rated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('rating_submitted'.tr())),
      );
    }
  }

  Widget _bottomCta(MembershipDetail m) {
    // Subscribing spends money, so the whole bar goes away in a parent's
    // session rather than being shown disabled - the status chip in the
    // hero already tells them where the membership stands.
    if (AppScope.isGuardian) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Builder(
          builder: (_) {
            if (m.isPendingPayment) {
              return ClubCard(
                color: AppColors.lightOrange,
                border: Border.all(color: AppColors.orangecolor.withValues(alpha: .35)),
                child: Row(
                  children: [
                    Icon(Icons.hourglass_bottom_rounded,
                        size: 18, color: AppColors.orangecolor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('awaiting_activation'.tr(),
                          style: AppStyles.medium14Black),
                    ),
                  ],
                ),
              );
            }

            if (m.isEnrolled) {
              return ClubCard(
                color: AppColors.lightGreen,
                border: Border.all(color: AppColors.greencolor.withValues(alpha: .35)),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 18, color: AppColors.greencolor),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          Text('already_enrolled'.tr(), style: AppStyles.medium14Black),
                    ),
                  ],
                ),
              );
            }

            return CustomElevatedButton(
              gold: true,
              text: m.isFree ? 'join_for_free'.tr() : 'subscribe_now'.tr(),
              onPressed: () => _checkout(m),
            );
          },
        ),
      ),
    );
  }

  Future<void> _checkout(MembershipDetail m) async {
    final paid = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutView(
          membershipId: widget.membershipId,
          membershipName: m.name,
          price: m.price,
        ),
      ),
    );

    if (paid == true) {
      _changed = true;
      _cubit.reload();
    }
  }
}
