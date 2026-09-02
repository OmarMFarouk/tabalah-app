import 'package:tabala/src/utils/app_date.dart';

import 'json_utils.dart';

/// The player's `/player/homepage` payload, typed.
///
/// The endpoint wraps everything in a single `homepage` object built by
/// `HomepageResource`, which nests three collections. Each has its own
/// resource with its own key shape, so each gets its own model here rather
/// than being squeezed into the general-purpose Membership/Session models -
/// they carry different fields (the player's own pivot dates, a computed
/// attendance rate) and are missing others (a session id, a membership id).
class PlayerHomeData {
  final List<HomeMembership> memberships;
  final List<HomeSession> todaySessions;
  final List<HomeTrainer> trainers;

  const PlayerHomeData({
    this.memberships = const [],
    this.todaySessions = const [],
    this.trainers = const [],
  });

  bool get isEmpty => memberships.isEmpty && todaySessions.isEmpty && trainers.isEmpty;

  /// Average attendance across every membership the player holds - the
  /// headline number on the home hero.
  double get overallAttendanceRate {
    if (memberships.isEmpty) return 0;
    final sum = memberships.fold<double>(0, (acc, m) => acc + m.attendanceRate);
    return sum / memberships.length;
  }

  /// The membership closest to expiring, for the renewal nudge.
  HomeMembership? get soonestExpiring {
    final dated = memberships.where((m) => m.daysLeft != null).toList()
      ..sort((a, b) => a.daysLeft!.compareTo(b.daysLeft!));
    return dated.isEmpty ? null : dated.first;
  }

  factory PlayerHomeData.fromJson(Map<String, dynamic> json) {
    return PlayerHomeData(
      memberships: J.list(json['memberships'], HomeMembership.fromJson),
      todaySessions: J.list(json['today_sessions'], HomeSession.fromJson),
      trainers: J.list(json['trainers'], HomeTrainer.fromJson),
    );
  }
}

/// From `HomepageMembershipResource`. Richer than the plain membership
/// resource: it reads the *player's own* enrollment pivot for start/end
/// dates, and carries the attendance rate the controller computed.
class HomeMembership {
  final int id;
  final String name;
  final String? sportName;

  /// Icon key for the sport, drawn on the card when there is no artwork.
  final String? sportIcon;

  /// The membership's own artwork, painted behind the card at low opacity.
  /// Null for a membership the club never gave a picture, which is the
  /// common case - the card falls back to the plain club gradient.
  final String? imageUrl;

  final String? startDate;
  final String? endDate;

  /// Computed server-side with `floor(now()->diffInDays(end_date))`. Note
  /// Carbon's `diffInDays` is absolute, so a membership that expired last
  /// week reports a positive number here - always cross-check against
  /// [hasExpired] before showing it as "days remaining".
  final int? daysLeft;
  final int? hoursLeft;
  final double attendanceRate;

  const HomeMembership({
    required this.id,
    required this.name,
    this.sportName,
    this.sportIcon,
    this.imageUrl,
    this.startDate,
    this.endDate,
    this.daysLeft,
    this.hoursLeft,
    this.attendanceRate = 0,
  });

  bool get hasExpired => endDate != null && AppDate.isPast(endDate);

  /// The trustworthy countdown: recomputed locally from the end date rather
  /// than taken from the server's absolute diff.
  int get remainingDays => hasExpired ? 0 : AppDate.daysLeft(endDate);

  bool get isExpiringSoon => !hasExpired && remainingDays <= 7;

  String get endsLabel => AppDate.friendlyDate(endDate, fallback: '—');

  factory HomeMembership.fromJson(Map<String, dynamic> json) {
    return HomeMembership(
      id: J.asInt(json['id']),
      name: J.asString(json['name']),
      sportName: J.asStringOrNull(json['sport_name']),
      sportIcon: J.asStringOrNull(json['sport_icon']),
      imageUrl: J.asStringOrNull(json['image_url']),
      startDate: J.asStringOrNull(json['start_date']),
      endDate: J.asStringOrNull(json['end_date']),
      daysLeft: J.asIntOrNull(json['days_left']),
      hoursLeft: J.asIntOrNull(json['hours_left']),
      attendanceRate: J.asDouble(json['attendance_rate']),
    );
  }
}

/// From `HomepageSessionResource`.
///
/// This resource carries **no ids at all** - not the session's, not the
/// membership's - so these cards are display-only. Anything that needs to
/// navigate into a session has to come from `/trainer/sessions` or the
/// membership detail endpoint instead.
class HomeSession {
  final String? sportName;
  final String? sportIcon;
  final String? membershipName;
  final String? trainerName;
  final String? trainerAvatar;
  final String startTime;
  final String endTime;
  final String sessionDate;

  const HomeSession({
    this.sportName,
    this.sportIcon,
    this.membershipName,
    this.trainerName,
    this.trainerAvatar,
    this.startTime = '',
    this.endTime = '',
    this.sessionDate = '',
  });

  String get timeLabel => AppDate.timeRange(startTime, endTime);

  String get startLabel => AppDate.time(startTime, fallback: '');

  String get title => membershipName ?? sportName ?? '';

  factory HomeSession.fromJson(Map<String, dynamic> json) {
    return HomeSession(
      sportName: J.asStringOrNull(json['sport_name']),
      sportIcon: J.asStringOrNull(json['sport_icon']),
      membershipName: J.asStringOrNull(json['membership_name']),
      trainerName: J.asStringOrNull(json['trainer_name']),
      trainerAvatar: J.asStringOrNull(json['trainer_avatar']),
      startTime: J.asString(json['start_time']),
      endTime: J.asString(json['end_time']),
      sessionDate: J.asString(json['session_date']),
    );
  }
}

/// From `HomepageTrainerResource`. `trainer_id` is the trainers-table id,
/// not the user id - it cannot be passed to endpoints that expect a user id.
class HomeTrainer {
  final int trainerId;
  final String name;
  final String? avatar;
  final String? sportName;
  final String? sportIcon;
  final double? ratingAvg;

  const HomeTrainer({
    required this.trainerId,
    required this.name,
    this.avatar,
    this.sportName,
    this.sportIcon,
    this.ratingAvg,
  });

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  String? get ratingLabel => ratingAvg == null ? null : ratingAvg!.toStringAsFixed(1);

  factory HomeTrainer.fromJson(Map<String, dynamic> json) {
    return HomeTrainer(
      trainerId: J.asInt(json['trainer_id']),
      name: J.asString(json['trainer_name']),
      avatar: J.asStringOrNull(json['trainer_avatar']),
      sportName: J.asStringOrNull(json['sport_name']),
      sportIcon: J.asStringOrNull(json['sport_icon']),
      ratingAvg: J.asDoubleOrNull(json['rating_avg']),
    );
  }
}
