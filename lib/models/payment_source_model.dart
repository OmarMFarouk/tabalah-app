import 'json_utils.dart';

/// Mirrors `App\Http\Resources\PaymentSourceResource`.
///
/// The club's catalogue of ways to take money. Every payment points at one
/// of these. The player-facing endpoint (`/player/payment-sources`) already
/// filters to `active()->online()`, so anything the app receives from it is
/// safe to offer at checkout - the `offline` kinds (cash at the desk, POS
/// terminal, bank transfer) are recorded by staff in the admin panel and
/// must never appear as a self-service choice.
class PaymentSourceModel {
  final int id;
  final String name;

  /// Stable machine key (`mada`, `apple_pay`, `cash`, ...). Match on this,
  /// not on [name], which is display text and may be localized or renamed.
  final String code;
  final String? description;

  /// `online` | `offline`.
  final String kind;
  final bool isActive;
  final bool isDefault;
  final int sortOrder;

  const PaymentSourceModel({
    required this.id,
    required this.name,
    required this.code,
    required this.kind,
    this.description,
    this.isActive = true,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  bool get isOnline => kind == 'online';

  factory PaymentSourceModel.fromJson(Map<String, dynamic> json) {
    return PaymentSourceModel(
      id: J.asInt(json['id']),
      name: J.asString(json['name']),
      code: J.asString(json['code']),
      description: J.asStringOrNull(json['description']),
      kind: J.asString(json['kind'], fallback: 'online'),
      isActive: J.asBool(json['is_active'], fallback: true),
      isDefault: J.asBool(json['is_default']),
      sortOrder: J.asInt(json['sort_order']),
    );
  }
}
