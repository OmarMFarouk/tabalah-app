import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/session_rating_cubit.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// Rating a session's trainer, `POST /player/session-ratings`.
///
/// The backend requires a `trainer_user_id`, and that is the awkward part:
/// none of the player-facing endpoints return the trainer's **user** id.
/// The membership detail endpoint gives a trainer name and avatar; the
/// homepage gives a `trainer_id`, which is the trainers-table id, not the
/// user id. So the caller passes whichever id it has, and when it has none
/// the screen asks the server for the user behind the name via the shared
/// `/user` lookup.
class RateSessionView extends StatefulWidget {
  final int sessionId;
  final String sessionLabel;
  final String? trainerName;

  /// Pass this when the caller already knows it - it skips the lookup.
  final int? trainerUserId;

  const RateSessionView({
    super.key,
    required this.sessionId,
    required this.sessionLabel,
    this.trainerName,
    this.trainerUserId,
  });

  @override
  State<RateSessionView> createState() => _RateSessionViewState();
}

class _RateSessionViewState extends State<RateSessionView> {
  late final SessionRatingCubit _cubit;
  final TextEditingController _note = TextEditingController();

  double _rating = 5;
  int? _resolvedTrainerId;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _cubit = SessionRatingCubit();
    _resolvedTrainerId = widget.trainerUserId;
    if (_resolvedTrainerId == null && widget.trainerName != null) {
      _resolveTrainer();
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _cubit.close();
    super.dispose();
  }

  /// `GET /user?q=<name>` is available to every signed-in role. It is a
  /// name search, so it is a best-effort resolution - if it comes back
  /// ambiguous or empty the submit button stays disabled rather than
  /// posting a rating against the wrong person.
  Future<void> _resolveTrainer() async {
    setState(() => _resolving = true);
    final id = await _cubit.lookupTrainerId(widget.trainerName!);
    if (mounted) {
      setState(() {
        _resolvedTrainerId = id;
        _resolving = false;
      });
    }
  }

  Future<void> _submit() async {
    final trainerId = _resolvedTrainerId;
    if (trainerId == null) return;

    // `note` is required server-side, max 1000 chars - not optional, which
    // is easy to assume from the field name.
    if (_note.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('note_required'.tr())),
      );
      return;
    }

    final ok = await _cubit.submit(
      sessionId: widget.sessionId,
      trainerUserId: trainerId,
      rating: _rating,
      note: _note.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_cubit.state.error ?? 'something_went_wrong'.tr()),
          backgroundColor: AppColors.redcolor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;

    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(title: Text('rate_session'.tr())),
        body: BlocBuilder<SessionRatingCubit, RatingSubmission>(
          builder: (context, state) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                ClubGradientPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('session'.tr(), style: AppStyles.bold11Gold),
                      const SizedBox(height: 6),
                      Text(widget.sessionLabel, style: AppStyles.bold18Black.copyWith(color: PanelInk.strong(context))),
                      if (widget.trainerName != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ClubAvatar(
                              initial: widget.trainerName![0].toUpperCase(),
                              size: 30,
                            ),
                            const SizedBox(width: 10),
                            Text(widget.trainerName!, style: AppStyles.medium14Black.copyWith(color: PanelInk.strong(context))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                SectionHeader(title: 'your_rating'.tr()),
                ClubCard(
                  child: Column(
                    children: [
                      Text(
                        _rating.toStringAsFixed(1),
                        style: AppStyles.bold32Gold,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final filled = _rating >= i + 1;
                          final half = !filled && _rating > i;
                          return IconButton(
                            onPressed: () => setState(() => _rating = i + 1),
                            icon: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : (half ? Icons.star_half_rounded : Icons.star_border_rounded),
                              size: 32,
                              color: AppColors.goldInk,
                            ),
                          );
                        }),
                      ),
                      // The column is decimal(5,2) and validation allows any
                      // numeric 0-5, so half-steps are legitimate - the
                      // slider exposes that rather than forcing whole stars.
                      Slider(
                        value: _rating,
                        min: 0,
                        max: 5,
                        divisions: 10,
                        activeColor: AppColors.primarycolor,
                        inactiveColor: AppColors.borderColor,
                        label: _rating.toStringAsFixed(1),
                        onChanged: (v) => setState(() => _rating = v),
                      ),
                    ],
                  ),
                ),
                SectionHeader(title: 'your_note'.tr()),
                CustomTextFormField(
                  controller: _note,
                  hinttext: 'rating_note_hint'.tr(),
                  maxlines: 5,
                  maxLength: 1000,
                ),
                const SizedBox(height: 20),
                if (_resolving)
                  Center(
                    child: CircularProgressIndicator(
                      color: AppColors.goldInk,
                      strokeWidth: 2.2,
                    ),
                  )
                else if (_resolvedTrainerId == null)
                  ClubCard(
                    color: AppColors.lightOrange,
                    child: Text(
                      'trainer_not_resolved'.tr(),
                      style: AppStyles.regular14Grey,
                    ),
                  )
                else
                  CustomElevatedButton(
                    gold: true,
                    isBusy: state.isSubmitting,
                    text: 'submit_rating'.tr(),
                    onPressed: _submit,
                  ),
                const SizedBox(height: 10),
                Text(
                  'rating_requires_attendance'.tr(),
                  textAlign: TextAlign.center,
                  style: AppStyles.regular12Grey,
                ),
                if (user?.isPlayer == false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'players_only'.tr(),
                      textAlign: TextAlign.center,
                      style: AppStyles.regular12Grey,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
