/// General constants that don't belong in colors/routes/theme/api config.
class AppConstants {
  AppConstants._();

  static const String appName = 'Tabalah';
  static const String clubName = 'Tabalah Club';

  static const int defaultPageSize = 15;

  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'd MMM yyyy';
  static const String displayTimeFormat = 'HH:mm';

  /// Statuses used across memberships/sessions/attendance/payments - kept
  /// here so views and cubits reference the same literal strings the
  /// backend uses, instead of re-typing them in multiple places.
  static const sessionStatusScheduled = 'scheduled';
  static const sessionStatusOngoing = 'ongoing';
  static const sessionStatusCompleted = 'completed';
  static const sessionStatusCancelled = 'cancelled';

  static const attendancePresent = 'present';
  static const attendanceAbsent = 'absent';
  static const attendanceLate = 'late';
  static const attendanceExcused = 'excused';

  static const paymentPending = 'pending';
  static const paymentSuccess = 'success';
  static const paymentFailed = 'failed';
}
