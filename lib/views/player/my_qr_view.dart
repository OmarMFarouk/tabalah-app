import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:tabala/components/general/club_widgets.dart';
import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// The player's stable identity QR, shown to a trainer who wants to mark
/// them present without picking them off a list.
///
/// The QR itself is always rendered dark-on-white regardless of theme -
/// scanners need the contrast, and inverting a QR breaks a lot of them.
class MyQrView extends StatelessWidget {
  final String qrToken;
  final String playerName;

  const MyQrView({super.key, required this.qrToken, required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldcolor,
      appBar: AppBar(title: Text('my_qr_code'.tr())),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClubAvatar(
                initial: playerName.isEmpty ? '?' : playerName[0].toUpperCase(),
                size: 64,
                ring: true,
              ),
              const SizedBox(height: 14),
              Text(playerName, style: AppStyles.bold20Black),
              const SizedBox(height: 6),
              Text(
                'my_qr_code_desc'.tr(),
                style: AppStyles.regular14Grey,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: .4),
                    width: 2,
                  ),
                ),
                child: QrImageView(
                  data: qrToken,
                  version: QrVersions.auto,
                  size: 224,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: AppColors.clubGreenDeep,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0A180F),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
