import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/components/general/qr_scanner_page.dart';
import 'package:tabala/cubits/session_detail_cubit.dart';

/// The trainer scans a player's personal identity QR against this session.
///
/// The cubit is passed in rather than created here: it already knows which
/// session is open, and reusing it means the roster behind the scanner
/// refreshes as soon as the scan lands.
class ScanPlayerQrView extends StatelessWidget {
  final SessionDetailCubit cubit;

  const ScanPlayerQrView({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return QrScannerPage(
      title: 'scan_player'.tr(),
      instructions: 'scan_player_instructions'.tr(),
      onCode: (code) => cubit.scanPlayerQr(code),
    );
  }
}
