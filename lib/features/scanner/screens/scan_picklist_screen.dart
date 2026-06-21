import 'package:flutter/material.dart';

import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/scanner/screens/bt_barcode_scanner_screen.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';
import 'package:bt_mobile/features/scanner/screens/picklist_scanning_screen.dart';

class ScanPicklistScreen extends StatefulWidget {
  const ScanPicklistScreen({super.key});

  @override
  State<ScanPicklistScreen> createState() => _ScanPicklistScreenState();
}

class _ScanPicklistScreenState extends State<ScanPicklistScreen> {
  final _repo = ReturnsRepository();
  final _batchScanController = TextEditingController();
  late Future<ScanPicklistData> _future = _repo.getScanPicklist();

  final Set<String> _selectedBatchIds = {};

  @override
  void dispose() {
    _batchScanController.dispose();
    super.dispose();
  }

  Color _badgeColor(String status) => switch (status) {
        'fully_picked' => BtColors.brandGreen,
        'partially_picked' => BtColors.badgeYellow,
        _ => BtColors.textMuted,
      };

  void _toggleBatch(PicklistBatch batch) {
    if (batch.isLocked) return;
    setState(() {
      if (_selectedBatchIds.contains(batch.id)) {
        _selectedBatchIds.remove(batch.id);
      } else {
        _selectedBatchIds.add(batch.id);
      }
    });
  }

  Future<void> _openBatchScanner(ScanPicklistData data) async {
    final code = await openBarcodeScanner(context, title: 'Scan batch');
    if (code != null && mounted) _scanBatchCode(data, code);
  }

  void _scanBatchCode(ScanPicklistData data, String code) {
    final batchId = data.batchBarcodes[code];
    if (batchId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch not found')),
      );
      return;
    }
    final batch = data.batches.firstWhere((b) => b.id == batchId);
    if (batch.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch in use by ${batch.lockedBy}')),
      );
      return;
    }
    setState(() => _selectedBatchIds.add(batchId));
  }

  void _startScanning(ScanPicklistData data) {
    if (_selectedBatchIds.isEmpty) return;
    final batchId = _selectedBatchIds.first;
    final session = data.sessionFor(batchId);
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No picking session for batch')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PicklistScanningScreen(
          session: session,
          rejectionReasons: data.rejectionReasons,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.screenBg,
      appBar: AppBar(
        title: const Text('Scan Picklist'),
        backgroundColor: BtColors.surface,
        foregroundColor: BtColors.textPrimary,
        elevation: 1,
      ),
      body: FutureBuilder<ScanPicklistData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  children: [
                    Text(data.warehouseName, style: BtTypography.bodySmRegular),
                    const SizedBox(height: BtSpacing.lg),
                    Text('Scan batch barcode', style: BtTypography.bodyMdMedium),
                    const SizedBox(height: BtSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: BtSearchField(
                            hint: 'Scan picklist sheet',
                            controller: _batchScanController,
                            onSubmitted: (v) => _scanBatchCode(data, v.trim()),
                          ),
                        ),
                        const SizedBox(width: BtSpacing.sm),
                        Material(
                          color: BtColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                          child: InkWell(
                            onTap: () => _openBatchScanner(data),
                            borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(Icons.qr_code_scanner),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: BtSpacing.xl),
                    Text('Available Batches', style: BtTypography.bodyMdMedium),
                    const SizedBox(height: BtSpacing.md),
                    for (final batch in data.batches)
                      _BatchTile(
                        batch: batch,
                        selected: _selectedBatchIds.contains(batch.id),
                        badgeColor: _badgeColor(batch.status),
                        onTap: () => _toggleBatch(batch),
                      ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  child: BtPrimaryButton(
                    label: 'Start Scanning',
                    onPressed: _selectedBatchIds.isEmpty
                        ? null
                        : () => _startScanning(data),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BatchTile extends StatelessWidget {
  const _BatchTile({
    required this.batch,
    required this.selected,
    required this.badgeColor,
    required this.onTap,
  });

  final PicklistBatch batch;
  final bool selected;
  final Color badgeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? BtColors.chipBg : BtColors.surface,
      child: ListTile(
        onTap: batch.isLocked ? null : onTap,
        title: Text(batch.label, style: BtTypography.bodyBaseSemibold),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${batch.orderCount} orders · ${batch.createdAt}'),
            if (batch.isLocked)
              Text(
                'In use by ${batch.lockedBy}',
                style: BtTypography.bodySmRegular.copyWith(
                  color: BtColors.badgeRed,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              batch.statusLabel,
              style: BtTypography.bodySmSemibold.copyWith(color: badgeColor),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: BtColors.brandGreen, size: 18),
          ],
        ),
      ),
    );
  }
}
