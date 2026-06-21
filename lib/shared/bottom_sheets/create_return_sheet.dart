import 'package:flutter/material.dart';

import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_badge.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

enum _CreateReturnStep { search, orderInfo, returnDetails, selectItems }

Future<bool?> showCreateReturnSheet(
  BuildContext context, {
  String? prefillOrderId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => CreateReturnSheet(prefillOrderId: prefillOrderId),
  );
}

class CreateReturnSheet extends StatefulWidget {
  const CreateReturnSheet({
    super.key,
    this.prefillOrderId,
    this.fullScreen = false,
  });

  final String? prefillOrderId;
  final bool fullScreen;

  @override
  State<CreateReturnSheet> createState() => _CreateReturnSheetState();
}

class _CreateReturnSheetState extends State<CreateReturnSheet> {
  final _repo = ReturnsRepository();
  final _searchController = TextEditingController();
  final _channelRefController = TextEditingController();
  final _awbController = TextEditingController();

  late final Future<CreateReturnData> _configFuture = _repo.getCreateReturnConfig();

  String? _searchTypeId;
  CreateReturnOrder? _foundOrder;
  _CreateReturnStep _step = _CreateReturnStep.search;
  bool _searching = false;

  String? _returnType;
  String? _returnReason;
  String? _courierId;
  int? _warehouseId;
  final Map<String, bool> _selectedItems = {};
  final Map<String, int> _returnQty = {};

