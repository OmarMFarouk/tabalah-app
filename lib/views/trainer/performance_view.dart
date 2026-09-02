import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/trainer_performance_cubit.dart';
import 'package:tabala/models/kpi_record_model.dart';
import 'package:tabala/models/salary_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/app_money.dart';

/// The trainer's own KPI targets and salary history, from
/// `/trainer/kpi-records` and `/trainer/salaries`. Both are scoped to the
/// signed-in user server-side, so nothing here needs filtering.
class TrainerPerformanceView extends StatefulWidget {
  const TrainerPerformanceView({super.key});

  @override
  State<TrainerPerformanceView> createState() => _TrainerPerformanceViewState();
}

class _TrainerPerformanceViewState extends State<TrainerPerformanceView> {
  late final TrainerPerformanceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = TrainerPerformanceCubit()..load();
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
        appBar: AppBar(title: Text('performance'.tr())),
        body: BlocBuilder<TrainerPerformanceCubit, AsyncState<TrainerPerformance>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: _cubit.load,
              isEmpty: state.hasData && state.data!.isEmpty,
              emptyMessage: 'no_performance_records'.tr(),
              child: state.hasData ? _content(state.data!) : const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  Widget _content(TrainerPerformance data) {
    final achievement = data.currentAchievement;

    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _cubit.load(refresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ClubGradientPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.latestPeriod == null
                      ? 'performance'.tr()
                      : AppDate.monthYear(data.latestPeriod),
                  style: AppStyles.bold11Gold,
                ),
                const SizedBox(height: 6),
                Text(
                  achievement == null ? '—' : '${achievement.round()}%',
                  style: AppStyles.bold32Black.copyWith(color: PanelInk.strong(context)),
                ),
                Text(
                  'of_target'.tr(),
                  style: AppStyles.regular12Grey.copyWith(color: PanelInk.muted(context)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'monthly_kpi'.tr(),
                        value: '${data.currentPeriodKpis.length}',
                        icon: Icons.flag_rounded,
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'latest_salary'.tr(),
                        value: data.latestSalary == null
                            ? '—'
                            : AppMoney.amount(data.latestSalary!.amount),
                        icon: Icons.payments_rounded,
                        onDark: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SectionHeader(title: 'monthly_indicators'.tr()),
          if (data.kpis.isEmpty)
            ClubCard(
              child: Text('no_kpi_records'.tr(), style: AppStyles.regular14Grey),
            )
          else
            ...data.kpis.map(_kpiCard),
          SectionHeader(title: 'salary_history'.tr()),
          if (data.salaries.isEmpty)
            ClubCard(
              child: Text('no_salary_records'.tr(), style: AppStyles.regular14Grey),
            )
          else
            ...data.salaries.map(_salaryRow),
        ],
      ),
    );
  }

  Widget _kpiCard(KpiRecordModel kpi) {
    // A null achievement means the target is zero, not that the trainer
    // scored nothing - the backend returns null precisely to avoid a
    // divide by zero. Say "no target" rather than "0%".
    final label = kpi.hasTarget
        ? '${(kpi.achievementPct ?? 0).round()}%'
        : 'no_target'.tr();

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  kpi.metric,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold16Black,
                ),
              ),
              StatusChip(
                label: AppDate.monthYear(kpi.period),
                color: AppColors.bluecolor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ProgressRow(
            label: '${kpi.actual.toStringAsFixed(0)} / ${kpi.target.toStringAsFixed(0)}',
            trailing: label,
            value: kpi.progress,
            color: kpi.isMet ? AppColors.greencolor : AppColors.goldInk,
          ),
        ],
      ),
    );
  }

  Widget _salaryRow(SalaryModel salary) {
    return ClubCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payments_rounded, size: 20, color: AppColors.goldInk),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppDate.monthYear(salary.period), style: AppStyles.bold14Black),
                const SizedBox(height: 2),
                Text('period'.tr(), style: AppStyles.regular12Grey),
              ],
            ),
          ),
          Text(AppMoney.amount(salary.amount), style: AppStyles.bold16Gold),
        ],
      ),
    );
  }
}
