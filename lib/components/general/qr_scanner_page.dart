import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:tabala/src/colors/app_colors.dart';
import 'package:tabala/src/theme/app_styles.dart';

/// Generic camera QR scanner. The caller decides what a scanned code means
/// (a session check-in token, a player identity token) via [onCode], which
/// returns null on success or an error message to show while scanning
/// continues.
///
/// The scanner is always dark - it sits over a camera feed, so it ignores
/// the app theme by design.
class QrScannerPage extends StatefulWidget {
  final String title;
  final String instructions;
  final Future<String?> Function(String code) onCode;

  const QrScannerPage({
    super.key,
    required this.title,
    required this.instructions,
    required this.onCode,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final code = capture.barcodes.isEmpty ? null : capture.barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _lastError = null;
    });

    // Stop before awaiting: the detector fires continuously, and a slow
    // round trip would otherwise queue up several check-in requests for the
    // same code.
    await _controller.stop();
    final error = await widget.onCode(code);

    if (!mounted) return;

    if (error == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isProcessing = false;
      _lastError = error;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title, style: AppStyles.bold18White),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, state, child) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_rounded,
              ),
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _handleDetect),
          const _ScannerFrame(),
          Positioned(
            left: 24,
            right: 24,
            bottom: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_lastError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      // white on the bright red measured 3.00:1; this fill clears 5.44:1
                      color: const Color(0xFFC0392B),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_lastError!, style: AppStyles.medium14White),
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _isProcessing ? 'processing'.tr() : widget.instructions,
                    style: AppStyles.medium14White,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatelessWidget {
  const _ScannerFrame();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 244,
          height: 244,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary, width: 3),
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
