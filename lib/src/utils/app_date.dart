import 'package:easy_localization/easy_localization.dart';
// material, not widgets: TimeOfDay (used by apiTime / toTimeOfDay for the
// reschedule pickers) lives in material.dart, not in the widgets layer.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:tabala/src/theme/theme_signal.dart';

/// Turns the raw date/time strings the Laravel API sends into something a
/// human wants to read.
///
/// The API is not consistent about shape, because different resources build
/// their values in different ways, so this is the one place that knows all
/// of them:
///
/// | Shape                            | Where it comes from                     |
/// |----------------------------------|-----------------------------------------|
/// | `2026-08-01T10:00:00.000000Z`    | Carbon casts: created_at, paid_at,      |
/// |                                  | start_date, end_date, qr_regenerated_at |
/// | `2026-08-01 00:00:00`            | HomepageSessionResource.session_date,   |
/// |                                  | player attendance `date` (raw column)   |
/// | `2026-08-01`                     | MembershipSessionResource.session_date, |
/// |                                  | MembershipScheduleResource.specific_date|
/// | `18:00:00` or `18:00`            | start_time / end_time (TIME columns)    |
/// | `2026-08`                        | KPI / salary `period`                   |
///
/// Two rules the UI relies on:
///
/// * **The trailing `Z` never reaches the screen.** A value ending in `Z` is
///   UTC; [parse] converts it to the device's local zone before anything is
///   formatted. Riyadh is UTC+3, so a session the API reports at
///   `2026-08-01T15:00:00Z` must render as 6:00 PM, not 3:00 PM, and
///   certainly not as the raw string.
/// * **Dates with no zone are read as local.** `2026-08-01` is a calendar
///   date, not an instant; shifting it by a timezone offset would move a
///   Thursday session onto Wednesday for anyone west of UTC.
class AppDate {
  AppDate._();

  static String get _localeTag => ThemeSignal.isArabic ? 'ar' : 'en';

  // ── Parsing ────────────────────────────────────────────────────────────

  /// Parses any of the shapes above. Returns null rather than throwing, so
  /// a malformed value degrades to a dash on screen instead of taking the
  /// whole list down.
  static DateTime? parse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.isUtc ? value.toLocal() : value;

    var raw = value.toString().trim();
    if (raw.isEmpty || raw == 'null') return null;

    // `2026-08` (period) -> first of that month.
    if (RegExp(r'^\d{4}-\d{2}$').hasMatch(raw)) raw = '$raw-01';

