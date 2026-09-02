import 'json_utils.dart';

/// Mirrors `App\Http\Resources\UserResource`.
///
/// Two things about that resource shape the model:
///
/// 1. **It is the only resource that prefixes its keys.** Every other
///    resource in the API uses bare keys (`id`, `name`, `status`);
///    UserResource emits `user_id`, `user_name`, `user_role` and so on. Do
///    not apply this prefixing anywhere else.
/// 2. **The profile blocks are conditional.** A user's `role` column and
///    their profile row can legitimately be out of step - a freshly
///    promoted trainer, an admin created without an employee record - so
///    `player` / `trainer` / `employee` are each present only when the row
///    exists. Every consumer must treat them as nullable.
class UserModel {
  final int id;
  final String name;
  final String? avatar;

  /// Ready-to-render absolute URL, whether the avatar was uploaded to local
  /// storage or set to an external URL. Prefer this over [avatar]: the raw
  /// column holds a storage-relative path for uploads, which is not
  /// loadable by the app on its own.
  final String? avatarUrl;

  final String role;
  final String email;
  final String? phone;
  final bool isOnline;

  /// `user_joined_at` - an ISO timestamp; format it through AppDate.
  final String? joinedAt;

  /// `user_last_seen` - already humanized server-side by Carbon's
  /// `diffForHumans()`, or the literal string "Never". It is *not* a
  /// timestamp, so do not try to parse it.
  final String? lastSeen;

  final PlayerProfile? player;
  final TrainerProfile? trainer;
  final EmployeeProfile? employee;

  const UserModel({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.phone,
    this.avatar,
    this.avatarUrl,
    this.isOnline = false,
    this.joinedAt,
    this.lastSeen,
    this.player,
    this.trainer,
    this.employee,
  });

  bool get isPlayer => role == 'player';
  bool get isTrainer => role == 'trainer';
  bool get isAdmin => role == 'admin' || role == 'super-admin';
  bool get isStaff => isAdmin || role == 'employee';

  /// First letter for avatar placeholders, safe on an empty name.
  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  /// A displayable image URL, or null when the placeholder should be used.
  String? get photo {
    final url = avatarUrl ?? avatar;
    if (url == null || url.isEmpty) return null;
    return url.startsWith('http') ? url : null;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: J.asInt(json['user_id']),
      name: J.asString(json['user_name']),
      avatar: J.asStringOrNull(json['user_avatar']),
      avatarUrl: J.asStringOrNull(json['user_avatar_url']),
      role: J.asString(json['user_role']),
      email: J.asString(json['user_email']),
      phone: J.asStringOrNull(json['user_phone']),
      isOnline: J.asBool(json['user_is_online']),
      joinedAt: J.asStringOrNull(json['user_joined_at']),
      lastSeen: J.asStringOrNull(json['user_last_seen']),
      player: json['player'] != null ? PlayerProfile.fromJson(J.asMap(json['player'])) : null,
      trainer: json['trainer'] != null ? TrainerProfile.fromJson(J.asMap(json['trainer'])) : null,
      employee:
          json['employee'] != null ? EmployeeProfile.fromJson(J.asMap(json['employee'])) : null,
    );
  }

  UserModel copyWith({String? name, String? avatarUrl}) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      role: role,
      email: email,
      phone: phone,
      avatar: avatar,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline,
      joinedAt: joinedAt,
      lastSeen: lastSeen,
      player: player,
      trainer: trainer,
      employee: employee,
    );
  }
}

class PlayerProfile {
  final int id;

  /// The player's stable identity QR. A trainer scans this to mark them
  /// present without picking them off a list. It is a UUID; the backend
  /// validates it with `required|uuid`.
  final String? qrToken;

  /// The code a parent types into the app to watch this player read-only.
  /// Shown to the player themselves so they can hand it over; there is
  /// nothing here a guardian could not already see.
  /// The member's club id — `TBLH-00042`. What is on their card and what
  /// they give at the desk.
  final String? clubId;

  final String? guardianCode;

  /// False once the club has switched the parent portal off for this
  /// player. The code still exists, it just stops being accepted.
  final bool guardianAccessEnabled;

  final String? emergencyContact;
  final num? weight;
  final num? height;

  const PlayerProfile({
    required this.id,
    this.qrToken,
    this.clubId,
    this.guardianCode,
    this.guardianAccessEnabled = true,
    this.emergencyContact,
    this.weight,
    this.height,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    return PlayerProfile(
      id: J.asInt(json['player_id']),
      qrToken: J.asStringOrNull(json['player_qr_token']),
      clubId: J.asStringOrNull(json['player_club_id'] ?? json['club_id']),
      guardianCode: J.asStringOrNull(json['player_guardian_code']),
      guardianAccessEnabled:
          json['player_guardian_access_enabled'] == null
          ? true
          : J.asBool(json['player_guardian_access_enabled']),
      emergencyContact: J.asStringOrNull(json['player_emergency_contact']),
      // Both columns are decimals, so they arrive as strings.
      weight: J.asDoubleOrNull(json['player_weight']),
      height: J.asDoubleOrNull(json['player_height']),
    );
  }
}

class TrainerProfile {
  final int id;

  /// Nullable on purpose. `trainer_sport_id` comes from `$user->trainer->
  /// sport?->id`, so it is null whenever the trainer has no sport attached -
  /// casting it to a non-null int made the whole trainer profile screen
  /// throw for those accounts.
  final int? sportId;
  final String sportName;
  final String? bio;
  final String status;
  final double? ratingAvg;

  const TrainerProfile({
    required this.id,
    required this.status,
    this.sportId,
    this.sportName = '',
    this.bio,
    this.ratingAvg,
  });

  /// `4.5` -> "4.5", null -> null. Ratings are decimal(5,2), not integers.
  String? get ratingLabel => ratingAvg?.toStringAsFixed(1);

  factory TrainerProfile.fromJson(Map<String, dynamic> json) {
    return TrainerProfile(
      id: J.asInt(json['trainer_id']),
      sportId: J.asIntOrNull(json['trainer_sport_id']),
      sportName: J.asString(json['trainer_sport_name']),
      bio: J.asStringOrNull(json['trainer_bio']),
      status: J.asString(json['trainer_status'], fallback: 'active'),
      ratingAvg: J.asDoubleOrNull(json['trainer_rating_avg']),
    );
  }
}

class EmployeeProfile {
  final int id;
  final String? position;
  final double? salary;
  final String status;

  const EmployeeProfile({
    required this.id,
    required this.status,
    this.position,
    this.salary,
  });

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    return EmployeeProfile(
      id: J.asInt(json['employee_id']),
      position: J.asStringOrNull(json['employee_position']),
      salary: J.asDoubleOrNull(json['employee_salary']),
      status: J.asString(json['employee_status'], fallback: 'active'),
    );
  }
}
