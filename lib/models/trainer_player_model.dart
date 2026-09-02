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

  const TrainerPlayerSummary({
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
    this.attendanceRate = 0,
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
    );
  }
}

/// `/trainer/players/{playerUserId}` - the same person plus their
/// attendance history, again limited to the trainer's own memberships.
class TrainerPlayerDetail {
  final int userId;
  final String name;
  final String? email;
  final String? avatar;
  final double? height;
  final double? weight;
  final List<TrainerPlayerAttendance> attendances;

  const TrainerPlayerDetail({
    required this.userId,
    required this.name,
    this.email,
    this.avatar,
    this.height,
    this.weight,
    this.attendances = const [],
  });

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  int get presentCount => attendances.where((a) => a.status == 'present').length;

  double get attendanceRate {
    if (attendances.isEmpty) return 0;
    return presentCount / attendances.length * 100;
  }

  factory TrainerPlayerDetail.fromJson({
    required Map<String, dynamic> player,
    required dynamic attendances,
  }) {
    return TrainerPlayerDetail(
      userId: J.asInt(player['user_id']),
      name: J.asString(player['name']),
      email: J.asStringOrNull(player['email']),
      avatar: J.asStringOrNull(player['avatar']),
      height: J.asDoubleOrNull(player['height']),
      weight: J.asDoubleOrNull(player['weight']),
      attendances: J.list(attendances, TrainerPlayerAttendance.fromJson),
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
