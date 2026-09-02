import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

typedef onvalidator = String? Function(String?)?;

/// The app's text field. Parameter names are kept exactly as they were
/// (`hinttext`, `obsecurtext`, `keyboardtype`, ...) so every existing call
/// site keeps compiling; what changed is that the decoration now inherits
/// from the theme, which is what makes the auth and profile forms legible
/// in dark mode.
class CustomTextFormField extends StatelessWidget {
  final Color? colorborderSide;
  final String? hinttext;
  final TextStyle? hintstyle;
  final String? labletext;
  final TextStyle? lablestyle;
  final Widget? prefixicon;
  final Widget? sufixicon;
  final TextEditingController? controller;
  final onvalidator validator;
  final TextInputType keyboardtype;
  final bool obsecurtext;
  final String obscuringCharacter;
  final int? maxlines;
  final bool denySpaces;
  final bool enabled;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  /// Extra formatters, applied after the [denySpaces] filter so both can be
  /// used together - which the parent-code field does: it strips spaces and
  /// upper-cases as you type.
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextFormField({
    super.key,
    required this.controller,
    this.obscuringCharacter = '*',
    this.obsecurtext = false,
    this.keyboardtype = TextInputType.text,
    this.prefixicon,
    this.sufixicon,
    this.lablestyle,
    this.labletext,
    this.hintstyle,
    this.hinttext,
    this.validator,
    this.colorborderSide,
    this.maxlines,
    this.denySpaces = false,
    this.enabled = true,
    this.maxLength,
    this.onChanged,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final border = colorborderSide ?? AppColors.borderColor;

    OutlineInputBorder outline(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextFormField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      maxLength: maxLength,
      inputFormatters: [
        if (denySpaces) FilteringTextInputFormatter.deny(' '),
        ...?inputFormatters,
      ],
      maxLines: obsecurtext ? 1 : (maxlines ?? 1),
      keyboardType: keyboardtype,
      obscureText: obsecurtext,
      obscuringCharacter: obscuringCharacter,
      validator: validator,
      style: AppStyles.regular14Black,
      cursorColor: AppColors.goldInk,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surfacecolor,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        enabledBorder: outline(border),
        disabledBorder: outline(border),
        focusedBorder: outline(AppColors.goldInk, width: 1.6),
        errorBorder: outline(AppColors.redcolor),
        focusedErrorBorder: outline(AppColors.redcolor, width: 1.6),
        hintText: hinttext,
        hintStyle: hintstyle ?? AppStyles.regular14Grey,
        labelText: labletext,
        labelStyle: lablestyle ?? AppStyles.regular14Grey,
        errorStyle: AppStyles.regular12Grey.copyWith(color: AppColors.redcolor),
        prefixIcon: prefixicon,
        suffixIcon: sufixicon,
      ),
    );
  }
}
