import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:tabala/components/general/avatar_picker_sheet.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/trainer_memberships_cubit.dart';
import 'package:tabala/cubits/trainer_profile_cubit.dart';
import 'package:tabala/models/membership_model.dart';
import 'package:tabala/models/user_model.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/theme/app_theme_provider.dart';
import 'package:tabala/src/utils/app_money.dart';

/// The trainer's profile, plus the classes they run.
///
/// The classes block is new: `/trainer/memberships` was live with no screen,
/// which also meant `/trainer/memberships/{id}/generate-sessions` was
/// unreachable - a trainer could not materialise sessions from their own
/// schedule without someone doing it for them in the admin panel.
class TrainerProfileView extends StatefulWidget {
  const TrainerProfileView({super.key});

  @override
  State<TrainerProfileView> createState() => _TrainerProfileViewState();
}

class _TrainerProfileViewState extends State<TrainerProfileView> {
  late final TrainerProfileCubit _profile;
  late final TrainerMembershipsCubit _memberships;

  @override
  void initState() {
    super.initState();
    _profile = TrainerProfileCubit()..load();
    _memberships = TrainerMembershipsCubit()..load();
  }

  @override
  void dispose() {
    _profile.close();
    _memberships.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _profile),
        BlocProvider.value(value: _memberships),
      ],
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(title: Text('profile'.tr())),
        body: BlocBuilder<TrainerProfileCubit, AsyncState<UserModel>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: _profile.load,
              child: state.hasData ? _content(state.data!) : const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  Widget _content(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trainer = user.trainer;

    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () async {
        await _profile.load(refresh: true);
        await _memberships.load(refresh: true);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          ClubBottomNav.scrollPadding(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ClubGradientPanel(
            child: Column(
              children: [
                ClubAvatar(
                  initial: user.initial,
                  photoUrl: user.photo,
                  size: 78,
                  ring: true,
                  onTap: () => showAvatarSheet(
                    context,
                    hasPhoto: user.photo != null,
                    onUpload: _profile.uploadAvatar,
                    onRemove: _profile.removeAvatar,
                  ),
                ),
                const SizedBox(height: 14),
                Text(user.name, style: AppStyles.bold20Black.copyWith(color: PanelInk.strong(context))),
                const SizedBox(height: 4),
                Text(
                  // sportName can be blank: the resource reads it through a
                  // null-safe relation, so a trainer with no sport attached
                  // gets an empty string rather than an error.
                  (trainer?.sportName.isNotEmpty ?? false)
                      ? trainer!.sportName
                      : 'coach'.tr(),
                  style: AppStyles.regular14Grey.copyWith(color: PanelInk.muted(context)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        label: 'rating'.tr(),
                        value: trainer?.ratingLabel ?? '—',
                        icon: Icons.star_rounded,
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatTile(
                        label: 'status_label'.tr(),
                        value: (trainer?.status ?? '').tr(),
                        icon: Icons.verified_user_rounded,
                        onDark: true,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: BlocBuilder<TrainerMembershipsCubit,
                          AsyncState<List<MembershipModel>>>(
                        builder: (context, state) => StatTile(
                          label: 'classes'.tr(),
                          value: '${state.data?.length ?? 0}',
                          icon: Icons.sports_rounded,
                          onDark: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SectionHeader(
            title: 'bio'.tr(),
            actionLabel: 'edit_profile'.tr(),
            onAction: () => _openEditSheet(user),
          ),
          ClubCard(
            child: Text(
              (trainer?.bio?.isNotEmpty ?? false) ? trainer!.bio! : 'no_bio_yet'.tr(),
              style: AppStyles.regular14Grey,
            ),
          ),

          SectionHeader(title: 'contact'.tr()),
          ClubCard(
            child: Column(
              children: [
                _row(Icons.mail_outline_rounded, 'email'.tr(), user.email),
                Divider(color: AppColors.borderColor, height: 22),
                _row(Icons.phone_outlined, 'phone'.tr(), user.phone ?? '—'),
              ],
            ),
          ),

          SectionHeader(
            title: 'my_classes'.tr(),
            subtitle: 'generate_sessions_hint'.tr(),
          ),
          BlocBuilder<TrainerMembershipsCubit, AsyncState<List<MembershipModel>>>(
            builder: (context, state) {
              if (state.isBusy) {
                return const AsyncStateView(isLoading: true, child: SizedBox());
              }
              final list = state.data ?? const <MembershipModel>[];
              if (list.isEmpty) {
                return ClubCard(
                  child: Text('no_classes_yet'.tr(), style: AppStyles.regular14Grey),
                );
              }
              return Column(children: list.map(_membershipCard).toList());
            },
          ),

          SectionHeader(title: 'preferences'.tr()),
          ClubCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      size: 20,
                      color: AppColors.goldInk,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('dark_mode'.tr(), style: AppStyles.medium14Black),
                    ),
                    Switch(
                      value: isDark,
                      activeColor: AppColors.primarycolor,
                      onChanged: (_) => context
                          .read<AppThemeProvider>()
                          .toggle(isCurrentlyDark: isDark),
                    ),
                  ],
                ),
                Divider(color: AppColors.borderColor, height: 22),
                Row(
                  children: [
                    Icon(Icons.language_rounded, size: 20, color: AppColors.goldInk),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('language'.tr(), style: AppStyles.medium14Black),
                    ),
                    TextButton(
                      onPressed: () => context.setLocale(
                        context.locale.languageCode == 'en'
                            ? const Locale('ar')
                            : const Locale('en'),
                      ),
                      child: Text(
                        context.locale.languageCode == 'en' ? 'العربية' : 'English',
                        style: AppStyles.bold14Gold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),
          CustomElevatedButton(
            text: 'logout'.tr(),
            bgColor: AppColors.surfacecolor,
            borderColor: AppColors.redcolor,
            textStyle: AppStyles.bold14Red,
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.greycolor),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppStyles.regular14Grey)),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppStyles.medium14Black,
          ),
        ),
      ],
    );
  }

  Widget _membershipCard(MembershipModel m) {
    return ClubCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  m.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.bold16Black,
                ),
              ),
              StatusChip(
                label: AppMoney.format(m.price),
                color: AppColors.goldInk,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(m.sportName ?? '—', style: AppStyles.regular12Grey),
          if (m.schedules.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: m.schedules
                  .map((s) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.cardcolor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(s.label, style: AppStyles.medium12Grey),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              if (m.enrollmentsCount != null)
                StatusChip(
                  label: m.maxAttendees == null
                      ? 'players_count'.tr(args: ['${m.enrollmentsCount}'])
                      : '${m.enrollmentsCount}/${m.maxAttendees}',
                  color: AppColors.bluecolor,
                  icon: Icons.groups_rounded,
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _generate(m),
                icon: Icon(Icons.auto_awesome_rounded, size: 17, color: AppColors.goldInk),
                label: Text('generate_sessions'.tr(), style: AppStyles.bold14Gold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Materialises session rows from the class's schedule.
  ///
  /// Safe to run repeatedly: the `unique_session` index on
  /// (membership, schedule, date) means re-generating over an overlapping
  /// window creates nothing rather than duplicating.
  Future<void> _generate(MembershipModel m) async {
    final now = DateTime.now();
    final created = await _memberships.generateSessions(
      m.id,
      from: now,
      to: now.add(const Duration(days: 30)),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          created == null
              ? 'something_went_wrong'.tr()
              : 'sessions_generated'.tr(args: ['$created']),
        ),
        backgroundColor: created == null ? AppColors.redcolor : null,
      ),
    );
  }

  void _openEditSheet(UserModel user) {
    final name = TextEditingController(text: user.name);
    final bio = TextEditingController(text: user.trainer?.bio ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 22,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'edit_profile'.tr(),
              style: AppStyles.bold18Black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            CustomTextFormField(controller: name, hinttext: 'full_name'.tr()),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: bio,
              hinttext: 'bio'.tr(),
              maxlines: 4,
              maxLength: 1000,
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              gold: true,
              text: 'save'.tr(),
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                final error = await _profile.update(
                  name: name.text.trim(),
                  bio: bio.text.trim(),
                );
                if (error != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: AppColors.redcolor),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
