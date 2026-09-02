import 'json_utils.dart';

/// Mirrors `App\Http\Resources\SportResource`.
class SportModel {
  final int id;
  final String name;
  final String? description;
  final String? image;

  /// Absolute URL for the artwork, built server-side. Prefer this over
  /// [image], which holds a storage-relative path for uploads.
  final String? imageUrl;

  /// Icon key from the shared catalogue; see [SportVisual].
  final String? icon;

  final int? trainersCount;
  final int? membershipsCount;

  const SportModel({
    required this.id,
    required this.name,
    this.description,
    this.image,
    this.imageUrl,
    this.icon,
    this.trainersCount,
    this.membershipsCount,
  });

  factory SportModel.fromJson(Map<String, dynamic> json) {
    return SportModel(
      id: J.asInt(json['id']),
      name: J.asString(json['name']),
      description: J.asStringOrNull(json['description']),
      image: J.asStringOrNull(json['image']),
      imageUrl: J.asStringOrNull(json['image_url']),
      icon: J.asStringOrNull(json['icon']),
      trainersCount: J.asIntOrNull(json['trainers_count']),
      membershipsCount: J.asIntOrNull(json['memberships_count']),
    );
  }
}
