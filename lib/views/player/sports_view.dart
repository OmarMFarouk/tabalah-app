import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/home/home_carousels.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/sports_cubit.dart';
import 'package:tabala/models/sport_page_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_money.dart';
import 'package:tabala/src/utils/sport_visual.dart';
import 'package:tabala/src/utils/status_ui.dart';
import 'package:tabala/views/player/membership_detail_view.dart';

/// The club's catalogue. A gold-accented filter rail across the top, then a
/// section per sport with its plans.
class SportsView extends StatefulWidget {
  const SportsView({super.key});

  @override
  State<SportsView> createState() => _SportsViewState();
}

class _SportsViewState extends State<SportsView> {
  late final SportsCubit _cubit;
  int _selectedSportId = -1; // -1 == all

  @override
  void initState() {
    super.initState();
    _cubit = SportsCubit()..load();
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
        appBar: AppBar(title: Text('sports_and_membership'.tr())),
        body: BlocBuilder<SportsCubit, AsyncState<List<SportWithPlans>>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: _cubit.load,
              isEmpty: state.hasData && state.data!.isEmpty,
              emptyMessage: 'no_sports_yet'.tr(),
              child: state.hasData ? _content(state.data!) : const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  Widget _content(List<SportWithPlans> sports) {
    final visible = _selectedSportId == -1
        ? sports
        : sports.where((s) => s.id == _selectedSportId).toList();

    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _cubit.load(refresh: true),
      child: ListView(
        padding: EdgeInsets.only(
          top: 12,
          bottom: ClubBottomNav.scrollPadding(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          CarouselRail(
            height: 44,
            gap: 8,
            children: [
              _filterChip('all_sports'.tr(), _selectedSportId == -1,
                  () => setState(() => _selectedSportId = -1)),
              ...sports.map(
                (s) => _filterChip(
                  s.name,
                  _selectedSportId == s.id,
                  () => setState(() => _selectedSportId = s.id),
                  icon: s.icon,
                  imageUrl: s.imageUrl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final sport in visible.where((s) => s.hasPlans))
            _sportSection(sport),
        ],
      ),
    );
  }

  Widget _filterChip(
    String label,
    bool selected,
    VoidCallback onTap, {
    String? icon,
    String? imageUrl,
  }) {
    // The "all sports" chip has no mark of its own, and giving it a generic
    // one would make it look like just another sport in the rail.
    final hasMark = icon != null || SportVisual.usable(imageUrl);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.only(
          left: hasMark ? 6 : 16,
          right: 16,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: AppColors.goldGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.borderColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasMark) ...[
              SportMark(
                imageUrl: imageUrl,
                icon: icon,
                size: 30,
                radius: 15,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: selected
                  ? AppStyles.bold14Black.copyWith(color: AppColors.clubGreenDeep)
                  : AppStyles.medium14Grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sportSection(SportWithPlans sport) {
    final cheapest = sport.cheapest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 18, 0, 12),
            child: Row(
              children: [
                SportMark(
                  imageUrl: sport.imageUrl,
                  icon: sport.icon,
                  size: 46,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SectionHeader(
                    title: sport.name,
                    subtitle: cheapest == null
                        ? sport.description
                        : '${'from_price'.tr()} ${AppMoney.format(cheapest.price)}',
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          ...sport.plans.map((plan) => _planCard(sport, plan)),
        ],
      ),
    );
  }

  Widget _planCard(SportWithPlans sport, MembershipPlan plan) {
    final tone = StatusUi.membershipRelation(plan.enrollmentStatus);

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => _openPlan(plan.id),
      // The plan's own artwork behind the card, faded far enough back that
      // the price and status chip keep their contrast.
      imageUrl: plan.imageUrl,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold16Black,
                ),
              ),
              const SizedBox(width: 10),
              StatusChip(label: StatusUi.label(plan.enrollmentStatus), color: tone),
            ],
          ),
          if (plan.description != null) ...[
            const SizedBox(height: 6),
            Text(
              plan.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.regular14Grey,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              _metaPill(Icons.payments_rounded, AppMoney.format(plan.price)),
              const SizedBox(width: 8),
              if (plan.durationDays != null)
                _metaPill(
                  Icons.calendar_month_rounded,
                  'days_count'.tr(args: ['${plan.durationDays}']),
                ),
              const SizedBox(width: 8),
              if (plan.maxAttendees != null)
                _metaPill(
                  Icons.groups_rounded,
                  'max_attendees_short'.tr(args: ['${plan.maxAttendees}']),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openPlan(plan.id),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: plan.canSubscribe
                      ? AppColors.primary.withValues(alpha: .55)
                      : AppColors.borderColor,
                ),
              ),
              child: Text(
                plan.isEnrolled
                    ? 'view_membership'.tr()
                    : plan.isPendingPayment
                        ? 'awaiting_activation'.tr()
                        : plan.isFree
                            ? 'join_for_free'.tr()
                            : 'subscribe_now'.tr(),
                style: plan.canSubscribe
                    ? AppStyles.bold14Gold
                    : AppStyles.medium14Grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String label) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.cardcolor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.subtextcolor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppStyles.medium12Grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPlan(int membershipId) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MembershipDetailView(membershipId: membershipId)),
    );
    if (changed == true) _cubit.load(refresh: true);
  }
}
