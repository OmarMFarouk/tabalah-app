import 'package:tabala/src/utils/app_date.dart';

import 'json_utils.dart';

enum ScheduleType { weekly, date }

/// Mirrors `App\Http\Resources\MembershipScheduleResource`.
///
/// A schedule is either a recurring weekday slot (`schedule_type: weekly`,
/// with `day_of_week`) or a one-off calendar date (`schedule_type: date`,
/// with `specific_date`). The two columns are mutually exclusive in
/// practice, which is why both are nullable here.
class MembershipScheduleModel {
  final int id;
  final int membershipId;
  final ScheduleType scheduleType;

  /// Lowercase English weekday as stored, e.g. `sunday`. The club runs a
  /// Sunday–Thursday week.
  final String? dayOfWeek;

  /// `yyyy-MM-dd`.
  final String? specificDate;

  /// `HH:mm:ss` from a TIME column.
  final String startTime;
  final String endTime;

  const MembershipScheduleModel({
    required this.id,
    required this.membershipId,
    required this.scheduleType,
    required this.startTime,
    required this.endTime,
    this.dayOfWeek,
    this.specificDate,
  });

  bool get isWeekly => scheduleType == ScheduleType.weekly;

  /// The humanized time window, e.g. `6:00 PM – 7:30 PM`.
  String get timeLabel => AppDate.timeRange(startTime, endTime);

  /// The day part on its own: a translated weekday for recurring slots, a
  /// formatted date for one-offs.
  String get dayLabel {
    if (isWeekly) {
      final key = (dayOfWeek ?? '').toLowerCase();
      return key.isEmpty ? '' : _weekdayLabel(key);
    }
    return AppDate.date(specificDate, fallback: '');
  }

  /// `Sunday · 6:00 PM – 7:30 PM`
  String get label {
    final day = dayLabel;
    return day.isEmpty ? timeLabel : '$day · $timeLabel';
  }

  /// Maps the stored English weekday onto a real DateTime so intl can
  /// localize it, rather than shipping a hand-written Arabic lookup table.
  static String _weekdayLabel(String english) {
    const order = {
      'monday': 1,
      'tuesday': 2,
      'wednesday': 3,
      'thursday': 4,
      'friday': 5,
      'saturday': 6,
      'sunday': 7,
    };
    final weekday = order[english];
    if (weekday == null) return english;

    // Any week works; pick the current one and walk to the right weekday.
    final now = DateTime.now();
    final anchor = now.subtract(Duration(days: now.weekday - weekday));
    return AppDate.weekday(anchor);
  }

  factory MembershipScheduleModel.fromJson(Map<String, dynamic> json) {
    return MembershipScheduleModel(
      id: J.asInt(json['id']),
      membershipId: J.asInt(json['membership_id']),
      scheduleType:
          json['schedule_type'] == 'date' ? ScheduleType.date : ScheduleType.weekly,
      dayOfWeek: J.asStringOrNull(json['day_of_week']),
      specificDate: J.asStringOrNull(json['specific_date']),
      startTime: J.asString(json['start_time']),
      endTime: J.asString(json['end_time']),
    );
  }
}
