import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/scanner/screens/bt_barcode_scanner_screen.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

class PicklistScanningScreen extends StatefulWidget {
  const PicklistScanningScreen({
    super.key,
    required this.session,
    required this.rejectionReasons,
  });

  final PicklistSession session;
  final List<String> rejectionReasons;

  @override
  State<PicklistScanningScreen> createState() => _PicklistScanningScreenState();
}

class _PicklistScanningScreenState extends State<PicklistScanningScreen> {
  final _scanController = TextEditingController();
  late List<PicklistOrderWithItems> _orders;

  @override
  void initState() {
    super.initState();
    _orders = widget.session.orders
        .map(
          (o) => PicklistOrderWithItems(
            id: o.id,
            customerName: o.customerName,
            channelRef: o.channelRef,
            status: o.status,
            items: o.items.map((i) => i).toList(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  List<PicklistOrderWithItems> get _activeOrders =>
      _orders.where((o) => !o.isComplete).toList();

  Future<void> _openScanner() async {
    final code = await openBarcodeScanner(context, title: 'Scan item');
    if (code != null && mounted) _scanItem(code);
  }

  void _scanItem(String code) {
    final itemId = widget.session.knownItemBarcodes[code];
    if (itemId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item not found in batch')),
      );
      return;
    }

    PicklistItem? target;
    PicklistOrderWithItems? order;
    for (final o in _orders) {
      for (final item in o.items) {
        if (item.id == itemId) {
          target = item;
          order = o;
          break;
        }
      }
      if (target != null) break;
    }

    if (target == null || order == null) return;

    if (target.requiresLot && !code.startsWith('LOT-')) {
      _promptLotCode(target, order);
      return;
    }

    _incrementPick(target, order, lotCode: code.startsWith('LOT-') ? code : null);
  }

  Future<void> _promptLotCode(
    PicklistItem item,
    PicklistOrderWithItems order,
  ) async {
    final lot = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: 'LOT-621301-A');
        return AlertDialog(
          title: const Text('Enter lot / batch code'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Lot code'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    if (lot != null && lot.isNotEmpty) {
      _incrementPick(item, order, lotCode: lot);
    }
  }

  void _incrementPick(
    PicklistItem target,
    PicklistOrderWithItems order, {
    String? lotCode,
  }) {
    setState(() {
      _orders = _orders.map((o) {
        if (o.id != order.id) return o;
        final items = o.items.map((item) {
          if (item.id != target.id) return item;
          final nextQty = (item.pickedQty + 1).clamp(0, item.requiredQty);
          return item.copyWith(pickedQty: nextQty, lotCode: lotCode ?? item.lotCode);
        }).toList();
        final complete = items.every((i) => i.isComplete);
        return o.copyWith(
          items: items,
          status: complete ? 'complete' : 'picking',
        );
      }).toList();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Picked ${target.sku}')),
    );
  }

  Future<void> _rejectOrder(PicklistOrderWithItems order) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(BtSpacing.lg),
              child: Text('Reject order', style: BtTypography.headingLgSemibold),
            ),
            for (final r in widget.rejectionReasons)
              ListTile(title: Text(r), onTap: () => Navigator.pop(context, r)),
          ],
        ),
      ),
    );
    if (reason == null) return;
    setState(() {
      _orders = _orders.map((o) {
        if (o.id != order.id) return o;
        return o.copyWith(status: 'rejected');
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.screenBg,
      appBar: AppBar(
        title: Text(widget.session.label),
        backgroundColor: BtColors.surface,
        foregroundColor: BtColors.textPrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(BtSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: BtSearchField(
                    hint: 'Scan item barcode',
                    controller: _scanController,
                    onSubmitted: (v) => _scanItem(v.trim()),
                  ),
                ),
                const SizedBox(width: BtSpacing.sm),
                Material(
                  color: BtColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                  child: InkWell(
                    onTap: _openScanner,
                    borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.qr_code_scanner),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: BtSpacing.lg),
              itemCount: _activeOrders.isEmpty ? 1 : _activeOrders.length,
              separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.md),
              itemBuilder: (context, index) {
                if (_activeOrders.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: Text(
                        'All orders picked',
                        style: BtTypography.bodyMdRegular,
                      ),
                    ),
                  );
                }
                final order = _activeOrders[index];
                return _OrderPickCard(
                  order: order,
                  onReject: () => _rejectOrder(order),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(BtSpacing.lg),
              child: BtPrimaryButton(
                label: 'Complete',
                onPressed: _activeOrders.isEmpty
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Picklist session completed')),
                        );
                        Navigator.pop(context);
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderPickCard extends StatelessWidget {
  const _OrderPickCard({required this.order, required this.onReject});

  final PicklistOrderWithItems order;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BtSpacing.lg),
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.customerName, style: BtTypography.bodyBaseSemibold),
                    Text(order.channelRef, style: BtTypography.bodySmRegular),
                  ],
                ),
              ),
              TextButton(onPressed: onReject, child: const Text('Reject')),
            ],
          ),
          const SizedBox(height: BtSpacing.md),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: BtSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: BtTypography.bodyMdMedium),
                        Text(
                          '${item.sku} · ${item.pickedQty} of ${item.requiredQty} picked',
                          style: BtTypography.bodySmRegular,
                        ),
                        if (item.lotCode != null)
                          Text(
                            'Lot: ${item.lotCode}',
                            style: BtTypography.bodySmRegular,
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    item.isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: item.isComplete ? BtColors.brandGreen : BtColors.textMuted,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
