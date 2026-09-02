import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/api/api_client.dart';
import 'package:tabala/api/api_endpoints.dart';
import 'package:tabala/api/api_exception.dart';
import 'package:tabala/models/json_utils.dart';
import 'package:tabala/models/kpi_record_model.dart';
import 'package:tabala/models/salary_model.dart';
import 'async_state.dart';

/// The trainer's KPI records and salary history, fetched together because
/// they share one screen. Both endpoints are paginated and both are scoped
/// server-side to `Auth::id()`, so there is nothing to filter client-side.
class TrainerPerformance {
  final List<KpiRecordModel> kpis;
  final List<SalaryModel> salaries;
  final PageMeta kpiMeta;
  final PageMeta salaryMeta;

  const TrainerPerformance({
    this.kpis = const [],
    this.salaries = const [],
    this.kpiMeta = const PageMeta(),
    this.salaryMeta = const PageMeta(),
  });

  /// The most recent period present in the KPI rows, used to headline the
  /// screen. Periods are `YYYY-MM` strings, which sort correctly as text.
  String? get latestPeriod {
    if (kpis.isEmpty) return null;
    final periods = kpis.map((k) => k.period).toList()..sort();
    return periods.last;
  }

  List<KpiRecordModel> get currentPeriodKpis {
    final period = latestPeriod;
    if (period == null) return const [];
    return kpis.where((k) => k.period == period).toList();
  }

  /// Mean achievement across the latest period's KPIs. Rows with no target
  /// are skipped rather than counted as zero - a KPI with target 0 has a
  /// null `achievement_pct` server-side precisely because the percentage is
  /// undefined, not because performance was nil.
  double? get currentAchievement {
    final scored = currentPeriodKpis.where((k) => k.hasTarget).toList();
    if (scored.isEmpty) return null;
    final sum = scored.fold<double>(0, (acc, k) => acc + (k.achievementPct ?? 0));
    return sum / scored.length;
  }

  SalaryModel? get latestSalary => salaries.isEmpty ? null : salaries.first;

  bool get isEmpty => kpis.isEmpty && salaries.isEmpty;
}

class TrainerPerformanceCubit extends Cubit<AsyncState<TrainerPerformance>> {
  TrainerPerformanceCubit() : super(const AsyncState.idle());

  Future<void> load({bool refresh = false}) async {
    emit(refresh ? state.toRefreshing() : const AsyncState.loading());

    try {
      // Fired in parallel: they are independent reads and the screen needs
      // both before it can render anything meaningful.
      final results = await Future.wait([
        ApiClient.instance.get(ApiEndpoints.trainerKpiRecords, query: {'per_page': 50}),
        ApiClient.instance.get(ApiEndpoints.trainerSalaries, query: {'per_page': 24}),
      ]);

      final kpiResponse = results[0];
      final salaryResponse = results[1];

      emit(AsyncState.ready(TrainerPerformance(
        kpis: J.list(kpiResponse['kpi_records'], KpiRecordModel.fromJson),
        salaries: J.list(salaryResponse['salaries'], SalaryModel.fromJson),
        kpiMeta: PageMeta.fromJson(
          kpiResponse['meta'] is Map
              ? Map<String, dynamic>.from(kpiResponse['meta'] as Map)
              : null,
        ),
        salaryMeta: PageMeta.fromJson(
          salaryResponse['meta'] is Map
              ? Map<String, dynamic>.from(salaryResponse['meta'] as Map)
              : null,
        ),
      )));
    } on ApiException catch (e) {
      emit(AsyncState.failed(e.message, previous: state.data));
    }
  }
}
