import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:bt_mobile/core/services/camera_service.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';

/// Opens a full-screen barcode scanner and returns the scanned value.
Future<String?> openBarcodeScanner(
  BuildContext context, {
  String title = 'Scan barcode',
}) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => BtBarcodeScannerScreen(title: title),
    ),
  );
}

class BtBarcodeScannerScreen extends StatefulWidget {
  const BtBarcodeScannerScreen({
    super.key,
    this.title = 'Scan barcode',
  });

  final String title;

  @override
  State<BtBarcodeScannerScreen> createState() => _BtBarcodeScannerScreenState();
}

class _BtBarcodeScannerScreenState extends State<BtBarcodeScannerScreen> {
  bool _permissionGranted = false;
  bool _permissionChecked = false;
  bool _handledScan = false;
  String? _error;
  int _retryKey = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final granted = await ensureCameraPermission();
    if (!mounted) return;
    setState(() {
      _permissionChecked = true;
      _permissionGranted = granted;
      _error = granted ? null : 'Camera permission is required to scan barcodes.';
    });
  }

  void _retry() {
    setState(() {
      _error = null;
      _handledScan = false;
      _retryKey++;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handledScan) return;
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((v) => v.trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;

    _handledScan = true;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_permissionGranted)
            MobileScanner(
              key: ValueKey(_retryKey),
              fit: BoxFit.cover,
              onDetect: _onDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(BtSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 48),
                        const SizedBox(height: BtSpacing.md),
                        Text(
                          error.errorDetails?.message ?? 'Camera failed to start',
                          textAlign: TextAlign.center,
                          style: BtTypography.bodyMdRegular.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: BtSpacing.lg),
                        FilledButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          else if (_permissionChecked)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(BtSpacing.xl),
                child: Text(
                  _error ?? 'Camera unavailable',
                  textAlign: TextAlign.center,
                  style: BtTypography.bodyMdRegular.copyWith(color: Colors.white),
                ),
              ),
            )
          else
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                      Expanded(
                        child: Text(
                          widget.title,
                          style: BtTypography.headingLgSemibold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (!_permissionGranted && _permissionChecked)
                        TextButton(
                          onPressed: openAppSettings,
                          child: const Text('Settings'),
                        ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(BtSpacing.xl),
                  child: Container(
                    width: 260,
                    height: 180,
                    decoration: BoxDecoration(
                      border: Border.all(color: BtColors.brandGreen, width: 2),
                      borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  child: Text(
                    'Align the barcode within the frame',
                    style: BtTypography.bodySmRegular.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
