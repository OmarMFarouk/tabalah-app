import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_header.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/cubits/auth/auth_state.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/auth/validators.dart';
import 'package:tabala/views/auth/verify_email_view.dart';

/// Signup in two steps: the account, then the athlete — body details, the
/// health disclosure, and the two agreements the academy requires.
///
/// The agreements are required, not offered: the server refuses a signup
/// without both, and the pledge is what the academy relies on if a
/// condition that was not disclosed turns out to matter.
class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  static const _site = 'https://tabalahacademy.com';

  final _accountForm = GlobalKey<FormState>();
  final _athleteForm = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final emergencyContactController = TextEditingController();
  final healthController = TextEditingController();

  int _step = 0;
  bool _hasCondition = false;
  bool _acceptTerms = false;
  bool _acceptPledge = false;

  /// Off until the first attempt, so the agreements are not shown in red
  /// before anyone has had the chance to tick them.
  bool _showConsentErrors = false;

  @override
  void dispose() {
    for (final c in [
      nameController,
      emailController,
      phoneController,
      passwordController,
      confirmPasswordController,
      heightController,
      weightController,
      emergencyContactController,
      healthController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (_accountForm.currentState!.validate()) setState(() => _step = 1);
  }

  void _submit() {
    final formOk = _athleteForm.currentState!.validate();
    setState(() => _showConsentErrors = true);
    if (!formOk || !_acceptTerms || !_acceptPledge) return;

    context.read<AuthCubit>().registerPlayer(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      passwordConfirmation: confirmPasswordController.text,
      phone: phoneController.text.trim(),
      height: num.tryParse(heightController.text),
      weight: num.tryParse(weightController.text),
      emergencyContact: emergencyContactController.text.trim(),
      healthCondition: _hasCondition ? healthController.text.trim() : null,
      acceptedTerms: _acceptTerms,
      acceptedPledge: _acceptPledge,
    );
  }

  Future<void> _open(String path) =>
      launchUrl(Uri.parse('$_site/$path'), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: AppColors.redcolor),
          );
        } else if (state is AuthRegistrationSuccess) {
          // The account exists but holds no token yet. Straight to the code
          // screen - sending them to the login tab would only earn a 403.
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => VerifyEmailView(email: state.email)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        // Back from the second step returns to the first rather than
        // leaving signup and dropping everything typed so far.
        return PopScope(
          canPop: _step == 0,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) setState(() => _step = 0);
          },
          child: Scaffold(
            backgroundColor: AppColors.scaffoldcolor,
            body: SafeArea(
              child: KeyboardAwareBody(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const CustomHeader(showBack: true),
                    const SizedBox(height: 14),
                    Text('create_account'.tr(), style: AppStyles.bold24Black),
                    const SizedBox(height: 8),
                    Text(
                      'register_description'.tr(),
                      textAlign: TextAlign.center,
                      style: AppStyles.regular14Grey,
                    ),
                    const SizedBox(height: 18),
                    _StepBar(step: _step),
                    const SizedBox(height: 18),
                    Expanded(
                      child: IndexedStack(
                        index: _step,
                        children: [
                          SingleChildScrollView(
                            child: Form(key: _accountForm, child: _accountFields()),
                          ),
                          SingleChildScrollView(
                            child: Form(key: _athleteForm, child: _athleteFields()),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_step == 1) ...[
                          Expanded(
                            child: SizedBox(
                              height: 55,
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () => setState(() => _step = 0),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.goldInk,
                                  side: BorderSide(color: AppColors.borderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: Text('back'.tr(), style: AppStyles.bold14Gold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 55,
                            child: CustomElevatedButton(
                              text: _step == 0 ? 'next'.tr() : 'create_account'.tr(),
                              isBusy: isLoading && _step == 1,
                              onPressed: isLoading ? null : (_step == 0 ? _next : _submit),
                            ),
                          ),
                        ),
                      ],
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

  Widget _accountFields() {
    return Column(
      children: [
        CustomTextFormField(
          controller: nameController,
          hinttext: "full_name".tr(),
          validator: Validators.required,
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: emailController,
          hinttext: "email_hint".tr(),
          keyboardtype: TextInputType.emailAddress,
          denySpaces: true,
          validator: Validators.email,
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: phoneController,
          hinttext: "phone".tr(),
          keyboardtype: TextInputType.phone,
          denySpaces: true,
          validator: Validators.optionalPhone,
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: passwordController,
          obsecurtext: true,
          denySpaces: true,
          hinttext: "password_hint".tr(),
          validator: Validators.password,
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: confirmPasswordController,
          obsecurtext: true,
          denySpaces: true,
          hinttext: "confirm_password_hint".tr(),
          validator: (value) => Validators.confirmPassword(value, passwordController.text),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _athleteFields() {
    final consentMissing = _showConsentErrors && !(_acceptTerms && _acceptPledge);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('signup_step_athlete_consent_desc'.tr(), style: AppStyles.regular14Grey),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: CustomTextFormField(
                controller: heightController,
                hinttext: "height_hint".tr(),
                denySpaces: true,
                keyboardtype: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextFormField(
                controller: weightController,
                hinttext: "weight_hint".tr(),
                denySpaces: true,
                keyboardtype: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: emergencyContactController,
          hinttext: "emergency_contact_hint".tr(),
          keyboardtype: TextInputType.phone,
          denySpaces: true,
          validator: Validators.optionalPhone,
        ),
        const SizedBox(height: 18),

        // ── Health disclosure ──────────────────
        _ConsentBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _checkRow(
                value: _hasCondition,
                onChanged: (v) => setState(() => _hasCondition = v),
                child: Text('has_health_condition'.tr(), style: AppStyles.medium14Black),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: _hasCondition
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomTextFormField(
                              controller: healthController,
                              hinttext: 'health_condition_hint'.tr(),
                              maxlines: 3,
                              maxLength: 1000,
                              validator: (v) => _hasCondition && (v ?? '').trim().isEmpty
                                  ? 'health_condition_required'.tr()
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text('health_condition_desc'.tr(), style: AppStyles.regular12Grey),
                          ],
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Agreements ─────────────────────────
        _ConsentBox(
          error: consentMissing,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _checkRow(
                value: _acceptTerms,
                onChanged: (v) => setState(() => _acceptTerms = v),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${'signup_terms_prefix'.tr()} ', style: AppStyles.medium14Black),
                    _link('terms_and_conditions'.tr(), 'terms'),
                    Text(' ${'and'.tr()} ', style: AppStyles.medium14Black),
                    _link('privacy_policy'.tr(), 'privacy'),
                  ],
                ),
              ),
              Divider(color: AppColors.borderColor, height: 22),
              _checkRow(
                value: _acceptPledge,
                onChanged: (v) => setState(() => _acceptPledge = v),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'signup_pledge'.tr(),
                      style: AppStyles.medium14Black.copyWith(height: 1.55),
                    ),
                    const SizedBox(height: 4),
                    _link('read_pledge'.tr(), 'guardian-pledge'),
                  ],
                ),
              ),
              if (_showConsentErrors && !_acceptTerms)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    'must_accept_terms'.tr(),
                    style: AppStyles.regular12Grey.copyWith(color: AppColors.redcolor),
                  ),
                ),
              if (_showConsentErrors && !_acceptPledge)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'must_accept_pledge'.tr(),
                    style: AppStyles.regular12Grey.copyWith(color: AppColors.redcolor),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _checkRow({
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget child,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.goldInk,
              checkColor: AppColors.onGold,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(padding: const EdgeInsets.only(top: 5), child: child),
          ),
        ],
      ),
    );
  }

  /// Opens the page on tabalahacademy.com. Its own gesture, so tapping the
  /// link does not also tick the box it sits beside.
  Widget _link(String label, String path) {
    return GestureDetector(
      onTap: () => _open(path),
      child: Text(
        label,
        style: AppStyles.bold14Gold.copyWith(
          decoration: TextDecoration.underline,
          decorationColor: AppColors.goldInk,
        ),
      ),
    );
  }
}

class _ConsentBox extends StatelessWidget {
  final Widget child;
  final bool error;

  const _ConsentBox({required this.child, this.error = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfacecolor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: error ? AppColors.redcolor : AppColors.borderColor,
          width: error ? 1.4 : 1,
        ),
      ),
      child: child,
    );
  }
}

class _StepBar extends StatelessWidget {
  final int step;

  const _StepBar({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(context, 0, 'signup_step_account'),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: step >= 1 ? AppColors.goldInk : AppColors.borderColor,
          ),
        ),
        _dot(context, 1, 'signup_step_athlete'),
      ],
    );
  }

  Widget _dot(BuildContext context, int index, String labelKey) {
    final reached = step >= index;
    final done = step > index;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached ? AppColors.goldInk : AppColors.surfacecolor,
            border: Border.all(color: reached ? AppColors.goldInk : AppColors.borderColor),
          ),
          child: done
              ? Icon(Icons.check_rounded, size: 15, color: AppColors.onGold)
              : Text(
                  '${index + 1}',
                  style: AppStyles.bold12Black.copyWith(
                    color: reached ? AppColors.onGold : AppColors.greycolor,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          labelKey.tr(),
          style: step == index ? AppStyles.bold14Black : AppStyles.regular14Grey,
        ),
      ],
    );
  }
}
