import 'assessment_model.dart';
import 'json_utils.dart';

/// `/trainer/players` - everyone enrolled across the trainer's memberships,
/// deduplicated by user, with an attendance rate scoped to *this trainer's*
/// classes only.
class TrainerPlayerSummary {
  final int userId;
  final String name;
  final String? email;
  final String? avatar;
  final double attendanceRate;

  /// Across every trainer who has assessed them. Null when nobody has yet.
  final double? averageRating;
  final int ratingsCount;
  final bool hasHealthCondition;

  const TrainerPlayerSummary({
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
    this.attendanceRate = 0,
    this.averageRating,
    this.ratingsCount = 0,
    this.hasHealthCondition = false,
  });

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  String? get photo =>
      (avatar != null && avatar!.startsWith('http')) ? avatar : null;

  factory TrainerPlayerSummary.fromJson(Map<String, dynamic> json) {
    return TrainerPlayerSummary(
      userId: J.asInt(json['user_id']),
      name: J.asString(json['name']),
      email: J.asStringOrNull(json['email']),
      avatar: J.asStringOrNull(json['avatar']),
      attendanceRate: J.asDouble(json['attendance_rate']),
      averageRating: J.asDoubleOrNull(json['average_rating']),
      ratingsCount: J.asInt(json['ratings_count']),
      hasHealthCondition: J.asBool(json['has_health_condition']),
    );
  }
}

/// `/trainer/players/{playerUserId}` - the same person, their health note,
/// their assessments, and their attendance in this trainer's memberships.
class TrainerPlayerDetail {
  final int userId;
  final String name;
  final String? email;
  final String? avatar;
  final double? height;
  final double? weight;
  final String? emergencyContact;
  final bool hasHealthCondition;
  final String? healthCondition;
  final double? averageRating;
  final List<TrainerPlayerAttendance> attendances;
  final List<AssessmentItem> assessments;

  const TrainerPlayerDetail({
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
    this.height,
    this.weight,
    this.emergencyContact,
    this.hasHealthCondition = false,
    this.healthCondition,
    this.averageRating,
    this.attendances = const [],
    this.assessments = const [],
  });

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  String? get photo =>
      (avatar != null && avatar!.startsWith('http')) ? avatar : null;

  int get presentCount => attendances.where((a) => a.status == 'present').length;

  double get attendanceRate {
    if (attendances.isEmpty) return 0;
    return presentCount / attendances.length * 100;
  }

  factory TrainerPlayerDetail.fromJson({
    required Map<String, dynamic> player,
    required dynamic attendances,
    dynamic assessments,
  }) {
    return TrainerPlayerDetail(
      userId: J.asInt(player['user_id']),
      name: J.asString(player['name']),
      email: J.asStringOrNull(player['email']),
      avatar: J.asStringOrNull(player['avatar']),
      height: J.asDoubleOrNull(player['height']),
      weight: J.asDoubleOrNull(player['weight']),
      emergencyContact: J.asStringOrNull(player['emergency_contact']),
      hasHealthCondition: J.asBool(player['has_health_condition']),
      healthCondition: J.asStringOrNull(player['health_condition']),
      averageRating: J.asDoubleOrNull(player['average_rating']),
      attendances: J.list(attendances, TrainerPlayerAttendance.fromJson),
      assessments: J.list(assessments, AssessmentItem.fromJson),
    );
  }
}

class TrainerPlayerAttendance {
  final int id;
  final String? membershipName;

  /// Raw `player_attendances.date` - a TIMESTAMP column with no Eloquent
  /// cast, so it arrives as `2026-08-01 10:00:00`.
  final String date;
  final String status;
  final String? note;

  const TrainerPlayerAttendance({
    required this.id,
    required this.date,
    required this.status,
    this.membershipName,
    this.note,
  });

  factory TrainerPlayerAttendance.fromJson(Map<String, dynamic> json) {
    return TrainerPlayerAttendance(
      id: J.asInt(json['id']),
      membershipName: J.asStringOrNull(json['membership_name']),
      date: J.asString(json['date']),
      status: J.asString(json['status'], fallback: 'present'),
      note: J.asStringOrNull(json['note']),
    );
  }
}
