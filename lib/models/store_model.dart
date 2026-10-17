import 'package:tabala/models/json_utils.dart';

/// A product on the shelf, as the member sees it - no cost price.
class ProductModel {
  final int id;
  final String name;
  final String? nameEn;
  final String? category;
  final String? description;
  final String? imageUrl;
  final double price;
  final int stock;

  const ProductModel({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.nameEn,
    this.category,
    this.description,
    this.imageUrl,
  });

  bool get inStock => stock > 0;

  String localizedName(String lang) =>
      lang == 'en' && (nameEn ?? '').isNotEmpty ? nameEn! : name;

  factory ProductModel.fromJson(Map<String, dynamic> j) => ProductModel(
        id: J.asInt(j['id']),
        name: J.asString(j['name']),
        nameEn: J.asStringOrNull(j['name_en']),
        category: J.asStringOrNull(j['category']),
        description: J.asStringOrNull(j['description']),
        imageUrl: J.asStringOrNull(j['image_url']),
        price: J.asDouble(j['price']),
        stock: J.asInt(j['stock']),
      );
}

class OrderItemModel {
  final String name;
  final double unitPrice;
  final int quantity;
  final double total;

  const OrderItemModel({
    required this.name,
    required this.unitPrice,
    required this.quantity,
    required this.total,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> j) => OrderItemModel(
        name: J.asString(j['name']),
        unitPrice: J.asDouble(j['unit_price']),
        quantity: J.asInt(j['quantity']),
        total: J.asDouble(j['total']),
      );
}

class OrderModel {
  final int id;
  final String number;

  /// pending, paid, delivered, cancelled.
  final String status;
  final double total;
  final String? createdAt;
  final int? invoiceId;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.number,
    required this.status,
    required this.total,
    required this.items,
    this.createdAt,
    this.invoiceId,
  });

  bool get isPending => status == 'pending';

  factory OrderModel.fromJson(Map<String, dynamic> j) => OrderModel(
        id: J.asInt(j['id']),
        number: J.asString(j['number']),
        status: J.asStringOrNull(j['status']) ?? 'pending',
        total: J.asDouble(j['total']),
        createdAt: J.asStringOrNull(j['created_at']),
        invoiceId: J.asIntOrNull(j['invoice_id']),
        items: J.list(j['items'], OrderItemModel.fromJson),
      );
}

/// How to reach the academy: `/contact`.
class ContactModel {
  final String? unifiedNumber;
  final String? phone;
  final String? whatsappUrl;
  final String? email;
  final String? website;
  final String? address;

  const ContactModel({
    this.unifiedNumber,
    this.phone,
    this.whatsappUrl,
    this.email,
    this.website,
    this.address,
  });

  static String? _blank(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();

  factory ContactModel.fromJson(Map<String, dynamic> j) => ContactModel(
        unifiedNumber: _blank(J.asStringOrNull(j['unified_number'])),
        phone: _blank(J.asStringOrNull(j['phone'])),
        whatsappUrl: _blank(J.asStringOrNull(j['whatsapp_url'])),
        email: _blank(J.asStringOrNull(j['email'])),
        website: _blank(J.asStringOrNull(j['website'])),
        address: _blank(J.asStringOrNull(j['address'])),
      );
}
