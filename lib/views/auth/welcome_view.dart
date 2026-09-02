import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/components/general/custom_header.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/auth/login_view.dart';

/// First screen after onboarding: pick which portal to continue to.
///
/// There are three ways into this app now - member, coach, and a read-only
/// parent view - but they are deliberately **not** three choices here.
///
/// A parent is not a third kind of user with their own account; they are
/// someone looking at a member's data with a code that member gave them. So
/// the question this screen asks is the one people can actually answer
/// about themselves - "are you a member or a coach?" - and the parent route
/// lives one level down, on the member sign-in screen, where the two ways in
/// (your own account, or a code) sit side by side. Offering "parent" up here
/// instead would make someone who has never heard of the code decide between
/// three things when they only know about two.
class WelcomeView extends StatefulWidget {
  const WelcomeView({super.key});

  @override
  State<WelcomeView> createState() => _WelcomeViewState();
}

class _WelcomeViewState extends State<WelcomeView> {
  LoginType selectedType = LoginType.player;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      body: SafeArea(
        child: KeyboardAwareBody(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 10),
              const CustomHeader(showBack: false),
              const SizedBox(height: 18),

              // Naming the step is what makes the two-level flow read as a
              // flow rather than as a screen that inexplicably leads to
              // another screen.
              _stepPill('portal_step'.tr(args: ['1'])),
              const SizedBox(height: 14),

              Text(
                "choose_login".tr(),
                style: AppStyles.bold24Black,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "choose_login_desc".tr(),
                textAlign: TextAlign.center,
                style: AppStyles.regular14Grey,
              ),
              const SizedBox(height: 26),

              _buildCard(
                type: LoginType.player,
                icon: Icons.person_rounded,
                title: "player_portal".tr(),
                subtitle: "player_subtitle".tr(),
                bottom: "player_bottom".tr(),
              ),
              const SizedBox(height: 14),
              _buildCard(
                type: LoginType.coach,
                icon: Icons.sports_rounded,
                title: "coach_portal".tr(),
                subtitle: "coach_subtitle".tr(),
                bottom: "coach_bottom".tr(),
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primarycolor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginView(loginType: selectedType),
                      ),
                    );
                  },
                  child: Text("continue".tr(), style: AppStyles.medium18White),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: .28)),
      ),
      child: Text(label, style: AppStyles.bold12Gold),
    );
  }

  Widget _buildCard({
    required LoginType type,
    required IconData icon,
    required String title,
    required String subtitle,
    required String bottom,
  }) {
    final isSelected = selectedType == type;

    return GestureDetector(
      onTap: () => setState(() => selectedType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          // Was a hardcoded Colors.white: in dark mode that put the
          // theme's near-white ink on a white card.
          color: isSelected ? AppColors.primarycolor : AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isSelected ? AppColors.primarycolor : AppColors.borderColor,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // A radio and an icon, not just a radio: the icon is what makes
            // the two cards distinguishable at a glance, before either is
            // read.
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: .16)
                    : AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? const Color(0xffE6C07B) : AppColors.goldInk,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: isSelected
                        ? AppStyles.bold16White
                        : AppStyles.bold16Black,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: isSelected
                        ? AppStyles.regular14White
                        : AppStyles.regular14Grey,
                  ),
                  const SizedBox(height: 8),
                  Text(bottom, style: AppStyles.medium14Yellow),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xffE6C07B)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xffE6C07B)
                      : AppColors.greycolor,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: AppColors.clubGreenDeep,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
