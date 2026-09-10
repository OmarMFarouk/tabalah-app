import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/auth/login_view.dart';

/// The first screen after onboarding.
///
/// This used to ask "member or coach?". It no longer asks anything: `login`
/// returns the account's role and AuthGate renders the matching app, so the
/// question was decoration - picking the wrong card changed nothing. Every
/// portal the academy adds stays invisible here.
///
/// What is left is the academy's front door: the mark, one line, and a way
/// in. Sized off the viewport rather than fixed spacers so it holds from a
/// small phone to a tablet.
class WelcomeView extends StatelessWidget {
  const WelcomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final h = media.size.height;
    final short = h < 700;

    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.clubGreenDeep,
              AppColors.clubGreenDeep.withValues(alpha: .92),
              AppColors.scaffoldcolor,
            ],
            stops: const [0, .46, .62],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) => SingleChildScrollView(
              // Scrollable but never scrolls on a normal phone: the column
              // is given the full height and only overflows on very short
              // screens or with large system font sizes.
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, short ? 20 : 40, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 2),
                        Center(child: ClubLogo(size: short ? 96 : 132)),
                        SizedBox(height: short ? 20 : 30),
                        Text(
                          'club_name'.tr(),
                          textAlign: TextAlign.center,
                          style: AppStyles.bold24Black.copyWith(
                            color: Colors.white,
                            fontSize: short ? 26 : 32,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'welcome_tagline'.tr(),
                          textAlign: TextAlign.center,
                          style: AppStyles.regular14Grey.copyWith(
                            color: Colors.white.withValues(alpha: .82),
                            fontSize: 15,
                            height: 1.6,
                          ),
                        ),
                        const Spacer(flex: 3),
                        _FeatureRow(),
                        SizedBox(height: short ? 22 : 34),
                        SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primarycolor,
                              foregroundColor: AppColors.clubGreenDeep,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LoginView()),
                            ),
                            child: Text(
                              'get_started'.tr(),
                              style: AppStyles.medium18White.copyWith(
                                color: AppColors.clubGreenDeep,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Center(
                          child: Text(
                            'club_info'.tr(),
                            textAlign: TextAlign.center,
                            style: AppStyles.regular12Grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Three words on what the app is for. Wraps rather than overflows when the
/// system font is scaled up.
class _FeatureRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        _chip(Icons.sports_soccer_rounded, 'feature_training'.tr()),
        _chip(Icons.calendar_month_rounded, 'feature_schedule'.tr()),
        _chip(Icons.qr_code_2_rounded, 'feature_attendance'.tr()),
      ],
    );
  }

  Widget _chip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary.withValues(alpha: .3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: AppColors.goldInk),
            const SizedBox(width: 7),
            Text(label, style: AppStyles.medium14Black.copyWith(fontSize: 13)),
          ],
        ),
      );
}
