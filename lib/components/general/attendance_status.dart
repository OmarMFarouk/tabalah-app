import 'package:easy_localization/easy_localization.dart';

/// The four attendance states the backend supports (see the
/// `player_attendances.status` enum). Kept as a real enum rather than raw
/// strings so the UI can switch over it exhaustively.
///
/// Note the API also uses a fifth *pseudo* value, `not_marked`, on the
/// trainer's session detail roster. It is not a DB enum member and must
/// never be sent back - it only means "no attendance row exists yet".
enum AttendanceStatus { present, absent, late, excused }

extension AttendanceStatusX on AttendanceStatus {
  String get apiValue => name;

  String get label => name.tr();

  static AttendanceStatus fromApiValue(String value) {
    return AttendanceStatus.values.firstWhere(
      (s) => s.apiValue == value,
      orElse: () => AttendanceStatus.present,
    );
  }

  static bool isMarked(String value) => value != 'not_marked' && value.isNotEmpty;
}
