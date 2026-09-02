import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/models/player_home_model.dart';
import 'package:tabala/models/trainer_home_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/src/utils/sport_visual.dart';
import 'package:tabala/src/utils/status_ui.dart';

/// A horizontally scrolling rail.
///
/// Padding is applied to the *scroll view*, not to a wrapping widget, so
/// the first and last cards can sit flush against the screen edge while
/// still having breathing room when parked - which is what makes a carousel
/// read as a carousel rather than a clipped row.
///
/// `physics` uses the bouncing/clamping default for the platform. RTL is
/// handled automatically: Flutter flips the scroll axis for an Arabic
/// locale, so the rail starts on the right without any manual reversal.
class CarouselRail extends StatelessWidget {
  final double height;
  final List<Widget> children;
  final EdgeInsets padding;
  final double gap;

  const CarouselRail({
    super.key,
    required this.height,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        clipBehavior: Clip.none,
        itemCount: children.length,
        separatorBuilder: (_, __) => SizedBox(width: gap),
        itemBuilder: (_, index) => children[index],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Player home cards
// ─────────────────────────────────────────────────────────────────────────

/// The headline card: one of the player's active memberships, with its
/// attendance ring and expiry countdown. Rendered on the club gradient
/// because these are the "membership card in your wallet" of the app.
class MembershipCarouselCard extends StatelessWidget {
  final HomeMembership membership;
  final VoidCallback? onTap;

  const MembershipCarouselCard({super.key, required this.membership, this.onTap});

  @override
  Widget build(BuildContext context) {
    final expired = membership.hasExpired;
    final expiringSoon = membership.isExpiringSoon;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 268,
        child: ClubGradientPanel(
          // Tightened from 18: the bottom row carries a ring, two lines of
          // text and a chip, and at the old padding the chip was crowding
          // the card edge on smaller phones.
          padding: const EdgeInsets.all(15),
          // The club's artwork for this plan, painted behind the gradient at
          // low opacity. Null for most memberships, and the card then looks
          // exactly as it did before.
          imageUrl: membership.imageUrl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (membership.sportName ?? '').toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bold11Gold,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          membership.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.bold18Black.copyWith(color: PanelInk.strong(context)),
                        ),
                      ],
                    ),
                  ),
                  // The sport's own glyph when it has one, so the card is
                  // identifiable at a glance in a rail of several plans.
                  Icon(
                    membership.sportIcon == null
                        ? Icons.workspace_premium_rounded
                        : SportVisual.icon(membership.sportIcon),
                    color: AppColors.goldInk,
                    size: 24,
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AttendanceRing(value: membership.attendanceRate / 100),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          expired ? 'expired_on'.tr() : 'valid_until'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          // Stepped down from 12 so the label reads as a
                          // caption for the date under it rather than
                          // competing with it.
                          style: AppStyles.regular12Grey.copyWith(
                            color: PanelInk.muted(context),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          membership.endsLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppStyles.medium14Black.copyWith(
                            color: PanelInk.strong(context),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusChip(
                          label: expired
                              ? 'expired'.tr()
                              : 'days_left'.tr(args: ['${membership.remainingDays}']),
                          color: expired
                              ? AppColors.red
                              : (expiringSoon ? AppColors.orange : AppColors.green),
                          dense: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The attendance percentage as a ring rather than a bar - it reads as a
/// score, which is what a member actually treats it as.
class _AttendanceRing extends StatelessWidget {
  final double value;

  const _AttendanceRing({required this.value});

  /// Down from 58. The ring was the widest thing in the bottom row and was
  /// squeezing the date and its chip into an ellipsis on narrower phones;
  /// at 46 the percentage is still perfectly legible and the row breathes.
  static const double _size = 46;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: _size,
            height: _size,
            child: CircularProgressIndicator(
              value: value.clamp(0.0, 1.0),
              strokeWidth: 4,
              strokeCap: StrokeCap.round,
              backgroundColor: PanelInk.line(context),
              valueColor: AlwaysStoppedAnimation(AppColors.goldInk),
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: AppStyles.bold14Black.copyWith(
              color: PanelInk.strong(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// A session in the player's "today" rail. These carry no id from the API
/// (HomepageSessionResource emits none), so the card is display-only.
class SessionCarouselCard extends StatelessWidget {
  final HomeSession session;

  const SessionCarouselCard({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 214,
      child: ClubCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
                  ),
                  child: Text(session.startLabel, style: AppStyles.bold12Gold),
                ),
                const Spacer(),
                // The sport's own glyph rather than a generic one, so a
                // day with three different classes reads at a glance.
                Icon(
                  SportVisual.icon(session.sportIcon),
                  size: 16,
                  color: AppColors.greycolor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.bold14Black,
            ),
            const SizedBox(height: 3),
            Text(
              session.timeLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.regular12Grey,
            ),
            const Spacer(),
            Row(
              children: [
                ClubAvatar(
                  initial: (session.trainerName ?? '?').isEmpty
                      ? '?'
                      : (session.trainerName ?? '?')[0].toUpperCase(),
                  size: 26,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    session.trainerName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.medium12Grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A coach in the player's trainers rail.
class TrainerCarouselCard extends StatelessWidget {
  final HomeTrainer trainer;

  const TrainerCarouselCard({super.key, required this.trainer});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: ClubCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClubAvatar(
              initial: trainer.initial,
              photoUrl: (trainer.avatar?.startsWith('http') ?? false) ? trainer.avatar : null,
              size: 52,
              ring: true,
            ),
            const SizedBox(height: 10),
            Text(
              trainer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppStyles.bold14Black,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  SportVisual.icon(trainer.sportIcon),
                  size: 12,
                  color: AppColors.greycolor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    trainer.sportName ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppStyles.regular12Grey,
                  ),
                ),
              ],
            ),
            if (trainer.ratingLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 14, color: AppColors.goldInk),
                  const SizedBox(width: 3),
                  Text(trainer.ratingLabel!, style: AppStyles.bold12Gold),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Trainer home cards
// ─────────────────────────────────────────────────────────────────────────

/// A class the trainer is running, in their day rail. Tapping opens the
/// session so they can take the register.
class TrainerSessionCarouselCard extends StatelessWidget {
  final TrainerDaySession session;
  final VoidCallback? onTap;

  const TrainerSessionCarouselCard({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 246,
      child: ClubCard(
        onTap: onTap,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
                  ),
                  child: Text(session.startLabel, style: AppStyles.bold12Gold),
                ),
                const Spacer(),
                StatusChip(
                  label: 'players_count'.tr(args: ['${session.players.length}']),
                  color: AppColors.bluecolor,
                  icon: Icons.groups_rounded,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.membershipName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.bold16Black,
            ),
            const SizedBox(height: 3),
            Text(
              '${session.sportName ?? ''} · ${session.timeLabel}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppStyles.regular12Grey,
            ),
            const Spacer(),
            ProgressRow(
              label: 'class_attendance'.tr(),
              trailing: '${session.attendanceRate.round()}%',
              value: session.attendanceRate / 100,
              color: session.attendanceRate >= 70
                  ? AppColors.greencolor
                  : (session.attendanceRate >= 40
                      ? AppColors.orangecolor
                      : AppColors.redcolor),
            ),
          ],
        ),
      ),
    );
  }
}

/// The horizontal day strip above the trainer's rail. Sunday–Thursday is
/// the club's working week, so the strip is anchored on the selected day
/// with three days either side rather than on a Monday-start calendar.
class DayStrip extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;

  const DayStrip({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = List.generate(
      9,
      (i) => DateTime(today.year, today.month, today.day).add(Duration(days: i - 3)),
    );

    return CarouselRail(
      height: 74,
      gap: 8,
      children: days.map((day) {
        final isSelected = day.year == selected.year &&
            day.month == selected.month &&
            day.day == selected.day;
        final isToday = day.year == today.year &&
            day.month == today.month &&
            day.day == today.day;

        return GestureDetector(
          onTap: () => onSelect(day),
          child: Container(
            width: 58,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primarycolor : AppColors.surfacecolor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.primarycolor
                    : (isToday ? AppColors.goldInk : AppColors.borderColor),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppDate.weekday(day).substring(0, 3),
                  style: isSelected
                      ? AppStyles.medium12White
                      : AppStyles.medium12Grey,
                ),
                const SizedBox(height: 5),
                Text(
                  '${day.day}',
                  style: isSelected ? AppStyles.bold16White : AppStyles.bold16Black,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// A compact roster row reused by the trainer's session card and detail
/// screen.
class RosterRow extends StatelessWidget {
  final String name;
  final String initial;
  final String? subtitle;
  final String? status;
  final VoidCallback? onTap;

  const RosterRow({
    super.key,
    required this.name,
    required this.initial,
    this.subtitle,
    this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClubAvatar(initial: initial, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold14Black,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppStyles.regular12Grey,
                  ),
                ],
              ],
            ),
          ),
          if (status != null)
            StatusChip(
              label: StatusUi.label(status!),
              color: StatusUi.attendance(status!),
              icon: StatusUi.attendanceIcon(status!),
            ),
        ],
      ),
    );
  }
}
