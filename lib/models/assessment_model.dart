import 'json_utils.dart';

/// `summary` on `/player/assessments` — the overall picture a parent looks at
/// first.
class AssessmentSummary {
  final int count;
  final double? average;
  final double? best;

  /// The last five ratings' average minus the five before them. Null until
  /// there are enough to compare.
  final double? trend;

  const AssessmentSummary({
    this.count = 0,
    this.average,
    this.best,
    this.trend,
  });

  factory AssessmentSummary.fromJson(Map<String, dynamic> json) {
    return AssessmentSummary(
      count: J.asInt(json['count']),
      average: J.asDoubleOrNull(json['average']),
      best: J.asDoubleOrNull(json['best']),
      trend: J.asDoubleOrNull(json['trend']),
    );
  }
}

/// One assessment: a trainer's rating of the player for a session, or a
/// general evaluation with no session behind it.
class AssessmentItem {
  final int id;
  final double rating;
  final String? note;
  final int? sessionId;
  final String? sessionDate;
  final String? membershipName;
  final String? sportName;
  final String? raterName;
  final String? raterRole;
  final String? createdAt;

  /// On the trainer's player screen: whether this trainer wrote it.
  final bool isMine;

  const AssessmentItem({
    required this.id,
    required this.rating,
    this.note,
    this.sessionId,
    this.sessionDate,
    this.membershipName,
    this.sportName,
    this.raterName,
    this.raterRole,
    this.createdAt,
    this.isMine = false,
  });

  bool get isGeneral => sessionId == null;

  factory AssessmentItem.fromJson(Map<String, dynamic> json) {
    return AssessmentItem(
      id: J.asInt(json['id']),
      rating: J.asDouble(json['rating']),
      note: J.asStringOrNull(json['note']),
      sessionId: J.asIntOrNull(json['session_id']),
      sessionDate: J.asStringOrNull(json['session_date']),
      membershipName: J.asStringOrNull(json['membership_name']),
      sportName: J.asStringOrNull(json['sport_name']),
      raterName: J.asStringOrNull(json['rater_name']),
      raterRole: J.asStringOrNull(json['rater_role']),
      createdAt: J.asStringOrNull(json['created_at']),
      isMine: J.asBool(json['is_mine']),
    );
  }
}

class AssessmentsPage {
  final AssessmentSummary summary;
  final List<AssessmentItem> items;
  final PageMeta meta;

  const AssessmentsPage({
    required this.summary,
    required this.items,
    required this.meta,
  });

  AssessmentsPage append(AssessmentsPage next) => AssessmentsPage(
    summary: summary,
    items: [...items, ...next.items],
    meta: next.meta,
  );
}
