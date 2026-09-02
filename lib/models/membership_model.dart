import 'json_utils.dart';
import 'membership_schedule_model.dart';

/// Mirrors `App\Http\Resources\MembershipResource`.
///
/// `price` is a `decimal(10,2)`, so it comes over the wire as the string
/// `"1450.00"` rather than a JSON number - hence the parse rather than a
/// cast. `schedules` and `enrollments_count` are conditional
/// (`whenLoaded` / `whenCounted`) and are simply absent when the controller
/// did not ask for them.
class MembershipModel {
  final int id;
  final String name;
  final String? description;
  final int trainerId;
  final String? trainerName;
  final int sportId;
  final String? sportName;
  final String? sportIcon;

  /// The membership's card artwork, or null to fall back to the gradient.
  final String? imageUrl;

  final double price;

  /// Null means an open-ended membership; the backend treats that as a
  /// hundred-year window when it computes an end date.
  final int? durationDays;

  /// Null means uncapped. When set, the backend refuses a new enrollment
  /// once this many are active.
  final int? maxAttendees;

  /// `fixed` | `scheduled`.
  final String type;

  /// `active` | `inactive`. Only active memberships can be enrolled in -
  /// checkout throws a 422 otherwise.
  final String status;

  final List<MembershipScheduleModel> schedules;
  final int? enrollmentsCount;

  const MembershipModel({
    required this.id,
    required this.name,
    required this.trainerId,
    required this.sportId,
    required this.price,
    required this.type,
    required this.status,
    this.description,
    this.trainerName,
    this.sportName,
    this.sportIcon,
    this.imageUrl,
    this.durationDays,
    this.maxAttendees,
    this.schedules = const [],
    this.enrollmentsCount,
  });

  bool get isFree => price <= 0;
  bool get isActive => status == 'active';

  /// How many seats are left, or null when the membership is uncapped or
  /// the count was not loaded.
  int? get seatsLeft {
    if (maxAttendees == null || enrollmentsCount == null) return null;
    final left = maxAttendees! - enrollmentsCount!;
    return left < 0 ? 0 : left;
  }

  factory MembershipModel.fromJson(Map<String, dynamic> json) {
    return MembershipModel(
      id: J.asInt(json['id']),
      name: J.asString(json['name']),
      description: J.asStringOrNull(json['description']),
      trainerId: J.asInt(json['trainer_id']),
      trainerName: J.asStringOrNull(json['trainer_name']),
      sportId: J.asInt(json['sport_id']),
      sportName: J.asStringOrNull(json['sport_name']),
      sportIcon: J.asStringOrNull(json['sport_icon']),
      imageUrl: J.asStringOrNull(json['image_url']),
      price: J.asDouble(json['price']),
      durationDays: J.asIntOrNull(json['duration_days']),
      maxAttendees: J.asIntOrNull(json['max_attendees']),
      type: J.asString(json['type'], fallback: 'fixed'),
      status: J.asString(json['status'], fallback: 'active'),
      schedules: J.list(json['schedules'], MembershipScheduleModel.fromJson),
      enrollmentsCount: J.asIntOrNull(json['enrollments_count']),
    );
  }
}
