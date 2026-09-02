/// Coercion helpers used by every `fromJson`.
///
/// These exist because a hard cast like `json['id'] as int` is a crash
/// waiting to happen against this API, in three specific ways:
///
/// * **Decimal columns arrive as strings.** MySQL `decimal(10,2)` comes back
///   through PDO as `"1450.00"`, and Laravel's `decimal:2` cast keeps it a
///   string in JSON. `as double` on that throws; `asDouble` parses it.
/// * **Nullable relations produce nulls.** `trainer_sport_id` is null for a
///   trainer whose sport row was removed, and the original UserModel cast it
///   with a non-nullable `as int`, so loading that trainer's profile threw
///   instead of showing a profile with a blank sport.
/// * **Counts flip between int and string** depending on whether they came
///   from `withCount` or a raw aggregate.
class J {
  J._();

  static int? asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int asInt(dynamic value, {int fallback = 0}) =>
      asIntOrNull(value) ?? fallback;

  static double? asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static double asDouble(dynamic value, {double fallback = 0}) =>
      asDoubleOrNull(value) ?? fallback;

  static String asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final s = value.toString();
    return s == 'null' ? fallback : s;
  }

  static String? asStringOrNull(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return (s.isEmpty || s == 'null') ? null : s;
  }

  static bool asBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    final s = value.toString().toLowerCase();
    if (s == '1' || s == 'true') return true;
    if (s == '0' || s == 'false') return false;
    return fallback;
  }

  /// Safely reads a list of maps out of a response. Laravel serialises an
  /// *empty* Eloquent Collection as `[]` but a keyed one as `{}`, so a value
  /// that is "usually a list" is not always a list.
  static List<Map<String, dynamic>> asMapList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (value is Map) {
      return value.values
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  static Map<String, dynamic> asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  /// Maps a JSON list straight into models.
  static List<T> list<T>(dynamic value, T Function(Map<String, dynamic>) build) =>
      asMapList(value).map(build).toList();
}

/// The `meta` block the paginated player/trainer endpoints attach next to
/// their collection (payments, KPI records, salaries, sessions).
class PageMeta {
  final int currentPage;
  final int lastPage;
  final int total;

  const PageMeta({
    this.currentPage = 1,
    this.lastPage = 1,
    this.total = 0,
  });

  bool get hasMore => currentPage < lastPage;

  int get nextPage => currentPage + 1;

  factory PageMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PageMeta();
    return PageMeta(
      currentPage: J.asInt(json['current_page'], fallback: 1),
      lastPage: J.asInt(json['last_page'], fallback: 1),
      total: J.asInt(json['total']),
    );
  }
}
