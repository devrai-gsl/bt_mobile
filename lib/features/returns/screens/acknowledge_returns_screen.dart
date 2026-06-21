import 'package:flutter/material.dart';

import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/features/scanner/screens/acknowledge_scanner_screen.dart';
import 'package:bt_mobile/features/returns/screens/acknowledge_success_screen.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

class AcknowledgeReturnsScreen extends StatefulWidget {
  const AcknowledgeReturnsScreen({super.key});

  @override
  State<AcknowledgeReturnsScreen> createState() =>
      _AcknowledgeReturnsScreenState();
}

class _AcknowledgeReturnsScreenState extends State<AcknowledgeReturnsScreen> {
  final _repo = ReturnsRepository();
  final _manualController = TextEditingController();
  late Future<ReturnsAcknowledgeData> _configFuture = _repo.getAcknowledgeConfig();

  String? _channelId;
  int? _warehouseId;
  final List<AckReturnScan> _scanned = [];
  bool _showSummary = false;

  @override
  void dispose() {
    _manualController.dispose();
    super.dispose();
  }

  bool get _canProceed => _channelId != null && _warehouseId != null;

  void _addScan(AckReturnScan item) {
    if (_scanned.any((e) => e.id == item.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Already added')),
      );
      return;
    }
    setState(() => _scanned.add(item));
  }

