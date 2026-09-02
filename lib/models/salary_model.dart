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

  const SalaryModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.period,
    this.userName,
    this.createdAt,
  });

  factory SalaryModel.fromJson(Map<String, dynamic> json) {
    return SalaryModel(
      id: J.asInt(json['id']),
      userId: J.asInt(json['user_id']),
      userName: J.asStringOrNull(json['user_name']),
      amount: J.asDouble(json['amount']),
      period: J.asString(json['period']),
      createdAt: J.asStringOrNull(json['created_at']),
    );
  }
}
