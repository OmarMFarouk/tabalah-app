import 'json_utils.dart';

/// Attendance as it reaches the player's attendance screen.
///
/// Careful: two different endpoints return attendance in two different
/// shapes, and this model absorbs both.
///
/// * `GET /player/attendances` builds an inline array in the controller with
///   `sport_name` and `membership_name`, and its `date` is the raw
///   `player_attendances.date` column - a TIMESTAMP, so it arrives as
///   `2026-08-01 10:00:00`, not as a plain date.
/// * `POST /player/check-in` and the trainer's marking endpoints return a
///   full `PlayerAttendanceResource`, which has `membership_id`,
///   `session_id`, `note` and `user_id` but no `sport_name`.
///
/// Both are accepted here so the same widget can render either.
class PlayerAttendanceModel {
  final int id;
  final int? userId;
  final int? membershipId;
  final int? sessionId;

  /// `present` | `absent` | `late` | `excused`.
  final String status;

  /// Raw string from the API - format it through AppDate, never print it.
  final String date;

  final String sportName;
  final String membershipName;
  final String? note;

  const PlayerAttendanceModel({
    required this.id,
    required this.status,
    required this.date,
    this.userId,
    this.membershipId,
    this.sessionId,
    this.sportName = '',
    this.membershipName = '',
    this.note,
  });

  bool get isPresent => status == 'present';

  /// Present and late both mean the member showed up. Excused means they
  /// were let off, which is neither attendance nor a black mark, so it is
  /// deliberately excluded from the "turned up" count.
  bool get countsAsAttended => status == 'present' || status == 'late';

  factory PlayerAttendanceModel.fromJson(Map<String, dynamic> json) {
    return PlayerAttendanceModel(
      id: J.asInt(json['id']),
      userId: J.asIntOrNull(json['user_id']),
      membershipId: J.asIntOrNull(json['membership_id']),
      sessionId: J.asIntOrNull(json['session_id']),
      status: J.asString(json['status'], fallback: 'present'),
      date: J.asString(json['date']),
      sportName: J.asString(json['sport_name']),
      membershipName: J.asString(json['membership_name']),
      note: J.asStringOrNull(json['note']),
    );
  }
}
