import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'package:bt_mobile/core/services/camera_service.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

class AcknowledgeScannerScreen extends StatefulWidget {
  const AcknowledgeScannerScreen({
    super.key,
    required this.onScan,
    required this.scanned,
  });

  final ValueChanged<String> onScan;
  final List<AckReturnScan> scanned;

  @override
  State<AcknowledgeScannerScreen> createState() =>
      _AcknowledgeScannerScreenState();
}

class _AcknowledgeScannerScreenState extends State<AcknowledgeScannerScreen> {
  bool _permissionGranted = false;
  bool _permissionChecked = false;
  String? _lastMessage;
  bool _lastError = false;
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
    });
  }

  void _retry() => setState(() => _retryKey++);

  void _scan(String code) {
    widget.onScan(code);
    setState(() {
      _lastMessage = 'Scanned $code';
      _lastError = false;
    });
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes
        .map((b) => b.rawValue)
        .whereType<String>()
        .map((v) => v.trim())
        .firstWhere((v) => v.isNotEmpty, orElse: () => '');
    if (value.isEmpty) return;
    _scan(value);
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
              child: Text(
                'Camera permission is required',
                style: BtTypography.bodyMdRegular.copyWith(color: Colors.white),
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
                          'Acknowledge Returns',
                          style: BtTypography.headingLgSemibold.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.scanned.length} added',
                        style: BtTypography.bodySmSemibold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 260,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(color: BtColors.brandGreen, width: 2),
                        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                      ),
                    ),
                  ),
                ),
                if (_lastMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BtSpacing.lg),
                    child: Text(
                      _lastMessage!,
                      style: BtTypography.bodySmRegular.copyWith(
                        color: _lastError ? BtColors.badgeRed : BtColors.brandGreen,
                      ),
                    ),
                  ),
                if (widget.scanned.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(
                      BtSpacing.lg,
                      BtSpacing.md,
                      BtSpacing.lg,
                      BtSpacing.lg,
                    ),
                    padding: const EdgeInsets.all(BtSpacing.lg),
                    decoration: BoxDecoration(
                      color: BtColors.surface,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(BtSpacing.radiusXl),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Order Acknowledged', style: BtTypography.bodyMdMedium),
                        const SizedBox(height: BtSpacing.sm),
                        for (final item in widget.scanned.take(2))
                          _AcknowledgedCard(item: item),
                      ],
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

class _AcknowledgedCard extends StatelessWidget {
  const _AcknowledgedCard({required this.item});

  final AckReturnScan item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: BtSpacing.sm),
      padding: const EdgeInsets.all(BtSpacing.md),
      decoration: BoxDecoration(
        color: BtColors.chipBg,
        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
        border: Border.all(color: BtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.channelReturnRef, style: BtTypography.bodyBaseSemibold),
          Text(item.returnType, style: BtTypography.bodySmRegular),
          Text(
            '${item.channel} · Order ${item.orderRef}',
            style: BtTypography.bodySmRegular,
          ),
          Text('AWB ${item.awb}', style: BtTypography.bodySmRegular),
        ],
      ),
    );
  }
}
