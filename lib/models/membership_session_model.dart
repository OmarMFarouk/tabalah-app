import 'package:tabala/src/utils/app_date.dart';

import 'json_utils.dart';

/// Mirrors `App\Http\Resources\MembershipSessionResource`.
///
/// A note on `session_date`, because it is not consistent across the API:
/// this resource calls `->toDateString()`, so it sends a clean
/// `2026-08-01`. The player homepage resource instead passes the Carbon
/// object through PHP's `date()`, which yields `2026-08-01 00:00:00`. Both
/// are handled by AppDate, which is why nothing here tries to slice the
/// string by hand.
class MembershipSessionModel {
  final int id;
  final int membershipId;
  final String? membershipName;
  final String? sportName;
  final String? trainerName;
  final int? scheduleId;

  /// `scheduled` | `ongoing` | `completed` | `cancelled`.
  final String status;

  final String sessionDate;
  final String startTime;
  final String endTime;

  final String? qrRegeneratedAt;
  final int? attendancesCount;

  const MembershipSessionModel({
    required this.id,
    required this.membershipId,
    required this.status,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    this.membershipName,
    this.sportName,
    this.trainerName,
    this.scheduleId,
    this.qrRegeneratedAt,
    this.attendancesCount,
  });

  /// `Today · 6:00 PM – 7:30 PM`
  String get whenLabel => AppDate.friendlySession(sessionDate, startTime, endTime);

  String get timeLabel => AppDate.timeRange(startTime, endTime);

  String get dayLabel => AppDate.friendlyDate(sessionDate);

  bool get isToday => AppDate.isToday(sessionDate);

  /// Check-in is refused server-side for these two, so the UI should not
  /// offer the scanner for them either.
  bool get isClosedForCheckIn => status == 'cancelled' || status == 'completed';

  factory MembershipSessionModel.fromJson(Map<String, dynamic> json) {
    return MembershipSessionModel(
      id: J.asInt(json['id']),
      membershipId: J.asInt(json['membership_id']),
      membershipName: J.asStringOrNull(json['membership_name']),
      sportName: J.asStringOrNull(json['sport_name']),
      trainerName: J.asStringOrNull(json['trainer_name']),
      scheduleId: J.asIntOrNull(json['schedule_id']),
      status: J.asString(json['status'], fallback: 'scheduled'),
      sessionDate: J.asString(json['session_date']),
      startTime: J.asString(json['start_time']),
      endTime: J.asString(json['end_time']),
      qrRegeneratedAt: J.asStringOrNull(json['qr_regenerated_at']),
      attendancesCount: J.asIntOrNull(json['attendances_count']),
    );
  }
}

/// A player row on the trainer's session detail screen, with their
/// attendance status for that specific session.
///
/// `attendance_status` is the usual four values *plus* `not_marked`, which
/// the controller substitutes when no attendance row exists yet. That fifth
/// value is not a DB enum member - do not try to send it back.
class SessionPlayerModel {
  final int userId;
  final String name;
  final String attendanceStatus;
  final int? attendanceId;

  const SessionPlayerModel({
    required this.userId,
    required this.name,
    required this.attendanceStatus,
    this.attendanceId,
  });

  bool get isMarked => attendanceStatus != 'not_marked';

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  factory SessionPlayerModel.fromJson(Map<String, dynamic> json) {
    return SessionPlayerModel(
      userId: J.asInt(json['user_id']),
      name: J.asString(json['name']),
      attendanceStatus: J.asString(json['attendance_status'], fallback: 'not_marked'),
      attendanceId: J.asIntOrNull(json['attendance_id']),
    );
  }
}
