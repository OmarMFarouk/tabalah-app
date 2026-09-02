import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/components/general/custom_header.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/auth/auth_state.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/auth/validators.dart';
import 'package:tabala/views/auth/register_view.dart';
import 'package:tabala/views/auth/forgot_password_view.dart';
import 'package:tabala/views/auth/verify_email_view.dart';

enum LoginType { player, coach }

/// How the person in front of the phone is getting in.
///
/// Only the member portal offers both: a coach has no parent code and never
/// sees this choice.
enum _SignInMode {
  /// Email and password - the member's own account, full access.
  account,

  /// A code the member handed to a parent - read-only, no account.
  parentCode,
}

/// One login screen for both portals - the only difference is copy and
/// whether a "create account" link is offered (players can self-register,
/// trainers are provisioned by an admin).
///
/// Step 2 of the sign-in flow. For members it also carries the choice
/// between the two ways in, which lives here rather than on the portal
/// chooser for the reason spelled out on [WelcomeView]: "member or coach"
/// is a question about who you are, and "my account or a code" is a question
/// about what you happen to be holding. Asking them one after the other is
/// what stops a parent's code looking like a third kind of account.
class LoginView extends StatefulWidget {
  final LoginType loginType;

  /// Opens straight on the parent-code form. Used when something already
  /// knows the person is a parent - a deep link, or the "view as parent"
  /// route out of a signed-out state.
  final bool startAsParent;

  const LoginView({
    super.key,
    required this.loginType,
    this.startAsParent = false,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();

  late _SignInMode _mode = widget.startAsParent
      ? _SignInMode.parentCode
      : _SignInMode.account;

  bool get isPlayer => widget.loginType == LoginType.player;
  bool get _isParent => isPlayer && _mode == _SignInMode.parentCode;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_isParent) {
      context.read<AuthCubit>().guardianLogin(
        code: codeController.text.trim(),
      );
      return;
    }

    context.read<AuthCubit>().login(
      email: emailController.text.trim(),
      password: passwordController.text,
    );
  }

