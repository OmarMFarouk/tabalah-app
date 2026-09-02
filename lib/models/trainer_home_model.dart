import 'package:tabala/src/utils/app_date.dart';

import 'json_utils.dart';

/// `/trainer/homepage?date=YYYY-MM-DD` - the trainer's board for one day.
///
/// The endpoint defaults to today when no `date` is passed, and echoes back
/// the date it actually used, which is what the day-strip in the UI binds to.
class TrainerHomeData {
  final int trainerId;
  final String trainerName;

  /// `YYYY-MM-DD`, echoed by the server.
  final String date;
  final List<TrainerDaySession> sessions;

  const TrainerHomeData({
    required this.trainerId,
    required this.trainerName,
    required this.date,
    this.sessions = const [],
  });

  int get playerCount =>
      sessions.fold<int>(0, (acc, s) => acc + s.players.length);

  /// Mean attendance across the day's sessions, for the hero stat.
  double get averageAttendanceRate {
    if (sessions.isEmpty) return 0;
    final sum = sessions.fold<double>(0, (acc, s) => acc + s.attendanceRate);
    return sum / sessions.length;
  }

  factory TrainerHomeData.fromJson(Map<String, dynamic> json) {
    return TrainerHomeData(
      trainerId: J.asInt(json['trainer_id']),
      trainerName: J.asString(json['trainer_name']),
      date: J.asString(json['date']),
      sessions: J.list(json['today_sessions'], TrainerDaySession.fromJson),
    );
  }
}

/// One session on the trainer's day, with its roster.
///
/// `total_attendance_rate` is computed across the *membership's whole
/// history*, not just this session - the controller groups every attendance
/// row for the membership, not only the ones on this date. Label it as the
/// class's overall rate rather than "today's attendance".
class TrainerDaySession {
  final int sessionId;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final int membershipId;
  final String membershipName;
  final String? sportName;
  final double attendanceRate;
  final List<TrainerSessionPlayer> players;

  const TrainerDaySession({
    required this.sessionId,
    required this.membershipId,
    required this.membershipName,
    this.sessionDate = '',
    this.startTime = '',
    this.endTime = '',
    this.sportName,
    this.attendanceRate = 0,
    this.players = const [],
  });

  String get timeLabel => AppDate.timeRange(startTime, endTime);
  String get startLabel => AppDate.time(startTime, fallback: '');
  String get whenLabel => AppDate.friendlySession(sessionDate, startTime, endTime);

  /// Mirrors `MembershipSession::ATTENDANCE_GRACE_MINUTES` on the server.
  /// Kept in step so the home page never offers a scan the API will reject.
  static const int attendanceGraceMinutes = 30;

  DateTime? _at(String time) {
    if (sessionDate.isEmpty || time.isEmpty) return null;
    return DateTime.tryParse('${sessionDate.split('T').first} $time');
  }

  DateTime? get startsAt => _at(startTime);
  DateTime? get endsAt => _at(endTime);

  /// Whether the API would currently accept attendance for this session.
  /// Used to decide which class a home-page scan belongs to.
  bool get isOpenForAttendance {
    final start = startsAt;
    final end = endsAt;
    if (start == null || end == null) return false;

    final now = DateTime.now();
    const grace = Duration(minutes: attendanceGraceMinutes);
    return now.isAfter(start.subtract(grace)) && now.isBefore(end.add(grace));
  }

  factory TrainerDaySession.fromJson(Map<String, dynamic> json) {
    return TrainerDaySession(
      sessionId: J.asInt(json['session_id']),
      sessionDate: J.asString(json['session_date']),
      startTime: J.asString(json['start_time']),
      endTime: J.asString(json['end_time']),
      membershipId: J.asInt(json['membership_id']),
      membershipName: J.asString(json['membership_name']),
      sportName: J.asStringOrNull(json['sport_name']),
      attendanceRate: J.asDouble(json['total_attendance_rate']),
      players: J.list(json['players'], TrainerSessionPlayer.fromJson),
    );
  }
}

class TrainerSessionPlayer {
  /// This is the **user** id, despite the `player_id` key - the controller
  /// reads it off the enrollment's user. It is the value the attendance
  /// endpoints expect as `user_id`.
  final int userId;
  final String name;
  final String? email;
  final double attendanceRate;

  const TrainerSessionPlayer({
    required this.userId,
    required this.name,
    this.email,
    this.attendanceRate = 0,
  });

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  factory TrainerSessionPlayer.fromJson(Map<String, dynamic> json) {
    return TrainerSessionPlayer(
      userId: J.asInt(json['player_id']),
      name: J.asString(json['player_name']),
      email: J.asStringOrNull(json['player_email']),
      attendanceRate: J.asDouble(json['attendance_rate']),
    );
  }
}
