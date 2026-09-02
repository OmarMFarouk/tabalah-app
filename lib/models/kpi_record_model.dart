import 'json_utils.dart';

/// Mirrors `App\Http\Resources\KpiRecordResource` - the trainer's own
/// performance rows from `/trainer/kpi-records`.
///
/// `achievement_pct` is computed server-side and is **null when the target
/// is zero**, which is the divide-by-zero guard rather than a missing value.
/// Treat null as "no target set", not as 0%.
class KpiRecordModel {
  final int id;
  final int kpiId;

  /// The KPI's human name, e.g. "Sessions delivered".
  final String metric;
  final double target;
  final double actual;
  final double? achievementPct;

  /// `YYYY-MM`, e.g. `2026-08`.
  final String period;

  const KpiRecordModel({
    required this.id,
    required this.kpiId,
    required this.metric,
    required this.target,
    required this.actual,
    required this.period,
    this.achievementPct,
  });

  bool get hasTarget => target > 0;

  /// 0..1 for a progress bar, clamped so an over-achieving trainer does not
  /// overflow the track.
  double get progress {
    if (!hasTarget) return 0;
    return (actual / target).clamp(0.0, 1.0);
  }

  bool get isMet => hasTarget && actual >= target;

  factory KpiRecordModel.fromJson(Map<String, dynamic> json) {
    return KpiRecordModel(
      id: J.asInt(json['id']),
      kpiId: J.asInt(json['kpi_id']),
      metric: J.asString(json['metric']),
      target: J.asDouble(json['target']),
      actual: J.asDouble(json['actual']),
      achievementPct: J.asDoubleOrNull(json['achievement_pct']),
      period: J.asString(json['period']),
    );
  }
}
