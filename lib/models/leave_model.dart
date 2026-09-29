import 'json_utils.dart';

/// A request to be away, as the person asking for it sees it.
///
/// Only annual leave draws on the yearly balance; sick, emergency and
/// unpaid days are recorded and count against nothing.
class LeaveRequest {
  final int id;
  final String type;
  final String typeLabel;
  final String? startDate;
  final String? endDate;
  final int days;
  final String? reason;
  final String status;
  final String? reviewerName;
  final String? reviewNote;

  const LeaveRequest({
    required this.id,
    required this.type,
    required this.typeLabel,
    this.startDate,
    this.endDate,
    this.days = 0,
    this.reason,
    this.status = 'pending',
    this.reviewerName,
    this.reviewNote,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) => LeaveRequest(
        id: J.asInt(json['id']),
        type: J.asStringOrNull(json['type']) ?? 'annual',
        typeLabel: J.asString(json['type_label']),
        startDate: J.asStringOrNull(json['start_date']),
        endDate: J.asStringOrNull(json['end_date']),
        days: J.asInt(json['days']),
        reason: J.asStringOrNull(json['reason']),
        status: J.asStringOrNull(json['status']) ?? 'pending',
        reviewerName: J.asStringOrNull(json['reviewer_name']),
        reviewNote: J.asStringOrNull(json['review_note']),
      );

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
}

/// What the person has, has spent, and has left this year.
class LeaveBalance {
  final int entitlement;
  final int used;
  final int remaining;

  const LeaveBalance({this.entitlement = 0, this.used = 0, this.remaining = 0});

  factory LeaveBalance.fromJson(Map<String, dynamic> json) => LeaveBalance(
        entitlement: J.asInt(json['entitlement']),
        used: J.asInt(json['used']),
        remaining: J.asInt(json['remaining']),
      );
}

class LeavesPage {
  final LeaveBalance balance;
  final List<LeaveRequest> items;

  /// `{key: arabic label}`, straight from the server so the two cannot
  /// disagree about which kinds exist.
  final Map<String, String> types;

  const LeavesPage({
    required this.balance,
    required this.items,
    this.types = const {},
  });
}
