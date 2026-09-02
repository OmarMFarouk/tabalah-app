import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/src/colors/app_colors.dart';

/// One place that knows what every backend status string looks like on
/// screen. The literals below are exactly the enum values the migrations
/// declare - if a value is missing here the UI degrades to grey rather than
/// throwing, but the intent is that this table stays in step with the DB.
class StatusUi {
  StatusUi._();

  // ── Attendance: present | absent | late | excused ──────────────────────
  //
  // `excused` is easy to forget: it was added alongside the other three and
  // is a distinct outcome, not a flavour of absent, so it gets its own blue
  // rather than being lumped in with the reds.

  static Color attendance(String status) {
    switch (status) {
      case 'present':
        return AppColors.greencolor;
      case 'absent':
        return AppColors.redcolor;
      case 'late':
        return AppColors.orangecolor;
      case 'excused':
        return AppColors.bluecolor;
      default:
        return AppColors.greycolor;
    }
  }

  static IconData attendanceIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_rounded;
      case 'absent':
        return Icons.close_rounded;
      case 'late':
        return Icons.schedule_rounded;
      case 'excused':
        return Icons.event_busy_rounded;
      default:
        return Icons.remove_rounded;
    }
  }

  // ── Session: scheduled | ongoing | completed | cancelled ───────────────

  static Color session(String status) {
    switch (status) {
      case 'scheduled':
        return AppColors.bluecolor;
      case 'ongoing':
        return AppColors.primary;
      case 'completed':
        return AppColors.greencolor;
      case 'cancelled':
        return AppColors.redcolor;
      default:
        return AppColors.greycolor;
    }
  }

  static IconData sessionIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.event_available_rounded;
      case 'ongoing':
        return Icons.play_circle_outline_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.event_rounded;
    }
  }

  // ── Payment: pending | success | failed | refunded ─────────────────────

  static Color payment(String status) {
    switch (status) {
      case 'success':
        return AppColors.greencolor;
      case 'pending':
        return AppColors.orangecolor;
      case 'failed':
        return AppColors.redcolor;
      case 'refunded':
        return AppColors.purplecolor;
      default:
        return AppColors.greycolor;
    }
  }

  static IconData paymentIcon(String status) {
    switch (status) {
      case 'success':
        return Icons.check_circle_outline_rounded;
      case 'pending':
        return Icons.hourglass_bottom_rounded;
      case 'failed':
        return Icons.error_outline_rounded;
      case 'refunded':
        return Icons.undo_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  // ── Enrollment: pending_payment | active | cancelled | expired ─────────
  //
  // Note the status is `pending_payment`, not `pending` - the shorter form
  // never appears in the enrollments enum and matching on it silently
  // classifies every pending row as "unknown".

  static Color enrollment(String status) {
    switch (status) {
      case 'active':
        return AppColors.greencolor;
      case 'pending_payment':
        return AppColors.orangecolor;
      case 'cancelled':
        return AppColors.redcolor;
      case 'expired':
        return AppColors.greycolor;
      default:
        return AppColors.greycolor;
    }
  }

  /// The player-facing membership status the sports/detail endpoints send
  /// back: `not enrolled` (with a space), `pending_payment`, `enrolled`,
  /// `expired`.
  static Color membershipRelation(String status) {
    switch (status) {
      case 'enrolled':
        return AppColors.greencolor;
      case 'pending_payment':
        return AppColors.orangecolor;
      case 'expired':
        return AppColors.redcolor;
      default:
        return AppColors.primary;
    }
  }

  /// Clamps a semantic colour so it works as *foreground* on the current
  /// theme's surfaces.
  ///
  /// The status colours are chosen to look right as fills. Used as text on a
  /// low-alpha wash of themselves - which is what StatusChip does - the
  /// lighter ones fail badly: brand gold measures 2.10:1 on white, academy
  /// green 2.88:1. Rather than hand-maintain a second palette, this pins
  /// lightness into a band that is guaranteed to clear contrast: dark enough
  /// on a light surface, light enough on a dark one, hue and saturation
  /// untouched so the colour still reads as the same status.
  static Color readable(BuildContext context, Color base) {
    final hsl = HSLColor.fromColor(base);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Bounds chosen by measuring every status colour against a 14% wash of
    // itself: 0.30 is the loosest light cap where the worst case (academy
    // green) still clears 4.5:1, and 0.66 the dark floor for the same.
    return isDark
        ? hsl.withLightness(hsl.lightness.clamp(0.66, 1.0)).toColor()
        : hsl.withLightness(hsl.lightness.clamp(0.0, 0.30)).toColor();
  }

  /// Translation-key lookup. The backend sends snake_case values and the
  /// translation files carry a key per value, so this is mostly a pass
  /// through - it exists so the one value with a space in it
  /// (`not enrolled`) is normalised before hitting `.tr()`.
  static String label(String status) {
    final key = status.trim().replaceAll(' ', '_').replaceAll('-', '_');
    return key.isEmpty ? '—' : key.tr();
  }
}
