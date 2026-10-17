import 'json_utils.dart';

/// Mirrors `App\Http\Resources\SalaryResource` - `/trainer/salaries` returns
/// the signed-in user's own rows only.
class SalaryModel {
  final int id;
  final int userId;
  final String? userName;
  final double amount;

  /// `YYYY-MM`.
  final String period;
  final String? createdAt;

  /// The breakdown from the payroll run. Older rows only have [amount],
  /// which is then the whole of it.
  final double allowances;
  final double overtimeAmount;
  final double bonus;
  final double deductions;
  final double net;
  final String status;
  final String? statusLabel;
  final String? paidAt;

  const SalaryModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.period,
    this.userName,
    this.createdAt,
    this.allowances = 0,
    this.overtimeAmount = 0,
    this.bonus = 0,
    this.deductions = 0,
    this.net = 0,
    this.status = 'paid',
    this.statusLabel,
    this.paidAt,
  });

  /// What actually lands in the account.
  double get takeHome => net > 0 ? net : amount;
  bool get isPaid => status == 'paid';

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    return SalaryModel(
      id: J.asInt(json['id']),
      userId: J.asInt(json['user_id']),
      userName: J.asStringOrNull(json['user_name']),
      amount: J.asDouble(json['amount']),
      period: J.asString(json['period']),
      createdAt: J.asStringOrNull(json['created_at']),
      allowances: J.asDouble(json['allowances']),
      overtimeAmount: J.asDouble(json['overtime_amount']),
      bonus: J.asDouble(json['bonus']),
      deductions: J.asDouble(json['deductions']),
      net: J.asDouble(json['net']),
      status: J.asStringOrNull(json['status']) ?? 'paid',
      statusLabel: J.asStringOrNull(json['status_label']),
      paidAt: J.asStringOrNull(json['paid_at']),
    );
  }
}
