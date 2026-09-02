import 'json_utils.dart';

/// `/player/sports` - every sport with its *active* memberships, each one
/// annotated with this player's own relationship to it.
///
/// The controller builds these arrays inline rather than through a resource
/// class, so the keys below are the authoritative list; there is no
/// `sport_id`, `trainer_name` or `status` on the membership entries.
class SportWithPlans {
  final int id;
  final String name;
  final String? description;

  /// Icon key from the shared catalogue; see [SportVisual].
  final String? icon;

  /// Uploaded artwork. When present it replaces the icon, which is the
  /// precedence the admin panel promises when it offers both.
  final String? imageUrl;

  final List<MembershipPlan> plans;

  const SportWithPlans({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.imageUrl,
    this.plans = const [],
  });

  bool get hasPlans => plans.isNotEmpty;

  /// The cheapest plan, used for the "from X SAR" line on the sport header.
  MembershipPlan? get cheapest {
    if (plans.isEmpty) return null;
    final sorted = [...plans]..sort((a, b) => a.price.compareTo(b.price));
    return sorted.first;
  }

  bool get isJoined => plans.any((p) => p.isEnrolled);

  factory SportWithPlans.fromJson(Map<String, dynamic> json) {
    return SportWithPlans(
      id: J.asInt(json['id']),
      name: J.asString(json['name']),
      description: J.asStringOrNull(json['description']),
      icon: J.asStringOrNull(json['icon']),
      imageUrl: J.asStringOrNull(json['image_url']),
      plans: J.list(json['memberships'], MembershipPlan.fromJson),
    );
  }
}

/// One membership as offered on the sports screen.
class MembershipPlan {
  final int id;
  final String name;
  final double price;
  final int? durationDays;
  final int? maxAttendees;
  final String type;
  final String? description;

  /// The plan's own artwork, used as a faded backdrop on its card.
  final String? imageUrl;

  /// `not enrolled` (with a space) | `pending_payment` | `enrolled` |
  /// `expired`. Computed per-player by the controller from their latest
  /// enrollment for this membership.
  final String enrollmentStatus;

  const MembershipPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.enrollmentStatus,
    this.durationDays,
    this.maxAttendees,
    this.type = 'fixed',
    this.description,
    this.imageUrl,
  });

  bool get isFree => price <= 0;
  bool get isEnrolled => enrollmentStatus == 'enrolled';
  bool get isPendingPayment => enrollmentStatus == 'pending_payment';
  bool get hasExpired => enrollmentStatus == 'expired';

  /// Only these two states let the member start a new checkout; the backend
  /// rejects a second active enrollment with a 422.
  bool get canSubscribe => !isEnrolled && !isPendingPayment;

  factory MembershipPlan.fromJson(Map<String, dynamic> json) {
    return MembershipPlan(
      id: J.asInt(json['id']),
      name: J.asString(json['name']),
      price: J.asDouble(json['price']),
      durationDays: J.asIntOrNull(json['duration_days']),
      maxAttendees: J.asIntOrNull(json['max_attendees']),
      type: J.asString(json['type'], fallback: 'fixed'),
      description: J.asStringOrNull(json['description']),
      imageUrl: J.asStringOrNull(json['image_url']),
      enrollmentStatus: J.asString(json['enrollment_status'], fallback: 'not enrolled'),
    );
  }
}
