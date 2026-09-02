import 'dart:async';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/components/general/custom_header.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// The second half of registration.
///
/// `/register` creates the account but withholds the auth token, and `/login`
/// refuses an address that was never confirmed. Both send the user here with
/// the address already known, so the only thing to type is the code.
///
/// A successful verification returns the token, so this screen ends with the
/// user signed in - the root listens for [AuthAuthenticated] and moves on.
class VerifyEmailView extends StatefulWidget {
  final String email;

  const VerifyEmailView({super.key, required this.email});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  /// Matches the server's resend cooldown, so the button is disabled for as
  /// long as a retry would be rejected anyway.
  static const int _cooldownSeconds = 60;
  int _secondsLeft = _cooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await context.read<AuthCubit>().verifyEmail(
          email: widget.email,
          code: _codeController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.redcolor),
      );
      return;
    }

    // Nothing to do on success. Verifying emits AuthAuthenticated, and the
    // listener in main.dart unwinds the auth stack for every entry and exit
    // in one place. Popping here as well was a second authority on
    // navigation racing the first - the mistake main.dart's comment was
    // written about.
  }

  Future<void> _resend() async {
    setState(() => _isLoading = true);
    final error = await context.read<AuthCubit>().resendVerification(email: widget.email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'verification_code_resent'.tr()),
        backgroundColor: error != null ? AppColors.redcolor : AppColors.primarycolor,
      ),
    );

    if (error == null) _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 0 && !_isLoading;

    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      body: SafeArea(
        child: KeyboardAwareBody(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  const CustomHeader(showBack: true),
                  const SizedBox(height: 16),
                  Text('verify_email_title'.tr(), style: AppStyles.bold24Black),
                  const SizedBox(height: 10),
                  Text(
                    'verify_email_desc'.tr(args: [widget.email]),
                    textAlign: TextAlign.center,
                    style: AppStyles.regular14Grey,
                  ),
                  const SizedBox(height: 28),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('verification_code'.tr(), style: AppStyles.medium14Grey),
                  ),
                  const SizedBox(height: 6),
                  CustomTextFormField(
                    controller: _codeController,
                    hinttext: 'code_hint'.tr(),
                    keyboardtype: TextInputType.number,
                    denySpaces: true,
                    validator: (v) => (v == null || v.trim().length != 6) ? 'code_hint'.tr() : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: CustomElevatedButton(
                      text: _isLoading ? 'loading'.tr() : 'verify_email_button'.tr(),
                      onPressed: _isLoading ? null : _submit,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: canResend ? _resend : null,
                    child: Text(
                      canResend
                          ? 'resend_code'.tr()
                          : 'resend_code_in'.tr(args: ['$_secondsLeft']),
                      style: canResend
                          ? AppStyles.medium14Primary
                          : AppStyles.regular14Grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