    // A bare time has no date to hang on; callers wanting a time should use
    // [time] instead. Anchor it to today so it can still be formatted.
    if (RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$').hasMatch(raw)) {
      final today = DateTime.now();
      final parts = raw.split(':');
      return DateTime(
        today.year,
        today.month,
        today.day,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
    }

    // `2026-08-01 10:00:00` -> ISO-ish. Dart wants the T separator, but it
    // also accepts a space, so this is mostly belt-and-braces.
    final normalized = raw.contains(' ') && !raw.contains('T')
        ? raw.replaceFirst(' ', 'T')
        : raw;

    final parsed = DateTime.tryParse(normalized);
    if (parsed == null) return null;

    // This is the line that kills the `Z`: an instant expressed in UTC gets
    // moved into the device's zone. Anything without a zone marker is
    // already local as far as Dart is concerned and passes through.
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  // ── Absolute formats ───────────────────────────────────────────────────

  /// `1 Aug 2026` / `١ أغسطس ٢٠٢٦`
  static String date(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;
    return DateFormat('d MMM yyyy', _localeTag).format(dt);
  }

  /// `Sat, 1 Aug` - the shape used on cards where the year is obvious.
  static String dayAndMonth(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;
    return DateFormat('EEE, d MMM', _localeTag).format(dt);
  }

  /// `Saturday` - the club runs a Sunday–Thursday week, so the weekday name
  /// carries real meaning in schedules.
  static String weekday(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;
    return DateFormat('EEEE', _localeTag).format(dt);
  }

  /// `August 2026` - for KPI/salary periods.
  static String monthYear(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;
    return DateFormat('MMMM yyyy', _localeTag).format(dt);
  }

  /// `6:00 PM` / `٦:٠٠ م`. Accepts a bare `18:00:00` as well as a full
  /// timestamp, because that is how the API sends session times.
  static String time(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;
    return DateFormat('h:mm a', _localeTag).format(dt);
  }

  /// `6:00 PM – 7:30 PM`, with the dash flipped for RTL reading order.
  static String timeRange(dynamic start, dynamic end) {
    final from = time(start, fallback: '');
    final to = time(end, fallback: '');
    if (from.isEmpty && to.isEmpty) return '—';
    if (to.isEmpty) return from;
    if (from.isEmpty) return to;
    return '$from – $to';
  }

  /// `1 Aug 2026 · 6:00 PM`
  static String dateTime(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;
    return '${DateFormat('d MMM yyyy', _localeTag).format(dt)} · '
        '${DateFormat('h:mm a', _localeTag).format(dt)}';
  }

  // ── Relative / humanized ───────────────────────────────────────────────

  /// The friendliest label available for a calendar date:
  /// today / tomorrow / yesterday, then a weekday inside the coming week,
  /// then a plain date. Translation keys: `today`, `tomorrow`, `yesterday`.
  static String friendlyDate(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;

    final days = _calendarDaysFromToday(dt);
    if (days == 0) return 'today'.tr();
    if (days == 1) return 'tomorrow'.tr();
    if (days == -1) return 'yesterday'.tr();
    if (days > 1 && days < 7) return DateFormat('EEEE', _localeTag).format(dt);
    if (days < -1 && days > -7) {
      return '${'last'.tr()} ${DateFormat('EEEE', _localeTag).format(dt)}';
    }
    return DateFormat('d MMM yyyy', _localeTag).format(dt);
  }

  /// `Today · 6:00 PM`, `Sunday · 7:00 AM`, `12 Sep 2026 · 8:00 PM`.
  static String friendlyDateTime(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;
    return '${friendlyDate(dt)} · ${DateFormat('h:mm a', _localeTag).format(dt)}';
  }

  /// A date with its time range, as used on session cards:
  /// `Today · 6:00 PM – 7:30 PM`.
  static String friendlySession(dynamic date, dynamic start, dynamic end) {
    final day = friendlyDate(date, fallback: '');
    final range = timeRange(start, end);
    if (day.isEmpty) return range;
    return '$day · $range';
  }

  /// `2 hours ago`, `in 3 days`, `just now`. Translation keys:
  /// `just_now`, `minutes_ago`, `hours_ago`, `days_ago`, `in_minutes`,
  /// `in_hours`, `in_days` - each taking a `{}` placeholder for the count.
  static String relative(dynamic value, {String fallback = '—'}) {
    final dt = parse(value);
    if (dt == null) return fallback;

    final diff = dt.difference(DateTime.now());
    final future = !diff.isNegative;
    final abs = diff.abs();

    if (abs.inMinutes < 1) return 'just_now'.tr();

    if (abs.inMinutes < 60) {
      final n = abs.inMinutes;
      return (future ? 'in_minutes' : 'minutes_ago').tr(args: ['$n']);
    }
    if (abs.inHours < 24) {
      final n = abs.inHours;
      return (future ? 'in_hours' : 'hours_ago').tr(args: ['$n']);
    }
    if (abs.inDays < 30) {
      final n = abs.inDays;
      return (future ? 'in_days' : 'days_ago').tr(args: ['$n']);
    }
    return date(dt);
  }

  /// Whole days remaining until [value], floored at zero. Used for
  /// membership expiry countdowns, where a negative number would read as
  /// nonsense ("-4 days left") rather than "expired".
  static int daysLeft(dynamic value) {
    final dt = parse(value);
    if (dt == null) return 0;
    final days = _calendarDaysFromToday(dt);
    return days < 0 ? 0 : days;
  }

  static bool isPast(dynamic value) {
    final dt = parse(value);
    if (dt == null) return false;
    return dt.isBefore(DateTime.now());
  }

  static bool isToday(dynamic value) => _calendarDaysFromToday(parse(value)) == 0;

  // ── API-facing formats ─────────────────────────────────────────────────

  /// `yyyy-MM-dd` - what the backend's `date` validation rules expect for
  /// query params and reschedule payloads. Always ASCII digits and always
  /// the *local* calendar day, so a user tapping "today" in Riyadh sends
  /// Riyadh's today.
  static String apiDate(DateTime value) =>
      DateFormat('yyyy-MM-dd', 'en').format(value);

  /// `HH:mm` - matches the `date_format:H:i` rule on the reschedule and
  /// session-store requests. Anything else is rejected with a 422.
  static String apiTime(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  /// Parses a `18:00:00` column value back into a TimeOfDay for pickers.
  static TimeOfDay? toTimeOfDay(dynamic value) {
    final raw = value?.toString().trim() ?? '';
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) {
      final dt = parse(value);
      return dt == null ? null : TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    return TimeOfDay(
      hour: int.parse(match.group(1)!),
      minute: int.parse(match.group(2)!),
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────

  /// Difference in *calendar days*, not in 24-hour blocks. 11pm tonight to
  /// 1am tomorrow is two hours but one day, and the label has to say
  /// "tomorrow" for that to make sense to a member reading a schedule.
  static int _calendarDaysFromToday(DateTime? value) {
    if (value == null) return 1 << 30;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final other = DateTime(value.year, value.month, value.day);
    return other.difference(today).inDays;
  }
}
