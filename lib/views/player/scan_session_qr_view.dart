import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:tabala/components/general/qr_scanner_page.dart';
import 'package:tabala/cubits/attendance_cubit.dart';

/// The player scans the QR the trainer is displaying for the session.
///
/// The token is a UUID from `membership_sessions.qr_token`. The backend
/// rejects the check-in if the session is cancelled or completed, if the
/// clock is outside the session's attendance window (its start and end plus
/// a 30 minute grace either side), or if the player has no *active*
/// enrollment in that membership - a pending-payment enrollment is not
/// enough - and each of those comes back as its own message, which the
/// scanner surfaces verbatim.
class ScanSessionQrView extends StatefulWidget {
  const ScanSessionQrView({super.key});

  @override
  State<ScanSessionQrView> createState() => _ScanSessionQrViewState();
}

class _ScanSessionQrViewState extends State<ScanSessionQrView> {
  late final AttendanceCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = AttendanceCubit();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QrScannerPage(
      title: 'scan_session_qr'.tr(),
      instructions: 'scan_session_qr_instructions'.tr(),
      onCode: _cubit.checkIn,
    );
  }
}
