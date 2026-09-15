import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tabala/components/general/assessment_widgets.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/assessments_cubit.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/models/assessment_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/guardian/guardian_main_view.dart';
import 'package:tabala/views/player/player_main_view.dart';

/// How the player is being assessed: the overall rating and its direction,
/// then every assessment session by session.
///
/// Shared by the member app (pushed from the profile) and the parent portal
/// (one of its tabs). The data is the same; only the chrome differs.
class AssessmentsView extends StatefulWidget {
  /// True inside the parent portal's tab bar: no app bar of its own, and room
  /// left at the bottom for the floating nav.
  final bool asTab;

  const AssessmentsView({super.key, this.asTab = false});

  @override
  State<AssessmentsView> createState() => _AssessmentsViewState();
}

class _AssessmentsViewState extends State<AssessmentsView> {
  late final AssessmentsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AssessmentsCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = widget.asTab ? ClubBottomNav.scrollPadding(context) : 32.0;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: widget.asTab ? null : AppBar(title: Text('my_assessments'.tr())),
        body: SafeArea(
          top: widget.asTab,
          bottom: false,
          child: BlocBuilder<AssessmentsCubit, AsyncState<AssessmentsPage>>(
            builder: (context, state) {
              final page = state.data;

              if (page == null) {
                return AsyncStateView(
                  isLoading: state.isBusy || !state.hasError,
                  errorMessage: state.error,
                  onRetry: _cubit.load,
                  child: const SizedBox(),
                );
              }

              return RefreshIndicator(
                color: AppColors.goldInk,
                backgroundColor: AppColors.surfacecolor,
                onRefresh: () => _cubit.load(refresh: true),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.pixels >= n.metrics.maxScrollExtent - 300) {
                      _cubit.loadMore();
                    }
                    return false;
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 12, 16, bottom),
                    children: [
                      if (widget.asTab) ...[
                        const GuardianBanner(padding: EdgeInsets.only(bottom: 12)),
                        Text('assessments'.tr(), style: AppStyles.bold24Black),
                        const SizedBox(height: 12),
                      ],
                      _summary(page.summary),
                      SectionHeader(
                        title: 'assessments_by_session'.tr(),
                        subtitle: 'assessments_desc'.tr(),
                      ),
                      if (page.items.isEmpty)
                        ClubCard(
                          child: EmptyState(
                            icon: Icons.star_outline_rounded,
                            title: 'no_assessments'.tr(),
                            message: 'no_assessments_desc'.tr(),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        )
                      else
                        ...page.items.map((a) => AssessmentCard(item: a)),
                      if (page.meta.hasMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summary(AssessmentSummary s) {
    final trend = s.trend;
    final (label, icon, tone) = trend == null
        ? ('—', Icons.remove_rounded, AppColors.greycolor)
        : trend > 0.1
        ? ('improving'.tr(), Icons.trending_up_rounded, AppColors.greencolor)
        : trend < -0.1
        ? ('declining'.tr(), Icons.trending_down_rounded, AppColors.redcolor)
        : ('steady'.tr(), Icons.trending_flat_rounded, AppColors.goldInk);

    return ClubGradientPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('overall_rating'.tr(), style: AppStyles.bold11Gold),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(s.average?.toStringAsFixed(1) ?? '—', style: AppStyles.bold32Gold),
              const SizedBox(width: 12),
              RatingStars(value: s.average ?? 0, size: 22),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'assessments'.tr(),
                  value: '${s.count}',
                  icon: Icons.reviews_rounded,
                  onDark: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'best_rating'.tr(),
                  value: s.best?.toStringAsFixed(1) ?? '—',
                  icon: Icons.emoji_events_rounded,
                  onDark: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: StatTile(
                  label: 'trend'.tr(),
                  value: label,
                  icon: icon,
                  accent: tone,
                  onDark: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