  @override
  void initState() {
    super.initState();
    if (widget.prefillOrderId != null) {
      _searchController.text = widget.prefillOrderId!;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _channelRefController.dispose();
    _awbController.dispose();
    super.dispose();
  }

  Future<void> _search(CreateReturnData config) async {
    final key = _searchController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(config.emptySearchMessage)),
      );
      return;
    }

    setState(() => _searching = true);
    await Future<void>.delayed(Duration(milliseconds: config.searchLoaderMs));
    if (!mounted) return;

    final order = config.knownOrders[key];
    setState(() {
      _searching = false;
      _foundOrder = order;
      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order not found')),
        );
        return;
      }
      if (order.allowReturn) {
        _step = _CreateReturnStep.orderInfo;
        _warehouseId ??=
            config.warehouses.firstWhere((w) => w.isDefault).id;
        _returnType ??= config.returnTypes.first;
        _returnReason ??= config.reasonsFor(_returnType).firstOrNull;
        _applyCourierReturnDefaults(config, order);
        _selectedItems.clear();
        _returnQty.clear();
        for (final item in order.items) {
          final selected = item.defaultSelected;
          _selectedItems[item.id] = selected;
          _returnQty[item.id] = selected
              ? (item.defaultReturnQty > 0 ? item.defaultReturnQty : 1)
              : 0;
        }
      }
    });
  }

  void _applyCourierReturnDefaults(CreateReturnData config, CreateReturnOrder order) {
    if (_returnType == 'Courier Return') {
      if (order.returnCourier != null) {
        final match = config.couriers
            .where((c) => c.name == order.returnCourier)
            .firstOrNull;
        _courierId = match?.id ?? config.couriers.firstOrNull?.id;
      }
      if (order.returnAwb != null) {
        _awbController.text = order.returnAwb!;
      }
    }
  }

  bool get _courierFieldsLocked =>
      _returnType == 'Courier Return' && _foundOrder?.returnCourier != null;

  bool get _canProceedFromOrderInfo => _warehouseId != null;

  bool get _canProceedFromDetails =>
      _returnType != null && _returnReason != null;

  bool get _canSubmit =>
      _foundOrder != null &&
      _returnType != null &&
      _returnReason != null &&
      _selectedItems.values.any((v) => v) &&
      _returnQty.values.any((q) => q > 0);

  void _onReturnTypeChanged(CreateReturnData config, String? type) {
    setState(() {
      _returnType = type;
      _returnReason = null;
      _courierId = null;
      _awbController.clear();
      if (type == 'Courier Return' && _foundOrder != null) {
        _applyCourierReturnDefaults(config, _foundOrder!);
      }
    });
  }

  Future<void> _submit(CreateReturnData config) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Return created successfully')),
    );
    await Future<void>.delayed(Duration(milliseconds: config.successRedirectMs));
    if (mounted) Navigator.pop(context, true);
  }

  void _goToStep(_CreateReturnStep step) => setState(() => _step = step);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return FutureBuilder<CreateReturnData>(
      future: _configFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final config = snapshot.data!;
        _searchTypeId ??= config.searchTypes.first.id;

        return Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: widget.fullScreen
                  ? _buildSheetBody(config, scrollController: null)
                  : DraggableScrollableSheet(
                      initialChildSize:
                          _step == _CreateReturnStep.search ? 0.55 : 0.88,
                      minChildSize: 0.4,
                      maxChildSize: 0.95,
                      expand: false,
                      builder: (context, scrollController) =>
                          _buildSheetBody(config, scrollController: scrollController),
                    ),
            ),
            if (_searching)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSheetBody(
    CreateReturnData config, {
    ScrollController? scrollController,
  }) {
    return Material(
      color: BtColors.surface,
      borderRadius: widget.fullScreen
          ? null
          : const BorderRadius.vertical(top: Radius.circular(28)),
      child: Column(
        children: [
          if (!widget.fullScreen) ...[
            const SizedBox(height: BtSpacing.md),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: BtColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BtSpacing.lg,
              BtSpacing.lg,
              BtSpacing.lg,
              BtSpacing.md,
            ),
            child: Text(
              'Create Return',
              style: BtTypography.headingXlSemibold,
            ),
          ),
          if (_step != _CreateReturnStep.search &&
              _foundOrder?.allowReturn == true)
            _CreateReturnStepper(current: _step),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(
                BtSpacing.lg,
                0,
                BtSpacing.lg,
                BtSpacing.lg,
              ),
              children: _buildStepContent(config),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(BtSpacing.lg),
              child: _buildActions(config),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStepContent(CreateReturnData config) {
    return [
      if (_step == _CreateReturnStep.search) ...[
        if (_foundOrder != null && !_foundOrder!.allowReturn)
          _OrderStatusCard(order: _foundOrder!),
        DropdownButtonFormField<String>(
          initialValue: _searchTypeId,
          decoration: const InputDecoration(labelText: 'Order ID'),
          items: config.searchTypes
              .map((t) => DropdownMenuItem(value: t.id, child: Text(t.label)))
              .toList(),
          onChanged: (v) => setState(() => _searchTypeId = v),
        ),
        const SizedBox(height: BtSpacing.md),
        BtSearchField(
          hint: config.searchTypes
              .firstWhere((t) => t.id == _searchTypeId)
              .placeholder,
          controller: _searchController,
        ),
      ],
      if (_step == _CreateReturnStep.orderInfo && _foundOrder != null) ...[
        _OrderStatusCard(order: _foundOrder!),
        const SizedBox(height: BtSpacing.lg),
        DropdownButtonFormField<int>(
          initialValue: _warehouseId,
          decoration: const InputDecoration(labelText: 'Return Warehouse'),
          items: config.warehouses
              .map((w) => DropdownMenuItem(value: w.id, child: Text(w.name)))
              .toList(),
          onChanged: (v) => setState(() => _warehouseId = v),
        ),
      ],
      if (_step == _CreateReturnStep.returnDetails) ...[
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _returnType,
                decoration: const InputDecoration(labelText: 'Return Type *'),
                items: config.returnTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => _onReturnTypeChanged(config, v),
              ),
            ),
            const SizedBox(width: BtSpacing.md),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _returnReason,
                decoration: const InputDecoration(labelText: 'Return Reason *'),
                items: config.reasonsFor(_returnType)
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _returnReason = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: BtSpacing.md),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _courierId,
                decoration: const InputDecoration(labelText: 'Return Courier'),
                items: config.couriers
                    .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: _courierFieldsLocked
                    ? null
                    : (v) => setState(() => _courierId = v),
              ),
            ),
            const SizedBox(width: BtSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _awbController,
                readOnly: _courierFieldsLocked,
                decoration: const InputDecoration(
                  labelText: 'Return AWB No.',
                  hintText: 'Enter AWB No.',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: BtSpacing.md),
        TextFormField(
          controller: _channelRefController,
          decoration: const InputDecoration(
            labelText: 'Channel Return Ref',
            hintText: 'Optional',
          ),
        ),
      ],
      if (_step == _CreateReturnStep.selectItems && _foundOrder != null) ...[
        Row(
          children: [
            Text(
              'Select Items for Return',
              style: BtTypography.bodyBaseSemibold,
            ),
            Text(
              ' *',
              style: BtTypography.bodyBaseSemibold.copyWith(
                color: BtColors.badgeRed,
              ),
            ),
          ],
        ),
        const SizedBox(height: BtSpacing.md),
        for (final item in _foundOrder!.items)
          _ItemCheckRow(
            item: item,
            selected: _selectedItems[item.id] ?? false,
            qty: _returnQty[item.id] ?? 0,
            onSelected: (v) {
              setState(() {
                _selectedItems[item.id] = v;
                if (v && (_returnQty[item.id] ?? 0) == 0) {
                  _returnQty[item.id] = 1;
                }
                if (!v) _returnQty[item.id] = 0;
              });
            },
            onQtyChanged: (q) => setState(() => _returnQty[item.id] = q),
          ),
      ],
    ];
  }

  Widget _buildActions(CreateReturnData config) {
    switch (_step) {
      case _CreateReturnStep.search:
        return BtPrimaryButton(
          label: 'Search',
          onPressed: _searching ? null : () => _search(config),
        );
      case _CreateReturnStep.orderInfo:
        return BtPrimaryButton(
          label: 'Create Return',
          onPressed: _canProceedFromOrderInfo
              ? () => _goToStep(_CreateReturnStep.returnDetails)
              : null,
        );
      case _CreateReturnStep.returnDetails:
        return Row(
          children: [
            Expanded(
              child: BtOutlineButton(
                label: 'Back',
                onPressed: () => _goToStep(_CreateReturnStep.orderInfo),
              ),
            ),
            const SizedBox(width: BtSpacing.md),
            Expanded(
              child: BtPrimaryButton(
                label: 'Next',
                onPressed: _canProceedFromDetails
                    ? () => _goToStep(_CreateReturnStep.selectItems)
                    : null,
              ),
            ),
          ],
        );
      case _CreateReturnStep.selectItems:
        return Row(
          children: [
            Expanded(
              child: BtOutlineButton(
                label: 'Back',
                onPressed: () => _goToStep(_CreateReturnStep.returnDetails),
              ),
            ),
            const SizedBox(width: BtSpacing.md),
            Expanded(
              child: BtPrimaryButton(
                label: 'Create Return',
                onPressed: _canSubmit ? () => _submit(config) : null,
              ),
            ),
          ],
        );
    }
  }
}

