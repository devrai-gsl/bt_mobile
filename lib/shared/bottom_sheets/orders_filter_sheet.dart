import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/features/orders/models/orders_filter_definitions.dart';
import 'package:bt_mobile/features/orders/models/orders_filter_state.dart';

Future<OrdersFilterState?> showOrdersFilterSheet({
  required BuildContext context,
  required OrdersFilterState initial,
}) {
  return showModalBottomSheet<OrdersFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _OrdersFilterSheet(initial: initial),
  );
}

class _OrdersFilterSheet extends StatefulWidget {
  const _OrdersFilterSheet({required this.initial});

  final OrdersFilterState initial;

  @override
  State<_OrdersFilterSheet> createState() => _OrdersFilterSheetState();
}

class _OrdersFilterSheetState extends State<_OrdersFilterSheet> {
  late OrdersFilterState _draft;
  final _searchController = TextEditingController();
  final _productFamilyController = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
    _productFamilyController.text = widget.initial.productFamilyQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _productFamilyController.dispose();
    super.dispose();
  }

  List<OrderFilterSectionDef> get _visibleSections {
    if (_search.trim().isEmpty) return orderFilterSections;
    final q = _search.toLowerCase();
    return orderFilterSections.where((section) {
      if (section.title.toLowerCase().contains(q)) return true;
      return section.options.any((o) => o.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _pickCustomRange(String sectionId, String sectionTitle) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _draft.customRanges[sectionId] ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: '$sectionTitle range',
    );
    if (picked == null || !mounted) return;
    setState(() {
      final nextRanges = Map<String, DateTimeRange>.from(_draft.customRanges)
        ..[sectionId] = picked;
      final nextKeys = Set<String>.from(_draft.selectedKeys)
        ..removeWhere((k) => k.startsWith('$sectionId::'));
      _draft = _draft.copyWith(
        selectedKeys: nextKeys,
        customRanges: nextRanges,
      );
    });
  }

  void _toggleChip(String sectionId, String value) {
    setState(() {
      final key = orderFilterKey(sectionId, value);
      final nextRanges = Map<String, DateTimeRange>.from(_draft.customRanges)
        ..remove(sectionId);
      _draft = _draft.toggle(key).copyWith(customRanges: nextRanges);
    });
  }

  bool _isCustomRangeActive(String sectionId) =>
      _draft.customRanges.containsKey(sectionId);

  @override
  Widget build(BuildContext context) {
    final draftCount = _draft.count;
    final hasDraft = draftCount > 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: BtColors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BtSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 52,
              height: 4,
              decoration: BoxDecoration(
                color: BtColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BtSpacing.xl,
                BtSpacing.lg,
                BtSpacing.lg,
                BtSpacing.md,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Filter', style: BtTypography.headingXlSemibold),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: BtSpacing.xl),
              child: BtSearchField(
                hint: 'Search filters',
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: BtSpacing.xl),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: BtSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final section in _visibleSections) ...[
                      if (section.separatorBefore) ...[
                        const Divider(height: BtSpacing.xl),
                        const SizedBox(height: BtSpacing.xl),
                      ],
                      _FilterSection(
                        section: section,
                        draft: _draft,
                        productFamilyController: _productFamilyController,
                        onProductFamilyChanged: (v) {
                          setState(
                            () => _draft = _draft.copyWith(productFamilyQuery: v),
                          );
                        },
                        onToggleChip: _toggleChip,
                        onCustomRange: _pickCustomRange,
                        isCustomRangeActive: _isCustomRangeActive,
                      ),
                      const SizedBox(height: BtSpacing.xl),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(BtSpacing.xl),
              child: Row(
                children: [
                  Expanded(
                    child: BtOutlineButton(
                      label: hasDraft ? 'Reset Filters' : 'Cancel',
                      onPressed: () {
                        if (hasDraft) {
                          setState(() {
                            _draft = const OrdersFilterState();
                            _productFamilyController.clear();
                          });
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: BtSpacing.md),
                  Expanded(
                    child: BtPrimaryButton(
                      label: hasDraft
                          ? 'Apply $draftCount Filter${draftCount == 1 ? '' : 's'}'
                          : 'Apply Filters',
                      onPressed: () => Navigator.pop(context, _draft),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.section,
    required this.draft,
    required this.productFamilyController,
    required this.onProductFamilyChanged,
    required this.onToggleChip,
    required this.onCustomRange,
    required this.isCustomRangeActive,
  });

  final OrderFilterSectionDef section;
  final OrdersFilterState draft;
  final TextEditingController productFamilyController;
  final ValueChanged<String> onProductFamilyChanged;
  final void Function(String sectionId, String value) onToggleChip;
  final Future<void> Function(String sectionId, String sectionTitle) onCustomRange;
  final bool Function(String sectionId) isCustomRangeActive;

  @override
  Widget build(BuildContext context) {
    if (section.kind == OrderFilterSectionKind.productFamily) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.title, style: BtTypography.bodyMdMedium),
          const SizedBox(height: 6),
          TextField(
            controller: productFamilyController,
            onChanged: onProductFamilyChanged,
            style: BtTypography.bodyBaseRegular,
            decoration: const InputDecoration(
              hintText: 'Match by family name',
            ),
          ),
          const SizedBox(height: BtSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: section.options.map((option) {
              final key = orderFilterKey(section.id, option);
              return _OrdersFilterChip(
                label: option,
                selected: draft.selectedKeys.contains(key),
                onTap: () => onToggleChip(section.id, option),
                leading: const Icon(Icons.category_outlined, size: 16),
              );
            }).toList(),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(section.title, style: BtTypography.bodyMdMedium),
        const SizedBox(height: BtSpacing.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in section.options)
              _OrdersFilterChip(
                label: option,
                selected: draft.selectedKeys
                    .contains(orderFilterKey(section.id, option)),
                onTap: () => onToggleChip(section.id, option),
              ),
            if (section.customRange)
              _OrdersFilterChip(
                label: 'Custom Range',
                selected: isCustomRangeActive(section.id),
                onTap: () => onCustomRange(section.id, section.title),
                leading: const Icon(Icons.calendar_today_outlined, size: 16),
              ),
          ],
        ),
      ],
    );
  }
}

class _OrdersFilterChip extends StatelessWidget {
  const _OrdersFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: leading,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: BtTypography.bodyMdMedium.copyWith(
        color: selected ? BtColors.chipText : BtColors.textBody,
      ),
      backgroundColor: BtColors.chipBg,
      selectedColor: BtColors.brandGreen,
      checkmarkColor: BtColors.surface,
      side: BorderSide(
        color: selected ? BtColors.brandGreen : BtColors.border,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
