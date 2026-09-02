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
import 'package:tabala/views/auth/reset_password_view.dart';
import 'package:tabala/views/auth/validators.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final error = await context.read<AuthCubit>().forgotPassword(email: _emailController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.redcolor),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('reset_code_sent'.tr()), backgroundColor: AppColors.primarycolor),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ResetPasswordView(email: _emailController.text.trim())),
    );
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
            child: Column(
              children: [
                const SizedBox(height: 12),
                const CustomHeader(showBack: true),
                const SizedBox(height: 16),
                Text('forgot_password_title'.tr(), style: AppStyles.bold24Black),
                const SizedBox(height: 10),
                Text(
                  'forgot_password_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppStyles.regular14Grey,
                ),
                const SizedBox(height: 28),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('email'.tr(), style: AppStyles.medium14Grey),
                ),
                const SizedBox(height: 6),
                CustomTextFormField(
                  controller: _emailController,
                  hinttext: 'email_hint'.tr(),
                  keyboardtype: TextInputType.emailAddress,
                  denySpaces: true,
                  validator: Validators.email,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: CustomElevatedButton(
                    text: _isLoading ? 'loading'.tr() : 'send_reset_code'.tr(),
                    onPressed: _isLoading ? null : _submit,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