  void _scanBarcode(String code) {
    final config = _configFuture;
    config.then((data) {
      final hit = data.knownBarcodes[code];
      if (hit == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Return not found — try manual entry')),
        );
        return;
      }
      final multi = data.multiReturnGroups[code];
      if (multi != null && multi.length > 1) {
        _showMultiPicker(multi);
        return;
      }
      _addScan(hit);
    });
  }

  Future<void> _showMultiPicker(List<AckReturnScan> options) async {
    final picked = await showModalBottomSheet<AckReturnScan>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(BtSpacing.lg),
              child: Text('Select Return', style: BtTypography.headingLgSemibold),
            ),
            for (final option in options)
              ListTile(
                title: Text(option.channelReturnRef),
                subtitle: Text('${option.channel} · ${option.awb}'),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );
    if (picked != null) _addScan(picked);
  }

  void _manualAdd() {
    final code = _manualController.text.trim();
    if (code.isEmpty) return;
    _scanBarcode(code);
    _manualController.clear();
  }

  Future<void> _showOtpDialog(AckOtpPreview otp) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Acknowledgement OTP'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Channel: ${otp.channelName}'),
            Text('Courier: ${otp.courierName}'),
            Text('Returns: ${otp.returnsCount}'),
            const SizedBox(height: BtSpacing.lg),
            Text(
              otp.otp,
              style: BtTypography.headingXlSemibold.copyWith(
                letterSpacing: 4,
                color: BtColors.brandGreen,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Share OTP'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _completeAck(ReturnsAcknowledgeData config) async {
    final needsOtp = config.channelRequiresOtp(_channelId);
    if (needsOtp) {
      await _showOtpDialog(config.otpPreview);
    }
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcknowledgeSuccessScreen(
          info: config.success,
          items: List<AckReturnScan>.from(_scanned),
          showOtp: needsOtp,
          otp: needsOtp ? config.otpPreview : null,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _scanned.clear();
      _showSummary = false;
      _channelId = null;
      _warehouseId = config.warehouses
          .firstWhere((w) => w.isDefault, orElse: () => config.warehouses.first)
          .id;
    });
  }

  Future<void> _openScanner(ReturnsAcknowledgeData config) async {
    if (!_canProceed) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AcknowledgeScannerScreen(
          scanned: _scanned,
          onScan: _scanBarcode,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.screenBg,
      appBar: AppBar(
        title: const Text('Acknowledge Returns'),
        backgroundColor: BtColors.surface,
        foregroundColor: BtColors.textPrimary,
        elevation: 1,
      ),
      body: FutureBuilder<ReturnsAcknowledgeData>(
        future: _configFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final config = snapshot.data!;
          _warehouseId ??= config.warehouses
              .firstWhere((w) => w.isDefault, orElse: () => config.warehouses.first)
              .id;

          if (_showSummary && _scanned.isNotEmpty) {
            return _SummaryStep(
              items: _scanned,
              onBack: () => setState(() => _showSummary = false),
              onConfirm: () => _completeAck(config),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(BtSpacing.lg),
            children: [
              Text('Select Channel and Warehouse', style: BtTypography.bodyMdMedium),
              const SizedBox(height: BtSpacing.md),
              DropdownButtonFormField<String>(
                value: _channelId,
                decoration: const InputDecoration(labelText: 'Select Channel'),
                items: config.channels
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _channelId = v),
              ),
              const SizedBox(height: BtSpacing.md),
              DropdownButtonFormField<int>(
                value: _warehouseId,
                decoration: const InputDecoration(labelText: 'Select Warehouse'),
                items: config.warehouses
                    .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (v) => setState(() => _warehouseId = v),
              ),
              if (_channelId != null && !config.channelRequiresOtp(_channelId)) ...[
                const SizedBox(height: BtSpacing.md),
                Container(
                  padding: const EdgeInsets.all(BtSpacing.md),
                  decoration: BoxDecoration(
                    color: BtColors.chipBg,
                    borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                    border: Border.all(color: BtColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: BtColors.brandGreen, size: 20),
                      const SizedBox(width: BtSpacing.sm),
                      Expanded(
                        child: Text(
                          'No OTP required for this channel',
                          style: BtTypography.bodySmRegular,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (config.showOtpWithoutAck &&
                  _channelId != null &&
                  config.channelRequiresOtp(_channelId)) ...[
                const SizedBox(height: BtSpacing.lg),
                BtOutlineButton(
                  label: 'Get OTP',
                  onPressed: () => _showOtpDialog(config.otpPreview),
                ),
              ],
              const SizedBox(height: BtSpacing.xl),
              Text('Scan or Search Returns', style: BtTypography.bodyMdMedium),
              const SizedBox(height: BtSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: BtSearchField(
                      hint: 'Scan AWB / Return ID',
                      controller: _manualController,
                      onSubmitted: _canProceed ? (_) => _manualAdd() : null,
                    ),
                  ),
                  const SizedBox(width: BtSpacing.sm),
                  Material(
                    color: BtColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                    child: InkWell(
                      onTap: _canProceed ? () => _openScanner(config) : null,
                      borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.qr_code_scanner),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: BtSpacing.lg),
              Text(
                '${_scanned.length} return${_scanned.length == 1 ? '' : 's'} added',
                style: BtTypography.bodySmRegular,
              ),
              const SizedBox(height: BtSpacing.md),
              for (final item in _scanned)
                Card(
                  child: ListTile(
                    title: Text(item.channelReturnRef),
                    subtitle: Text('${item.channel} · ${item.awb}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _scanned.removeWhere((e) => e.id == item.id)),
                    ),
                  ),
                ),
              const SizedBox(height: BtSpacing.xl),
              BtPrimaryButton(
                label: 'Complete Scanning',
                onPressed: _scanned.isEmpty
                    ? null
                    : () => setState(() => _showSummary = true),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  const _SummaryStep({
    required this.items,
    required this.onBack,
    required this.onConfirm,
  });

  final List<AckReturnScan> items;
  final VoidCallback onBack;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BtSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Summary', style: BtTypography.headingLgSemibold),
          const SizedBox(height: BtSpacing.lg),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, index) {
                final item = items[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Row('Channel Return Ref', item.channelReturnRef),
                    _Row('Channel', item.channel),
                    _Row('Return Type', item.returnType),
                    _Row('AWB', item.awb),
                    _Row('Order Ref', item.orderRef),
                  ],
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(child: BtOutlineButton(label: 'Back', onPressed: onBack)),
              const SizedBox(width: BtSpacing.md),
              Expanded(
                child: BtPrimaryButton(
                  label: 'Save and Acknowledge',
                  onPressed: onConfirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: BtTypography.bodySmRegular)),
          Expanded(child: Text(value, style: BtTypography.bodyMdMedium)),
        ],
      ),
    );
  }
}
