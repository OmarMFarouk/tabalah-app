import 'dart:ui' show FontFeature;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'package:tabala/components/general/avatar_picker_sheet.dart';
import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/async_state.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/player_profile_cubit.dart';
import 'package:tabala/models/user_model.dart';
import 'package:tabala/src/app_scope.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/src/theme/app_theme_provider.dart';
import 'package:tabala/src/utils/app_date.dart';
import 'package:tabala/views/guardian/guardian_main_view.dart';
import 'package:tabala/views/player/my_qr_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final PlayerProfileCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = PlayerProfileCubit()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldcolor,
        appBar: AppBar(title: Text('profile'.tr())),
        body: BlocBuilder<PlayerProfileCubit, AsyncState<UserModel>>(
          builder: (context, state) {
            return AsyncStateView(
              isLoading: state.isBusy,
              errorMessage: state.hasData ? null : state.error,
              onRetry: _cubit.load,
              child: state.hasData ? _content(state.data!) : const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  Widget _content(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RefreshIndicator(
      color: AppColors.goldInk,
      backgroundColor: AppColors.surfacecolor,
      onRefresh: () => _cubit.load(refresh: true),
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          ClubBottomNav.scrollPadding(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const GuardianBanner(padding: EdgeInsets.only(bottom: 12)),
          ClubGradientPanel(
            child: Column(
              children: [
                // Tappable, with the camera badge saying so. A parent
                // watching their child's account only ever looks here, so
                // for them it stays a plain picture.
                ClubAvatar(
                  initial: user.initial,
                  photoUrl: user.photo,
                  size: 78,
                  ring: true,
                  onTap: AppScope.isGuardian
                      ? null
                      : () => showAvatarSheet(
                          context,
                          hasPhoto: user.photo != null,
                          onUpload: _cubit.uploadAvatar,
                          onRemove: _cubit.removeAvatar,
                        ),
                ),
                const SizedBox(height: 14),
                Text(user.name, style: AppStyles.bold20Black.copyWith(color: PanelInk.strong(context))),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: AppStyles.regular14Grey.copyWith(color: PanelInk.muted(context)),
                ),
                // The club id sits under the name because that is what it
                // is — an identity, not a setting. A member asked for it at
                // the desk should not have to go looking through a menu.
                if (user.player?.clubId != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: user.player!.clubId!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('club_id_copied'.tr())),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.goldInk.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.badge_outlined,
                            size: 14,
                            color: AppColors.goldInk,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.player!.clubId!,
                            style: AppStyles.bold16Black.copyWith(
                              fontSize: 13,
                              color: AppColors.goldInk,
                              letterSpacing: 1.2,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatusChip(
                      label: AppScope.isGuardian
                          ? 'guardian_read_only'.tr()
                          : 'player'.tr(),
                      color: AppColors.goldInk,
                      icon: AppScope.isGuardian
                          ? Icons.visibility_rounded
                          : Icons.sports_rounded,
                    ),
                    const SizedBox(width: 8),
                    if (user.joinedAt != null)
                      StatusChip(
                        label: '${'member_since'.tr()} ${AppDate.date(user.joinedAt)}',
                        color: AppColors.green,
                      ),
                  ],
                ),
              ],
            ),
          ),

          SectionHeader(
            title: 'physical_profile'.tr(),
            // A parent may look at these numbers, not change them.
            actionLabel: AppScope.isGuardian ? null : 'edit_profile'.tr(),
            onAction: AppScope.isGuardian ? null : () => _openEditSheet(user),
          ),
          ClubCard(
            child: Column(
              children: [
                _row('height_hint', user.player?.height == null
                    ? '—'
                    : '${user.player!.height} ${'cm'.tr()}'),
                Divider(color: AppColors.borderColor, height: 22),
                _row('weight_hint', user.player?.weight == null
                    ? '—'
                    : '${user.player!.weight} ${'kg'.tr()}'),
                Divider(color: AppColors.borderColor, height: 22),
                _row('emergency_contact', user.player?.emergencyContact ?? '—'),
                Divider(color: AppColors.borderColor, height: 22),
                _row('phone', user.phone ?? '—'),
              ],
            ),
          ),

          // The QR is an identity badge, not an action: a parent presenting
          // it at the door is the whole point of the guardian session, so it
          // sits outside the gated block below.
          if (user.player?.qrToken != null) ...[
            SectionHeader(title: 'my_qr_code'.tr()),
            _tile(
              icon: Icons.qr_code_2_rounded,
              title: 'my_qr_code'.tr(),
              subtitle: 'my_qr_code_desc'.tr(),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MyQrView(
                    qrToken: user.player!.qrToken!,
                    playerName: user.name,
                  ),
                ),
              ),
            ),
          ],

          // Everything remaining in this section acts on the account
          // itself, so a parent's session skips it entirely rather than
          // showing a list of tiles that all refuse to open.
          if (!AppScope.isGuardian) ...[
            SectionHeader(title: 'account'.tr()),
            // The member's half of the parent portal: this is where they
            // find the code to hand over.
            if (user.player?.guardianCode != null)
              _tile(
                icon: Icons.family_restroom_rounded,
                title: 'guardian_code'.tr(),
                subtitle: user.player!.guardianAccessEnabled
                    ? 'guardian_code_desc'.tr()
                    : 'guardian_code_disabled'.tr(),
                onTap: () => _showGuardianCode(user),
              ),
            _tile(
              icon: Icons.lock_outline_rounded,
              title: 'change_password'.tr(),
              subtitle: 'change_password_desc'.tr(),
              onTap: _openPasswordSheet,
            ),
          ],

          SectionHeader(title: 'preferences'.tr()),
          ClubCard(
            child: Column(
              children: [
                // Theme lives on the provider, but the *current* answer is
                // read from the theme so ThemeMode.system resolves properly.
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
            text: AppScope.isGuardian ? 'guardian_exit'.tr() : 'logout'.tr(),
            bgColor: AppColors.surfacecolor,
            borderColor: AppColors.redcolor,
            textStyle: AppStyles.bold14Red,
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
    );
  }

  Widget _row(String labelKey, String value) {
    return Row(
      children: [
        Expanded(child: Text(labelKey.tr(), style: AppStyles.regular14Grey)),
        Text(value, style: AppStyles.medium14Black),
      ],
    );
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ClubCard(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.goldInk, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.bold14Black),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.regular12Grey,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: AppColors.greycolor),
        ],
      ),
    );
  }

  /// Shows the member their parent code, big enough to read aloud.
  ///
  /// Deliberately a sheet rather than a row on the profile: the code is a
  /// credential, and putting it permanently on screen means it is on screen
  /// whenever the member hands their phone to somebody.
  void _showGuardianCode(UserModel user) {
    final code = user.player?.guardianCode;
    if (code == null) return;

    final enabled = user.player?.guardianAccessEnabled ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'guardian_code'.tr(),
              style: AppStyles.bold18Black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'guardian_code_sheet_desc'.tr(),
              style: AppStyles.regular14Grey,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            ClubGradientPanel(
              child: Column(
                children: [
                  SelectableText(
                    code,
                    textAlign: TextAlign.center,
                    style: AppStyles.bold24Black.copyWith(
                      color: PanelInk.strong(sheetContext),
                      // Wide tracking and fixed-width digits: this code gets
                      // compared character by character against something
                      // written on a piece of paper.
                      letterSpacing: 8,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (!enabled) ...[
                    const SizedBox(height: 12),
                    Text(
                      'guardian_code_disabled'.tr(),
                      textAlign: TextAlign.center,
                      style: AppStyles.regular12Grey.copyWith(
                        color: AppColors.redcolor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: CustomElevatedButton(
                    text: 'copy'.tr(),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      Navigator.pop(sheetContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('guardian_code_copied'.tr())),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  // Copying assumes the parent is reachable from this phone's
                  // clipboard, which they usually aren't — the code has to
                  // get into a WhatsApp message to somebody else. Sharing
                  // sends the sentence, not just the eight characters, so
                  // what arrives explains itself.
                  child: CustomElevatedButton(
                    gold: true,
                    text: 'share'.tr(),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Share.share(
                        'guardian_code_share_body'.tr(
                          namedArgs: {'code': code, 'name': user.name},
                        ),
                        subject: 'guardian_code'.tr(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Edits the player-specific fields via `PUT /player/profile`.
  void _openEditSheet(UserModel user) {
    final name = TextEditingController(text: user.name);
    final height = TextEditingController(text: user.player?.height?.toString() ?? '');
    final weight = TextEditingController(text: user.player?.weight?.toString() ?? '');
    final emergency =
        TextEditingController(text: user.player?.emergencyContact ?? '');

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
            Row(
              children: [
                Expanded(
                  child: CustomTextFormField(
                    controller: height,
                    hinttext: 'height_hint'.tr(),
                    keyboardtype: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomTextFormField(
                    controller: weight,
                    hinttext: 'weight_hint'.tr(),
                    keyboardtype: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: emergency,
              hinttext: 'emergency_contact_hint'.tr(),
              keyboardtype: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              gold: true,
              text: 'save'.tr(),
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                final error = await _cubit.update(
                  name: name.text.trim(),
                  height: num.tryParse(height.text),
                  weight: num.tryParse(weight.text),
                  emergencyContact: emergency.text.trim(),
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

  /// Password changes go through the shared `/profile` endpoint, which
  /// requires the current password - a signed-in device on its own is not
  /// enough to lock the real owner out of their account.
  void _openPasswordSheet() {
    final current = TextEditingController();
    final next = TextEditingController();

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
              'change_password'.tr(),
              style: AppStyles.bold18Black,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            CustomTextFormField(
              controller: current,
              hinttext: 'current_password'.tr(),
              obsecurtext: true,
            ),
            const SizedBox(height: 12),
            CustomTextFormField(
              controller: next,
              hinttext: 'new_password_hint'.tr(),
              obsecurtext: true,
            ),
            const SizedBox(height: 20),
            CustomElevatedButton(
              gold: true,
              text: 'save'.tr(),
              onPressed: () async {
                Navigator.of(sheetContext).pop();
                final error = await _cubit.updateAccount(
                  password: next.text,
                  currentPassword: current.text,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'password_reset_success'.tr()),
                    backgroundColor: error == null ? null : AppColors.redcolor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
