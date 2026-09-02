import 'json_utils.dart';
import 'membership_schedule_model.dart';

/// `/player/memberships/{membership}` - one membership's public detail plus
/// this player's own relationship to it and its next sessions.
///
/// Built inline by `MembershipDetailCont`, so the shape differs from
/// `MembershipResource`: there is no `sport_id`/`trainer_id`, but there are
/// three flattened trainer fields and the player's `enrollment_status`.
class MembershipDetail {
  final int id;
  final String name;
  final String? description;
  final double price;
  final int? durationDays;
  final String type;
  final String? sportName;

  /// Icon key for the sport; drawn when there is no artwork.
  final String? sportIcon;

  /// The sport's own photo, if the club uploaded one.
  final String? sportImageUrl;

  /// The membership's own artwork, painted behind the hero at low opacity.
  final String? imageUrl;

  final String? trainerName;
  final String? trainerAvatar;
  final double? trainerRating;
  final List<MembershipScheduleModel> schedules;

  /// `not enrolled` | `pending_payment` | `enrolled` | `expired`.
  final String enrollmentStatus;

  final List<UpcomingSession> upcomingSessions;

  const MembershipDetail({
    required this.id,
    required this.name,
    required this.price,
    required this.enrollmentStatus,
    this.description,
    this.durationDays,
    this.type = 'fixed',
    this.sportName,
    this.sportIcon,
    this.sportImageUrl,
    this.imageUrl,
    this.trainerName,
    this.trainerAvatar,
    this.trainerRating,
    this.schedules = const [],
    this.upcomingSessions = const [],
  });

  bool get isFree => price <= 0;
  bool get isEnrolled => enrollmentStatus == 'enrolled';
  bool get isPendingPayment => enrollmentStatus == 'pending_payment';
  bool get hasExpired => enrollmentStatus == 'expired';
  bool get canSubscribe => !isEnrolled && !isPendingPayment;

  String? get trainerRatingLabel => trainerRating?.toStringAsFixed(1);

  factory MembershipDetail.fromJson({
    required Map<String, dynamic> membership,
    required dynamic upcoming,
  }) {
    return MembershipDetail(
      id: J.asInt(membership['id']),
      name: J.asString(membership['name']),
      description: J.asStringOrNull(membership['description']),
      price: J.asDouble(membership['price']),
      durationDays: J.asIntOrNull(membership['duration_days']),
      type: J.asString(membership['type'], fallback: 'fixed'),
      sportName: J.asStringOrNull(membership['sport_name']),
      sportIcon: J.asStringOrNull(membership['sport_icon']),
      sportImageUrl: J.asStringOrNull(membership['sport_image_url']),
      imageUrl: J.asStringOrNull(membership['image_url']),
      trainerName: J.asStringOrNull(membership['trainer_name']),
      trainerAvatar: J.asStringOrNull(membership['trainer_avatar']),
      trainerRating: J.asDoubleOrNull(membership['trainer_rating']),
      schedules: J.list(membership['schedules'], MembershipScheduleModel.fromJson),
      enrollmentStatus:
          J.asString(membership['enrollment_status'], fallback: 'not enrolled'),
      upcomingSessions: J.list(upcoming, UpcomingSession.fromJson),
    );
  }
}

/// The trimmed session rows this endpoint selects: id, date, times, status
/// and nothing else. They *do* carry a real session id, unlike the homepage
/// sessions, so they can be rated once attended.
class UpcomingSession {
  final int id;
  final String sessionDate;
  final String startTime;
  final String endTime;
  final String status;

  const UpcomingSession({
    required this.id,
    required this.sessionDate,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory UpcomingSession.fromJson(Map<String, dynamic> json) {
    return UpcomingSession(
      id: J.asInt(json['id']),
      sessionDate: J.asString(json['session_date']),
      startTime: J.asString(json['start_time']),
      endTime: J.asString(json['end_time']),
      status: J.asString(json['status'], fallback: 'scheduled'),
    );
  }
}
