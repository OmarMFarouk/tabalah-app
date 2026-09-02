import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tabala/components/general/club_logo.dart';
import 'package:tabala/components/general/custom_header.dart';
import 'package:tabala/components/general/custom_elevated_button.dart';
import 'package:tabala/components/general/custom_text_form_field.dart';
import 'package:tabala/cubits/auth/auth_cubit.dart';
import 'package:tabala/views/auth/verify_email_view.dart';
import 'package:tabala/cubits/auth/auth_state.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';
import 'package:tabala/views/auth/validators.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final heightController = TextEditingController();
  final weightController = TextEditingController();
  final emergencyContactController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    heightController.dispose();
    weightController.dispose();
    emergencyContactController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().registerPlayer(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
          passwordConfirmation: confirmPasswordController.text,
          phone: phoneController.text.trim(),
          height: num.tryParse(heightController.text),
          weight: num.tryParse(weightController.text),
          emergencyContact: emergencyContactController.text.trim(),
        );
  }

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
            MaterialPageRoute(
              builder: (_) => VerifyEmailView(email: state.email),
            ),
          );
        }
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
                    const SizedBox(height: 16),
                    Text("create_account".tr(), style: AppStyles.bold24Black),
                    const SizedBox(height: 10),
                    Text(
                      "register_description".tr(),
                      textAlign: TextAlign.center,
                      style: AppStyles.regular14Grey,
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
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
                              validator: (value) =>
                                  Validators.confirmPassword(value, passwordController.text),
                            ),
                            const SizedBox(height: 16),
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
                            // The only field whose hint was a bare number
                            // mask, so nothing on screen said what it was
                            // for. Labelled, and given the phone keyboard
                            // the other number fields already had.
                            CustomTextFormField(
                              controller: emergencyContactController,
                              hinttext: "emergency_contact_hint".tr(),
                              keyboardtype: TextInputType.phone,
                              denySpaces: true,
                              validator: Validators.optionalPhone,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: CustomElevatedButton(
                        text: isLoading ? "loading".tr() : "create_account".tr(),
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
}
