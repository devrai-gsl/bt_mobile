import 'package:flutter/material.dart';

import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_secondary_tabs.dart';
import 'package:bt_mobile/features/returns/screens/acknowledge_returns_screen.dart';
import 'package:bt_mobile/features/returns/screens/return_qc_screen.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';
import 'package:bt_mobile/features/returns/widgets/return_card.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({
    super.key,
    this.warehouseName = 'Goa Warehouse',
    this.initialTab = 0,
    this.returnsRepository,
  });

  final String warehouseName;
  final int initialTab;
  final ReturnsRepository? returnsRepository;

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  late int _tabIndex = widget.initialTab;
  final _searchController = TextEditingController();
  final _repo = ReturnsRepository();
  String _search = '';
  var _sortBy = 'Return Created';
  var _sortOrder = 'Newest first';
  late Future<ReturnsListData> _loadFuture = _load();

  ReturnsRepository get repo => widget.returnsRepository ?? _repo;

  Future<ReturnsListData> _load() => repo.getList();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ReturnCardData> _filtered(ReturnsListData data) {
    final tab = data.tabs[_tabIndex];
    return data.returns.where((r) {
      if (r.tab != tab) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return r.customerName.toLowerCase().contains(q) ||
          r.returnRef.toLowerCase().contains(q);
    }).toList();
  }

  void _onCardAction(ReturnCardData card) {
    if (card.actionLabel == 'Acknowledge') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const AcknowledgeReturnsScreen()),
      );
    } else if (card.actionLabel == 'Perform QC') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const ReturnQcScreen()),
      );
    }
  }

  void _showSortSheet() {
    showBtBottomSheet(
      context: context,
      title: 'Sort',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BtSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sort By', style: BtTypography.bodyMdMedium),
            const SizedBox(height: BtSpacing.md),
            for (final option in [
              'Return Created',
              'Channel Delivered',
              'Acknowledgement Date',
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: BtSpacing.md),
                child: BtRadioOption(
                  label: option,
                  selected: _sortBy == option,
                  onTap: () => setState(() => _sortBy = option),
                ),
              ),
            const SizedBox(height: BtSpacing.lg),
            Text('Sort Order', style: BtTypography.bodyMdMedium),
            const SizedBox(height: BtSpacing.md),
            BtRadioOption(
              label: 'Newest first',
              selected: _sortOrder == 'Newest first',
              onTap: () => setState(() => _sortOrder = 'Newest first'),
            ),
            const SizedBox(height: BtSpacing.md),
            BtRadioOption(
              label: 'Oldest first',
              selected: _sortOrder == 'Oldest first',
              onTap: () => setState(() => _sortOrder = 'Oldest first'),
            ),
            const SizedBox(height: BtSpacing.xl),
          ],
        ),
      ),
      footer: BtSheetActions(
        onReset: () {
          setState(() {
            _sortBy = 'Return Created';
            _sortOrder = 'Newest first';
          });
          Navigator.pop(context);
        },
        onApply: () => Navigator.pop(context),
        applyLabel: 'Apply Sort',
      ),
    );
  }

  void _showFilterSheet() {
    showBtBottomSheet(
      context: context,
      title: 'Filter',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BtSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BtSearchField(hint: 'Search filters'),
            const SizedBox(height: BtSpacing.xl),
            Text('Date Created', style: BtTypography.bodyMdMedium),
            const SizedBox(height: BtSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Today', 'Yesterday', 'Last 7d'].map((c) {
                return BtFilterChip(label: c, selected: false, onTap: () {});
              }).toList(),
            ),
            const SizedBox(height: BtSpacing.xl),
          ],
        ),
      ),
      footer: BtSheetActions(
        onReset: () => Navigator.pop(context),
        onApply: () => Navigator.pop(context),
        applyLabel: 'Apply Filters',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: BtColors.screenBg,
      child: FutureBuilder<ReturnsListData>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text('Could not load returns', style: BtTypography.bodyMdRegular),
            );
          }

          final data = snapshot.data!;
          final returns = _filtered(data);

          return Column(
            children: [
              BtListScreenHeader(
                title: 'Returns',
                subtitle: widget.warehouseName,
                searchHint: 'Search returns',
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _search = v),
                tabs: [
                  for (var i = 0; i < data.tabs.length; i++)
                    BtSecondaryTab(
                      label: data.tabs[i],
                      badge: _badgeForTab(data.tabs[i], data.returns),
                    ),
                ],
                selectedTabIndex: _tabIndex,
                onTabSelected: (i) => setState(() => _tabIndex = i),
                onFilterTap: _showFilterSheet,
                onSortTap: _showSortSheet,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  itemCount: returns.isEmpty ? 1 : returns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.lg),
                  itemBuilder: (context, index) {
                    if (returns.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Text(
                            'No returns in ${data.tabs[_tabIndex]}',
                            style: BtTypography.bodyMdRegular,
                          ),
                        ),
                      );
                    }
                    final card = returns[index];
                    return ReturnCard(
                      data: card,
                      onAction: () => _onCardAction(card),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String? _badgeForTab(String tab, List<ReturnCardData> returns) {
    final count = returns.where((r) => r.tab == tab).length;
    return count > 0 ? '$count' : null;
  }
}
