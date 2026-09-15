import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/models/assessment_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/utils/app_date.dart';

/// Five stars with halves.
///
/// Always laid out left-to-right: a half star's filled half is drawn on the
/// left, so mirroring the row under Arabic would put it on the wrong side.
class RatingStars extends StatelessWidget {
  final double value;
  final double size;

  const RatingStars({super.key, required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final icon = value >= i + 1
              ? Icons.star_rounded
              : value > i
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded;
          return Icon(icon, size: size, color: AppColors.goldInk);
        }),
      ),
    );
  }
}

/// One assessment as a card: the stars, the session it was about, who gave
/// it, and what they wrote.
class AssessmentCard extends StatelessWidget {
  final AssessmentItem item;
  final bool showRater;

  const AssessmentCard({super.key, required this.item, this.showRater = true});

  @override
  Widget build(BuildContext context) {
    final meta = [
      if (item.sportName != null) item.sportName!,
      if (showRater && item.raterName != null) 'rated_by'.tr(args: [item.raterName!]),
    ].join(' · ');

    return ClubCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              RatingStars(value: item.rating, size: 18),
              const SizedBox(width: 8),
              Text(item.rating.toStringAsFixed(1), style: AppStyles.bold14Black),
              const Spacer(),
              Text(
                AppDate.friendlyDate(item.sessionDate ?? item.createdAt),
                style: AppStyles.regular12Grey,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.isGeneral ? 'general_evaluation'.tr() : (item.membershipName ?? '—'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.bold14Black,
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(meta, style: AppStyles.regular12Grey),
          ],
          if (item.note != null) ...[
            const SizedBox(height: 8),
            Text(item.note!, style: AppStyles.regular14Black.copyWith(height: 1.5)),
          ],
        ],
      ),
    );
  }
}

/// The mark beside a player with a declared health condition. Tapping it
/// reads the note, when the note came with the payload.
class HealthFlag extends StatelessWidget {
  final String? note;
  final bool dense;

  const HealthFlag({super.key, this.note, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final chip = StatusChip(
      label: 'special_condition'.tr(),
      color: AppColors.redcolor,
      icon: Icons.medical_information_rounded,
      dense: dense,
    );

    if (note == null) return chip;

    return GestureDetector(
      onTap: () => showHealthNote(context, note!),
      child: chip,
    );
  }
}

Future<void> showHealthNote(BuildContext context, String note) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(Icons.medical_information_rounded, color: AppColors.redcolor, size: 34),
      title: Text('health_condition'.tr()),
      content: Text(note, style: AppStyles.regular14Black.copyWith(height: 1.6)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('close'.tr()),
        ),
      ],
    ),
  );
}

/// The note itself, where there is room to show it in full.
class HealthNoteCard extends StatelessWidget {
  final String note;

  const HealthNoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return ClubCard(
      color: AppColors.lightRed,
      border: Border.all(color: AppColors.redcolor.withValues(alpha: .35)),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.medical_information_rounded, color: AppColors.redcolor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'special_condition'.tr(),
                  style: AppStyles.bold14Black.copyWith(color: AppColors.redcolor),
                ),
                const SizedBox(height: 4),
                Text(
                  note.isEmpty ? '—' : note,
                  style: AppStyles.regular14Black.copyWith(height: 1.55),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