class _CreateReturnStepper extends StatelessWidget {
  const _CreateReturnStepper({required this.current});

  final _CreateReturnStep current;

  int get _index => switch (current) {
        _CreateReturnStep.orderInfo => 0,
        _CreateReturnStep.returnDetails => 1,
        _CreateReturnStep.selectItems => 2,
        _ => 0,
      };

  @override
  Widget build(BuildContext context) {
    const labels = ['Order Info', 'Return Details', 'Select Items'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BtSpacing.lg,
        0,
        BtSpacing.lg,
        BtSpacing.lg,
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= _index
                          ? BtColors.brandGreen
                          : BtColors.border,
                    ),
                  ),
                _StepDot(
                  number: '${i + 1}',
                  active: i == _index,
                  completed: i < _index,
                ),
              ],
            ],
          ),
          const SizedBox(height: BtSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < labels.length; i++)
                Text(
                  labels[i],
                  style: (i == _index
                          ? BtTypography.bodySmSemibold
                          : BtTypography.bodySmRegular)
                      .copyWith(
                    color: i == _index
                        ? BtColors.brandGreen
                        : BtColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.number,
    required this.active,
    required this.completed,
  });

  final String number;
  final bool active;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final filled = active || completed;
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? BtColors.brandGreen : BtColors.surface,
        border: Border.all(
          color: filled ? BtColors.brandGreen : BtColors.border,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        number,
        style: BtTypography.bodySmSemibold.copyWith(
          color: filled ? Colors.white : BtColors.textMuted,
        ),
      ),
    );
  }
}

