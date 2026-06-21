import 'package:flutter/material.dart';

import 'package:bt_mobile/features/orders/repositories/orders_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_badge.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_secondary_tabs.dart';
import 'package:bt_mobile/features/scanner/screens/bt_barcode_scanner_screen.dart';
import 'package:bt_mobile/features/returns/screens/create_return_screen.dart';
import 'package:bt_mobile/features/orders/models/order_detail_models.dart';
import 'package:bt_mobile/features/orders/models/order_processing_models.dart';
import 'package:bt_mobile/shared/bottom_sheets/reject_order_sheet.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    this.rejectionReasons = const [],
    this.initialTabIndex = 0,
  });

  final OrderDetailData order;
  final List<String> rejectionReasons;
  final int initialTabIndex;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late int _tabIndex = widget.initialTabIndex;
  String? _selectedPackagingId;
  final _repo = OrdersRepository();
  final _barcodeController = TextEditingController();
  bool _processing = false;
  String? _processingLabel;

  OrderDetailData get order => widget.order;

  List<BtSecondaryTab> get _tabs {
    final tabs = <BtSecondaryTab>[
      const BtSecondaryTab(label: 'Info'),
      if (order.showShippingTab) const BtSecondaryTab(label: 'Shipping'),
      if (order.showReturnsTab) const BtSecondaryTab(label: 'Returns'),
      BtSecondaryTab(
        label: 'Txns',
        badge: order.transactionCount > 0 ? '${order.transactionCount}' : null,
      ),
    ];
    return tabs;
  }

  String get _activeTabLabel {
    final tabs = _tabs;
    if (_tabIndex < 0 || _tabIndex >= tabs.length) return 'Info';
    return tabs[_tabIndex].label;
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _openBarcodeScanner() async {
    final code = await openBarcodeScanner(context, title: 'Scan barcode');
    if (code != null && mounted) {
      setState(() => _barcodeController.text = code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.screenBg,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OrderDetailHeader(order: order),
                BtSecondaryTabs(
                  tabs: _tabs,
                  selectedIndex: _tabIndex,
                  onSelected: (i) => setState(() => _tabIndex = i),
                ),
                const Divider(height: 1, color: BtColors.border),
                Expanded(child: _buildTabBody()),
              ],
            ),
          ),
          if (_processing)
            ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: BtSpacing.lg),
                    Text(
                      _processingLabel ?? 'Processing…',
                      style: BtTypography.bodyMdMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Future<void> _onPrimaryAction(String action) async {
    final actions = await _repo.getProcessingActions();
    final config = actions.actionFor(action);
    if (config == null) {
      _showSnack(action);
      return;
    }

    if (config.type == 'sheet' && action == 'Assign Courier') {
      await _showAssignCourierSheet(actions);
      return;
    }

    setState(() {
      _processing = true;
      _processingLabel = config.loaderLabel;
    });
    await Future<void>.delayed(Duration(milliseconds: config.loaderMs));
    if (!mounted) return;
    setState(() => _processing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(config.successMessage)),
    );
  }

  Future<void> _showAssignCourierSheet(OrderProcessingActionsData actions) async {
    String? courierId = actions.couriers.first.id;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                BtSpacing.lg,
                BtSpacing.lg,
                BtSpacing.lg,
                MediaQuery.viewInsetsOf(context).bottom + BtSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Assign Courier', style: BtTypography.headingLgSemibold),
                  const SizedBox(height: BtSpacing.md),
                  DropdownButtonFormField<String>(
                    value: courierId,
                    items: actions.couriers
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setModalState(() => courierId = v),
                    decoration: const InputDecoration(labelText: 'Courier'),
                  ),
                  const SizedBox(height: BtSpacing.lg),
                  BtPrimaryButton(
                    label: 'Assign',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Courier assigned')),
      );
    }
  }

  Widget _buildTabBody() {
    return switch (_activeTabLabel) {
      'Shipping' => _ShippingTab(
        shipping: order.shipping,
        selectedPackagingId: _selectedPackagingId ?? order.shipping?.selectedPackagingId,
        onPackagingSelected: (id) => setState(() => _selectedPackagingId = id),
      ),
      'Returns' => _ReturnsTab(
        order: order,
        onCreateReturn: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CreateReturnScreen(prefillOrderId: order.id),
            ),
          );
        },
      ),
      'Txns' => _TransactionsTab(order: order),
      _ => _InfoTab(order: order),
    };
  }

  Widget? _buildActionBar() {
    if (order.primaryAction == null) return null;

    return Material(
      color: BtColors.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            BtSpacing.lg,
            BtSpacing.md,
            BtSpacing.lg,
            BtSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (order.showScanBar) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _barcodeController,
                        decoration: InputDecoration(
                          hintText: 'Scan or enter barcodes to accept',
                          hintStyle: BtTypography.bodyBaseRegular.copyWith(
                            color: BtColors.textMuted,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: BtSpacing.inputPaddingH,
                            vertical: BtSpacing.inputPaddingV,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: BtSpacing.sm),
                    Material(
                      color: BtColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                      child: InkWell(
                        onTap: _openBarcodeScanner,
                        borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.qr_code_scanner, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BtSpacing.md),
              ],
              Row(
                children: [
                  if (order.secondaryAction != null)
                    Expanded(
                      child: BtOutlineButton(
                        label: order.secondaryAction!,
                        onPressed: () => _onSecondaryAction(),
                      ),
                    ),
                  if (order.secondaryAction != null)
                    const SizedBox(width: BtSpacing.md),
                  Expanded(
                    flex: order.secondaryAction != null ? 2 : 1,
                    child: BtPrimaryButton(
                      label: order.primaryAction!,
                      onPressed: _processing
                          ? null
                          : () => _onPrimaryAction(order.primaryAction!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSecondaryAction() async {
    final action = order.secondaryAction;
    if (action == null) return;
    if (action == 'Reject Order' && widget.rejectionReasons.isNotEmpty) {
      final confirmed = await showRejectOrderSheet(
        context: context,
        reasons: widget.rejectionReasons,
      );
      if (confirmed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order rejected')),
        );
        Navigator.pop(context);
      }
      return;
    }
    _showSnack(action);
  }

  void _showSnack(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action — coming soon')),
    );
  }
}

class _OrderDetailHeader extends StatelessWidget {
  const _OrderDetailHeader({required this.order});

  final OrderDetailData order;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          BtSpacing.sm,
          BtSpacing.sm,
          BtSpacing.lg,
          BtSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.customerName, style: BtTypography.headingLgSemibold),
                  const SizedBox(height: 2),
                  Text(order.createdAt, style: BtTypography.bodySmRegular),
                ],
              ),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: order.badges.map(_badgeFor).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeFor(String label) {
    final isPaid = label == 'Paid' || label == 'Prepaid';
    final isPending = label.contains('Pending') || label.contains('Packing');
    return BtBadge(
      label: label,
      backgroundColor: isPaid
          ? BtColors.brandGreen
          : isPending
              ? BtColors.badgeYellow
              : BtColors.surfaceMuted,
      textColor: isPaid ? BtColors.surface : BtColors.textBody,
    );
  }
}

class _InfoTab extends StatelessWidget {
  const _InfoTab({required this.order});

  final OrderDetailData order;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(BtSpacing.lg),
      children: [
        _DetailCard(
          children: [
            _DetailField(label: 'Channel', value: order.channelName),
            _DetailField(label: 'Order Type', value: order.orderType),
            _DetailField(label: 'Channel Order #', value: order.channelOrderRef),
            _DetailField(label: 'Sub order#', value: order.subOrderId),
          ],
        ),
        const SizedBox(height: BtSpacing.lg),
        Row(
          children: [
            Text('Order Items', style: BtTypography.bodyMdMedium),
            const Spacer(),
            Text(
              '${order.itemCount} items · ${order.totalQty} Qty',
              style: BtTypography.bodyMdMedium.copyWith(
                color: BtColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: BtSpacing.md),
        for (final item in order.items) ...[
          _OrderItemCard(item: item, showAccept: order.showPartialAccept),
          const SizedBox(height: BtSpacing.lg),
        ],
        _OrderSummaryCard(order: order),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BtSpacing.lg),
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
        boxShadow: [
          BoxShadow(
            color: BtColors.brandGreen.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _DetailField extends StatelessWidget {
  const _DetailField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BtSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: BtTypography.bodySmRegular),
          const SizedBox(height: 2),
          Text(value, style: BtTypography.bodyMdMedium),
        ],
      ),
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({required this.item, required this.showAccept});

  final OrderDetailItem item;
  final bool showAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(BtSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: BtColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        color: BtColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: BtSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              BtSkuBadge(sku: item.sku),
                              const Spacer(),
                              Text('${item.qty} Qty', style: BtTypography.bodyMdMedium),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(item.name, style: BtTypography.bodyMdRegular),
                          const SizedBox(height: 4),
                          Text(item.price, style: BtTypography.bodyMdRegular),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BtSpacing.md),
                _ItemMeta(label: 'Item Ref', value: item.itemRef),
                _ItemMeta(label: 'Channel SKU', value: item.channelSku),
                _ItemMeta(label: 'Channel Product ID', value: item.channelProductId),
                _ItemMeta(label: 'ITO ID', value: item.itoId),
              ],
            ),
          ),
          if (showAccept && item.acceptQty != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: BtSpacing.lg,
                vertical: BtSpacing.md,
              ),
              decoration: const BoxDecoration(
                color: BtColors.chipBg,
                border: Border(top: BorderSide(color: BtColors.border)),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(BtSpacing.radiusLg),
                ),
              ),
              child: Row(
                children: [
                  Text('Accept Quantity', style: BtTypography.bodyMdMedium),
                  const Spacer(),
                  Container(
                    width: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: BtColors.surface,
                      borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                      border: Border.all(color: BtColors.borderInput),
                    ),
                    child: Center(
                      child: Text(
                        '${item.acceptQty}',
                        style: BtTypography.bodyMdMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.remove, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ItemMeta extends StatelessWidget {
  const _ItemMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: BtTypography.bodySmRegular),
          ),
          Expanded(
            child: Text(value, style: BtTypography.bodySmMedium),
          ),
        ],
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.order});

  final OrderDetailData order;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      children: [
        Text('Order Summary', style: BtTypography.bodyMdMedium),
        const SizedBox(height: BtSpacing.md),
        _SummaryRow(label: 'Shipping Fee', value: order.shippingFee),
        _SummaryRow(label: 'COD Fee', value: order.codFee),
        _SummaryRow(
          label: 'Discount',
          value: order.discount,
          valueColor: BtColors.badgeRed,
        ),
        const Divider(height: BtSpacing.xl),
        Row(
          children: [
            Text('Order Total', style: BtTypography.bodyMdMedium),
            const Spacer(),
            Text(order.orderTotal, style: BtTypography.bodyBaseMedium),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BtSpacing.sm),
      child: Row(
        children: [
          Text(label, style: BtTypography.bodySmRegular),
          const Spacer(),
          Text(
            value,
            style: BtTypography.bodyMdMedium.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab({required this.order});

  final OrderDetailData order;

  @override
  Widget build(BuildContext context) {
    final txns = order.transactions;

    if (txns.isEmpty) {
      return const _PlaceholderTab(
        icon: Icons.receipt_long_outlined,
        message: 'No transactions recorded for this order.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(BtSpacing.lg),
      itemCount: txns.length,
      separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.lg),
      itemBuilder: (context, index) {
        final txn = txns[index];
        return _DetailCard(
          children: [
            if (txn.isSystem)
              Padding(
                padding: const EdgeInsets.only(bottom: BtSpacing.sm),
                child: Text(
                  'System transaction',
                  style: BtTypography.bodySmSemibold.copyWith(
                    color: BtColors.brandGreen,
                  ),
                ),
              ),
            _DetailField(label: 'Received At', value: txn.receivedAt),
            _DetailField(label: 'Source', value: txn.source),
            _DetailField(label: 'Source Reference', value: txn.sourceReference),
            _DetailField(label: 'Gross Value', value: txn.grossValue),
          ],
        );
      },
    );
  }
}

class _ShippingTab extends StatelessWidget {
  const _ShippingTab({
    required this.shipping,
    required this.selectedPackagingId,
    required this.onPackagingSelected,
  });

  final OrderShippingInfo? shipping;
  final String? selectedPackagingId;
  final ValueChanged<String> onPackagingSelected;

  @override
  Widget build(BuildContext context) {
    if (shipping == null) {
      return const _PlaceholderTab(
        icon: Icons.local_shipping_outlined,
        message: 'Shipping details are not available yet.',
      );
    }

    PackagingOption? selected;
    for (final option in shipping!.packagingOptions) {
      if (option.id == selectedPackagingId) {
        selected = option;
        break;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(BtSpacing.lg),
      children: [
        _DetailCard(
          children: [
            Text('Tracking Info', style: BtTypography.bodyMdMedium),
            const SizedBox(height: BtSpacing.md),
            _DetailField(label: 'Courier Name', value: shipping!.courierName),
            _DetailField(label: 'Tracking Number', value: shipping!.trackingNumber),
          ],
        ),
        const SizedBox(height: BtSpacing.lg),
        _DetailCard(
          children: [
            Text('Package Details', style: BtTypography.bodyMdMedium),
            const SizedBox(height: BtSpacing.md),
            _DetailField(label: 'Dimensions', value: shipping!.dimensions),
            _DetailField(label: 'Weight', value: shipping!.weight),
            if (shipping!.packagingOpted) ...[
              const SizedBox(height: BtSpacing.md),
              if (selected == null && shipping!.selectedPackagingTitle == null) ...[
                Text('Select packaging', style: BtTypography.bodySmRegular),
                const SizedBox(height: BtSpacing.sm),
                for (final option in shipping!.packagingOptions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: BtSpacing.sm),
                    child: BtRadioOption(
                      label: option.label,
                      selected: selectedPackagingId == option.id,
                      onTap: () => onPackagingSelected(option.id),
                    ),
                  ),
              ] else ...[
                _DetailField(
                  label: 'Selected Package',
                  value: shipping!.selectedPackagingTitle ?? selected?.label ?? '',
                ),
                if (shipping!.selectedDimensions != null)
                  _DetailField(
                    label: 'Dimensions',
                    value: shipping!.selectedDimensions!,
                  ),
                if (shipping!.selectedWeight != null)
                  _DetailField(label: 'Weight', value: shipping!.selectedWeight!),
              ],
            ],
          ],
        ),
        if (shipping!.deliveryAddress != null) ...[
          const SizedBox(height: BtSpacing.lg),
          _DetailCard(
            children: [
              Text('Delivery Address', style: BtTypography.bodyMdMedium),
              const SizedBox(height: BtSpacing.md),
              Text(shipping!.deliveryAddress!.formatted, style: BtTypography.bodyMdRegular),
            ],
          ),
        ],
        if (shipping!.billingAddress != null) ...[
          const SizedBox(height: BtSpacing.lg),
          _DetailCard(
            children: [
              Text('Billing Address', style: BtTypography.bodyMdMedium),
              const SizedBox(height: BtSpacing.md),
              Text(shipping!.billingAddress!.formatted, style: BtTypography.bodyMdRegular),
            ],
          ),
        ],
      ],
    );
  }
}

class _ReturnsTab extends StatelessWidget {
  const _ReturnsTab({required this.order, required this.onCreateReturn});

  final OrderDetailData order;
  final VoidCallback onCreateReturn;

  @override
  Widget build(BuildContext context) {
    if (order.linkedReturns.isEmpty) {
      return _PlaceholderTab(
        icon: Icons.undo_outlined,
        message: 'No returns linked to this order yet.',
        actionLabel: 'Create Return',
        onAction: onCreateReturn,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(BtSpacing.lg),
      itemCount: order.linkedReturns.length,
      separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.lg),
      itemBuilder: (context, index) {
        final ret = order.linkedReturns[index];
        return _DetailCard(
          children: [
            _DetailField(label: 'Channel Return Ref', value: ret.channelReturnRef),
            _DetailField(label: 'Return Type', value: ret.returnType),
            _DetailField(label: 'Status', value: ret.status),
            _DetailField(label: 'AWB', value: ret.awb),
          ],
        );
      },
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(BtSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: BtColors.textMuted),
            const SizedBox(height: BtSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: BtTypography.bodyMdRegular,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: BtSpacing.lg),
              BtPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                expand: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
