import 'package:easy_localization/easy_localization.dart';

class Validators {
  static String? required(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'field_required'.tr();
    }
    return null;
  }

  /// A Saudi mobile number, but only if one was typed - the field is
  /// optional on the server, so an empty box must stay valid.
  ///
  /// Accepts the shapes people actually type: 05XXXXXXXX, 5XXXXXXXX,
  /// +9665XXXXXXXX and 009665XXXXXXXX.
  static String? optionalPhone(String? text) {
    final value = (text ?? '').trim();
    if (value.isEmpty) return null;

    final digits = value.replaceAll(RegExp(r'[^0-9+]'), '');
    final normalised = digits
        .replaceFirst(RegExp(r'^\+966'), '0')
        .replaceFirst(RegExp(r'^00966'), '0')
        .replaceFirst(RegExp(r'^966'), '0');

    final local = normalised.startsWith('5') ? '0$normalised' : normalised;

    return RegExp(r'^05[0-9]{8}$').hasMatch(local) ? null : 'invalid_phone'.tr();
  }

  static String? email(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'please_enter_email'.tr();
    }

    final bool emailValid = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(text);

    if (!emailValid) {
      return 'please_enter_valid_email'.tr();
    }

    return null;
  }

  /// The backend requires at least 8 characters (see RegisterRequest /
  /// LoginRequest), so this stays in sync with that.
  static String? password(String? text) {
    if (text == null || text.trim().isEmpty) {
      return 'please_enter_password'.tr();
    }

    if (text.length < 8) {
      return 'password_must_be_at_least_8_characters'.tr();
    }

    return null;
  }

  static String? confirmPassword(String? text, String original) {
    if (text == null || text.trim().isEmpty) {
      return 'please_confirm_password'.tr();
    }

    if (text != original) {
      return 'passwords_do_not_match'.tr();
    }

    return null;
  }
}
