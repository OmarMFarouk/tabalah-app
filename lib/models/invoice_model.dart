import 'json_utils.dart';

/// An invoice as the member sees it. The printable document lives on the
/// server behind a signed link; this is only what the list needs.
class InvoiceModel {
  final int id;
  final String number;
  final String? issuedAt;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String currency;

  const InvoiceModel({
    required this.id,
    required this.number,
    this.issuedAt,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.total = 0,
    this.currency = 'SAR',
  });

  bool get isTaxed => taxAmount > 0;

  factory InvoiceModel.fromJson(Map<String, dynamic> json) => InvoiceModel(
        id: J.asInt(json['id']),
        number: J.asString(json['number']),
        issuedAt: J.asStringOrNull(json['issued_at']),
        subtotal: J.asDouble(json['subtotal']),
        taxAmount: J.asDouble(json['tax_amount']),
        total: J.asDouble(json['total']),
        currency: J.asString(json['currency'], fallback: 'SAR'),
      );
}