class _OrderStatusCard extends StatelessWidget {
  const _OrderStatusCard({required this.order});

  final CreateReturnOrder order;

  Color _statusColor(String status) => switch (status) {
        'Shipped' => BtColors.chipSelectedBg,
        'Processing' => BtColors.badgeYellow,
        'Packing' => BtColors.badgeYellow,
        _ => BtColors.badgeYellow,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: BtSpacing.lg),
      padding: const EdgeInsets.all(BtSpacing.lg),
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Channel', style: BtTypography.bodySmRegular),
                    const SizedBox(height: 4),
                    Text(order.channel, style: BtTypography.bodyMdRegular),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Status', style: BtTypography.bodySmRegular),
                  const SizedBox(height: 4),
                  BtBadge(
                    label: order.orderStatus,
                    backgroundColor: _statusColor(order.orderStatus),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: BtSpacing.md),
          Text('Channel Order ID', style: BtTypography.bodySmRegular),
          const SizedBox(height: 4),
          Text(
            order.channelOrderRef,
            style: BtTypography.bodyBaseSemibold,
          ),
          if (!order.allowReturn) ...[
            const SizedBox(height: BtSpacing.md),
            Container(
              padding: const EdgeInsets.all(BtSpacing.md),
              decoration: BoxDecoration(
                color: BtColors.badgeRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
                border: Border.all(color: BtColors.badgeRed.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: BtColors.badgeRed, size: 18),
                  const SizedBox(width: BtSpacing.sm),
                  Expanded(
                    child: Text(
                      order.blockedMessage,
                      style: BtTypography.bodySmRegular.copyWith(
                        color: BtColors.badgeRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemCheckRow extends StatelessWidget {
  const _ItemCheckRow({
    required this.item,
    required this.selected,
    required this.qty,
    required this.onSelected,
    required this.onQtyChanged,
  });

  final CreateReturnOrderItem item;
  final bool selected;
  final int qty;
  final ValueChanged<bool> onSelected;
  final ValueChanged<int> onQtyChanged;

  String _truncateChannelId(String? id) {
    if (id == null || id.isEmpty) return '-';
    if (id.length <= 12) return id;
    return '${id.substring(0, 9)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: BtSpacing.md),
      padding: const EdgeInsets.all(BtSpacing.md),
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
        border: Border.all(color: BtColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: selected,
              onChanged: (v) => onSelected(v ?? false),
              activeColor: BtColors.brandGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: BtSpacing.sm),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BtColors.chipBg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.image_outlined, color: BtColors.textMuted),
          ),
          const SizedBox(width: BtSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF374151),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.sku,
                        style: BtTypography.bodyXsSemibold.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${item.qtyOrdered} Qty',
                      style: BtTypography.bodySmMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(item.name, style: BtTypography.bodySmMedium),
                Text(item.price, style: BtTypography.bodySmMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Channel ID',
                            style: BtTypography.bodySmRegular.copyWith(
                              color: BtColors.textMuted,
                            ),
                          ),
                          Text(
                            _truncateChannelId(item.channelItemId),
                            style: BtTypography.bodySmRegular.copyWith(
                              color: BtColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rev Set',
                            style: BtTypography.bodySmRegular.copyWith(
                              color: BtColors.textMuted,
                            ),
                          ),
                          Text(
                            item.revSet ?? '-',
                            style: BtTypography.bodySmRegular.copyWith(
                              color: BtColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (selected) ...[
                  const SizedBox(height: BtSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: qty > 1 ? () => onQtyChanged(qty - 1) : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        visualDensity: VisualDensity.compact,
                      ),
                      Text('$qty', style: BtTypography.bodyMdSemibold),
                      IconButton(
                        onPressed: qty < item.qtyReturnable
                            ? () => onQtyChanged(qty + 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
                if (item.qtyPreviouslyReturned > 0)
                  Text(
                    'Previously returned: ${item.qtyPreviouslyReturned}',
                    style: BtTypography.bodySmRegular.copyWith(
                      color: BtColors.textMuted,
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
