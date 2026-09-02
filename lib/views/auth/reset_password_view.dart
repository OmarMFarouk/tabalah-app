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
import 'package:tabala/views/auth/validators.dart';

class ResetPasswordView extends StatefulWidget {
  final String email;

  const ResetPasswordView({super.key, required this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await context.read<AuthCubit>().resetPassword(
          email: widget.email,
          code: _codeController.text.trim(),
          password: _passwordController.text,
          passwordConfirmation: _confirmController.text,
        );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.redcolor),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('password_reset_success'.tr()), backgroundColor: AppColors.primarycolor),
    );

    // Pop all the way back to login - the reset revoked every existing
    // session token, so there's nothing to bootstrap into anyway.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
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
                  Text('reset_password_title'.tr(), style: AppStyles.bold24Black),
                  const SizedBox(height: 10),
                  Text(
                    'reset_password_desc'.tr(),
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
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('new_password'.tr(), style: AppStyles.medium14Grey),
                  ),
                  const SizedBox(height: 6),
                  CustomTextFormField(
                    controller: _passwordController,
                    obsecurtext: true,
                    denySpaces: true,
                    hinttext: 'new_password_hint'.tr(),
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text('confirm_password'.tr(), style: AppStyles.medium14Grey),
                  ),
                  const SizedBox(height: 6),
                  CustomTextFormField(
                    controller: _confirmController,
                    obsecurtext: true,
                    denySpaces: true,
                    hinttext: 'confirm_password_hint'.tr(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return Validators.password(v);
                      if (v != _passwordController.text) return 'confirm_password'.tr();
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: CustomElevatedButton(
                      text: _isLoading ? 'loading'.tr() : 'reset_password_button'.tr(),
                      onPressed: _isLoading ? null : _submit,
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