  void _switchMode(_SignInMode next) {
    if (_mode == next) return;
    // Clearing the other form's fields matters for more than tidiness: the
    // validators run against whatever is still in the controllers, and a
    // stale password would keep the button refusing to submit a code.
    setState(() {
      _mode = next;
      emailController.clear();
      passwordController.clear();
      codeController.clear();
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.redcolor,
            ),
          );
        } else if (state is AuthNeedsVerification) {
          // Right password, unconfirmed address. This is a step they can
          // finish, so hand them the code screen rather than an error they
          // cannot act on.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.primarycolor,
            ),
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => VerifyEmailView(email: state.email),
            ),
          );
        }
        // Nothing to do on AuthAuthenticated: unwinding the route stack is
        // handled once, app-wide, in main.dart. Doing it here as well made
        // navigation depend on this screen surviving the transition.
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: AppColors.scaffoldcolor,
          body: SafeArea(
            child: KeyboardAwareBody(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const CustomHeader(showBack: true),
                    const SizedBox(height: 14),
                    _stepPill('portal_step'.tr(args: ['2'])),
                    const SizedBox(height: 14),
                    Text(
                      _isParent
                          ? "parent_portal".tr()
                          : (isPlayer
                                ? "player_portal".tr()
                                : "coach_portal".tr()),
                      style: AppStyles.bold24Black,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isParent
                          ? "parent_portal_desc".tr()
                          : (isPlayer
                                ? "description".tr()
                                : "coach_login_desc".tr()),
                      textAlign: TextAlign.center,
                      style: AppStyles.regular14Grey,
                    ),
                    const SizedBox(height: 22),

                    if (isPlayer) ...[
                      _modeSwitch(isLoading),
                      const SizedBox(height: 22),
                    ],

                    if (_isParent)
                      ..._parentFields()
                    else
                      ..._accountFields(isLoading),

                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: CustomElevatedButton(
                        text: isLoading
                            ? "loading".tr()
                            : (_isParent
                                  ? "parent_sign_in".tr()
                                  : (isPlayer
                                        ? "player_login".tr()
                                        : "coach_login".tr())),
                        onPressed: isLoading ? null : _submit,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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

  /// The two ways a member's household can get in, side by side.
  ///
  /// Shown as two labelled tiles rather than a segmented control because
  /// each needs a sentence of explanation: the whole point is that a parent
  /// understands, before they tap, that their view will be read-only.
  Widget _modeSwitch(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('sign_in_method'.tr(), style: AppStyles.medium14Grey),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _modeTile(
                mode: _SignInMode.account,
                icon: Icons.badge_rounded,
                title: 'sign_in_with_account'.tr(),
                subtitle: 'sign_in_with_account_desc'.tr(),
                enabled: !isLoading,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _modeTile(
                mode: _SignInMode.parentCode,
                icon: Icons.family_restroom_rounded,
                title: 'sign_in_as_parent'.tr(),
                subtitle: 'sign_in_as_parent_desc'.tr(),
                enabled: !isLoading,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _modeTile({
    required _SignInMode mode,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    final selected = _mode == mode;

    return GestureDetector(
      onTap: enabled ? () => _switchMode(mode) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: .14)
              : AppColors.surfacecolor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: .65)
                : AppColors.borderColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.goldInk : AppColors.greycolor,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              style: selected
                  ? AppStyles.bold14Black
                  : AppStyles.medium14Black,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 3,
              style: AppStyles.regular12Grey,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _accountFields(bool isLoading) {
    return [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text("email".tr(), style: AppStyles.medium14Grey),
      ),
      const SizedBox(height: 6),
      CustomTextFormField(
        controller: emailController,
        hinttext: "email_hint".tr(),
        keyboardtype: TextInputType.emailAddress,
        denySpaces: true,
        validator: Validators.email,
      ),
      const SizedBox(height: 16),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text("password".tr(), style: AppStyles.medium14Grey),
      ),
      const SizedBox(height: 6),
      CustomTextFormField(
        controller: passwordController,
        obsecurtext: true,
        denySpaces: true,
        hinttext: "password_hint".tr(),
        validator: Validators.password,
      ),
      const SizedBox(height: 10),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: GestureDetector(
          onTap: isLoading
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ForgotPasswordView(),
                  ),
                ),
          child: Text("forgot_password".tr(), style: AppStyles.bold14Primary),
        ),
      ),
      const SizedBox(height: 14),
      if (isPlayer)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: GestureDetector(
            onTap: isLoading
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterView()),
                  ),
            child: RichText(
              text: TextSpan(
                style: AppStyles.regular14Grey,
                children: [
                  TextSpan(text: "${"no_account_yet".tr()} "),
                  TextSpan(
                    text: "create_account".tr(),
                    style: AppStyles.bold14Primary,
                  ),
                ],
              ),
            ),
          ),
        ),
    ];
  }

  List<Widget> _parentFields() {
    return [
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text("parent_code".tr(), style: AppStyles.medium14Grey),
      ),
      const SizedBox(height: 6),
      CustomTextFormField(
        controller: codeController,
        hinttext: "parent_code_hint".tr(),
        denySpaces: true,
        // Codes are stored upper-case from an alphabet with no ambiguous
        // glyphs. Upper-casing as the parent types means a code copied out
        // of a message in lower case still matches, without them having to
        // notice why it didn't.
        inputFormatters: [UpperCaseTextFormatter()],
        keyboardtype: TextInputType.visiblePassword,
        validator: (value) {
          final code = (value ?? '').trim();
          if (code.isEmpty) return 'parent_code_required'.tr();
          if (code.length < 6) return 'parent_code_too_short'.tr();
          return null;
        },
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.greycolor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'parent_where_code'.tr(),
              style: AppStyles.regular12Grey,
            ),
          ),
        ],
      ),
    ];
  }
}

/// Upper-cases as the user types, keeping the caret where they left it.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
