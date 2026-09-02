import 'json_utils.dart';

/// The `payment_source` block PaymentResource nests inside a payment.
class PaymentSourceSummary {
  final int id;
  final String name;
  final String code;
  final String kind;

  const PaymentSourceSummary({
    required this.id,
    required this.name,
    required this.code,
    required this.kind,
  });

  factory PaymentSourceSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSourceSummary(
      id: J.asInt(json['id']),
      name: J.asString(json['name']),
      code: J.asString(json['code']),
      kind: J.asString(json['kind']),
    );
  }
}

class PaymentEnrollmentSummary {
  final int id;
  final int membershipId;
  final String? membershipName;
  final String status;
  final String? startDate;
  final String? endDate;

  const PaymentEnrollmentSummary({
    required this.id,
    required this.membershipId,
    required this.status,
    this.membershipName,
    this.startDate,
    this.endDate,
  });

  factory PaymentEnrollmentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentEnrollmentSummary(
      id: J.asInt(json['id']),
      membershipId: J.asInt(json['membership_id']),
      membershipName: J.asStringOrNull(json['membership_name']),
      status: J.asString(json['status']),
      startDate: J.asStringOrNull(json['start_date']),
      endDate: J.asStringOrNull(json['end_date']),
    );
  }
}

/// Mirrors `App\Http\Resources\PaymentResource`.
///
/// `enrollment`, `payment_source`, `user` and `recorder` are all emitted
/// through `whenLoaded`, so they are absent - not null - whenever the
/// controller did not eager-load them. Reading them defensively is the
/// difference between a payments list that renders and one that throws on
/// the first row recorded by staff.
class PaymentModel {
  final int id;

  /// A UUID the backend generates on create. Shown to members as their
  /// receipt number.
  final String reference;
  final int userId;
  final String? userName;

  /// `enrollment` for self-service checkout; staff-recorded rows may carry
  /// other types.
  final String type;

  final int? paymentSourceId;
  final PaymentSourceSummary? paymentSource;

  /// Legacy free-text column kept for older clients. It mirrors the
  /// source's `code`, so prefer [paymentSource] when it is present.
  final String method;

  final double amount;

  /// Both the migration default and the seeder write `SAR`. Render whatever
  /// the row says rather than assuming riyals - see AppMoney.
  final String currency;

  /// `pending` | `success` | `failed` | `refunded`.
  final String status;
  final String? notes;
  final String? recordedByName;

  final String? paidAt;
  final String? refundedAt;
  final String? createdAt;

  final PaymentEnrollmentSummary? enrollment;

  const PaymentModel({
    required this.id,
    required this.reference,
    required this.userId,
    required this.type,
    required this.method,
    required this.amount,
    required this.currency,
    required this.status,
    this.userName,
    this.paymentSourceId,
    this.paymentSource,
    this.notes,
    this.recordedByName,
    this.paidAt,
    this.refundedAt,
    this.createdAt,
    this.enrollment,
  });

  bool get isPending => status == 'pending';
  bool get isSuccess => status == 'success';
  bool get isFailed => status == 'failed';
  bool get isRefunded => status == 'refunded';

  /// The label the member recognises: the payment method's display name,
  /// falling back to the legacy free-text column.
  String get methodLabel => paymentSource?.name ?? method;

  /// The receipt number as the member should see it.
  ///
  /// References are now short and branded by design — `TBLH-2608-98YHB` —
  /// so they are shown whole. This used to cut everything down to eight
  /// characters, which was right when the column held a 36-character UUID
  /// and is actively wrong now: it would render the new format as
  /// "TBLH-260", which is neither unique nor quotable back to the club.
  ///
  /// Older payments still carry UUIDs, and those are still truncated,
  /// because nobody was ever going to read one of those out anyway.
  String get shortReference {
    if (reference.startsWith('TBLH-')) return reference;

    return reference.length <= 8
        ? reference
        : reference.substring(0, 8).toUpperCase();
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: J.asInt(json['id']),
      reference: J.asString(json['reference']),
      userId: J.asInt(json['user_id']),
      userName: J.asStringOrNull(json['user_name']),
      type: J.asString(json['type'], fallback: 'enrollment'),
      paymentSourceId: J.asIntOrNull(json['payment_source_id']),
      paymentSource: json['payment_source'] is Map
          ? PaymentSourceSummary.fromJson(J.asMap(json['payment_source']))
          : null,
      method: J.asString(json['method'], fallback: 'simulated_gateway'),
      amount: J.asDouble(json['amount']),
      currency: J.asString(json['currency'], fallback: 'SAR'),
      status: J.asString(json['status'], fallback: 'pending'),
      notes: J.asStringOrNull(json['notes']),
      recordedByName: J.asStringOrNull(json['recorded_by_name']),
      paidAt: J.asStringOrNull(json['paid_at']),
      refundedAt: J.asStringOrNull(json['refunded_at']),
      createdAt: J.asStringOrNull(json['created_at']),
      enrollment: json['enrollment'] is Map
          ? PaymentEnrollmentSummary.fromJson(J.asMap(json['enrollment']))
          : null,
    );
  }
}
