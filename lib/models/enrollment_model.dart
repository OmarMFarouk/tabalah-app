import 'json_utils.dart';

/// Mirrors `App\Http\Resources\EnrollmentResource`.
///
/// Status is one of `pending_payment` | `active` | `cancelled` | `expired`.
/// Note it is `pending_payment`, never plain `pending` - the enum in the
/// migration has no such value, and matching on the short form silently
/// misclassifies every checkout that has not settled yet.
///
/// Expiry is derived, not stored: the resource computes `is_active` as
/// "status is active AND end_date is still in the future". There is no
/// `expired` string on the row itself, so trust [isActive] rather than
/// comparing dates a second time in the UI.
class EnrollmentModel {
  final int id;
  final int userId;
  final String? userName;
  final int membershipId;
  final String? membershipName;
  final String status;
  final int? paymentId;
  final String? startDate;
  final String? endDate;
  final bool isActive;
  final String? createdAt;

  const EnrollmentModel({
    required this.id,
    required this.userId,
    required this.membershipId,
    required this.status,
    required this.isActive,
    this.userName,
    this.membershipName,
    this.paymentId,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  bool get isAwaitingPayment => status == 'pending_payment';
  bool get isCancelled => status == 'cancelled';

  /// "Expired" in the UI sense: the row still says active but its window has
  /// closed, or the backend already flipped it to `expired`.
  bool get hasLapsed => status == 'expired' || (status == 'active' && !isActive);

  factory EnrollmentModel.fromJson(Map<String, dynamic> json) {
    return EnrollmentModel(
      id: J.asInt(json['id']),
      userId: J.asInt(json['user_id']),
      userName: J.asStringOrNull(json['user_name']),
      membershipId: J.asInt(json['membership_id']),
      membershipName: J.asStringOrNull(json['membership_name']),
      status: J.asString(json['status'], fallback: 'active'),
      paymentId: J.asIntOrNull(json['payment_id']),
      startDate: J.asStringOrNull(json['start_date']),
      endDate: J.asStringOrNull(json['end_date']),
      isActive: J.asBool(json['is_active']),
      createdAt: J.asStringOrNull(json['created_at']),
    );
  }
}
