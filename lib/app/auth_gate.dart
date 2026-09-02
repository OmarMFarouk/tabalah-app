import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/auth/auth_state.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/prefs/app_prefs.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/auth/onboarding_view.dart';
import 'package:tabala/views/auth/welcome_view.dart';
import 'package:tabala/views/guardian/guardian_main_view.dart';
import 'package:tabala/views/player/player_main_view.dart';
import 'package:tabala/views/trainer/trainer_main_view.dart';

/// Sits at the root of the app. Whichever screen is pushed on top
/// (onboarding -> welcome -> login) eventually pops back here once
/// AuthCubit reports an authenticated session, and this widget then shows
/// the portal for the user's role.
///
/// Role routing is deliberately explicit rather than "trainer or else
/// player": the same credentials work against the admin panel, and a staff
/// account signing in here should be told so rather than silently dropped
/// into the player app with endpoints that will 403 on every call.
class AuthGate extends StatefulWidget {
  // Intentionally not a const constructor call site anywhere: see the note
  // on MaterialApp.home in main.dart. Const-canonicalised widgets are
  // skipped on rebuild, which stops a theme switch from reaching the screens
  // below.
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _hasSeenOnboarding;

  /// True once the very first auth decision has been made.
  ///
  /// Without this, every later `AuthLoading` - a login attempt, a
  /// registration - dropped the gate back to the splash screen, tearing down
  /// the WelcomeView sitting underneath the pushed login route. Loading
  /// during a login attempt is the *login screen's* business to show; the
  /// gate should hold whatever it was already showing.
  bool _resolvedOnce = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().bootstrap();
    AppPrefs.hasSeenOnboarding().then((seen) {
      if (mounted) setState(() => _hasSeenOnboarding = seen);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          _resolvedOnce = true;

          // Checked before the role, and that order matters: a guardian
          // token authenticates *as* the player it watches, so
          // `user.isPlayer` is true for a parent too. Reading the role
          // first would drop every parent into the full member app.
          if (state.isGuardian) return GuardianMainView();

          if (state.user.isTrainer) return TrainerMainView();
          if (state.user.isPlayer) return PlayerMainView();
          return _WrongPortalScreen();
        }

        if (state is AuthUnauthenticated ||
            state is AuthFailure ||
            state is AuthRegistrationSuccess ||
            // Both halves of the sign-up detour. Neither is a session, so
            // the gate keeps showing the unauthenticated UI while the auth
            // screens above it push the verification step. Leaving either
            // out drops this branch to the splash screen, which tears down
            // WelcomeView underneath the pushed login route and leaves the
            // stack in a state only a restart recovers from.
            state is AuthNeedsVerification ||
            // Hold the unauthenticated UI through a login attempt rather
            // than flashing the splash and rebuilding WelcomeView.
            (_resolvedOnce && state is AuthLoading)) {
          _resolvedOnce = true;
          // Wait for the onboarding check before choosing, to avoid a flash
          // of onboarding for returning users.
          if (_hasSeenOnboarding == null) return SplashScreen();
          return _hasSeenOnboarding! ? WelcomeView() : OnboardingView();
        }

        return SplashScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ClubLogo(size: 108),
            const SizedBox(height: 18),
            Text('club_name'.tr(), style: AppStyles.bold20Gold),
            const SizedBox(height: 4),
            Text('club_info'.tr(), style: AppStyles.regular12Grey),
            const SizedBox(height: 30),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                color: AppColors.goldInk,
                strokeWidth: 2.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown when a staff account (employee/admin/owner) signs in to the member
/// app. Their role passes authentication but every `/player/*` and
/// `/trainer/*` route is gated by role middleware and would 403.
class _WrongPortalScreen extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _WrongPortalScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  size: 56, color: AppColors.goldInk),
              const SizedBox(height: 18),
              Text(
                'staff_account_detected'.tr(),
                textAlign: TextAlign.center,
                style: AppStyles.bold18Black,
              ),
              const SizedBox(height: 8),
              Text(
                'use_admin_panel'.tr(),
                textAlign: TextAlign.center,
                style: AppStyles.regular14Grey,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => context.read<AuthCubit>().logout(),
                child: Text('logout'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
