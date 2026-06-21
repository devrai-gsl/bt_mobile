import 'package:flutter/material.dart';

import 'package:bt_mobile/features/orders/repositories/orders_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_secondary_tabs.dart';
import 'package:bt_mobile/features/orders/screens/order_detail_screen.dart';
import 'package:bt_mobile/features/orders/models/orders_filter_state.dart';
import 'package:bt_mobile/features/orders/models/orders_models.dart';
import 'package:bt_mobile/features/orders/widgets/order_card.dart';
import 'package:bt_mobile/shared/bottom_sheets/orders_filter_sheet.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({
    super.key,
    this.warehouseName = 'Goa Warehouse',
    this.initialTab = 1,
    this.ordersRepository,
  });

  final String warehouseName;
  final int initialTab;
  final OrdersRepository? ordersRepository;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late int _tabIndex = widget.initialTab;
  final _searchController = TextEditingController();
  final _repo = OrdersRepository();
  String _search = '';
  var _sortBy = 'Order Date';
  var _sortOrder = 'Newest first';
  OrdersFilterState _appliedFilters = const OrdersFilterState();
  late Future<_OrdersLoadResult> _loadFuture = _load();

  static const _toFixTabIndex = 0;

  OrdersRepository get repo => widget.ordersRepository ?? _repo;

  Future<_OrdersLoadResult> _load() async {
    final tabs = await repo.getTabs();
    final orders = await repo.getOrders();
    return _OrdersLoadResult(tabs: tabs, orders: orders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(OrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tabIndex = widget.initialTab;
    }
  }

  bool get _isToFixTab => _tabIndex == _toFixTabIndex;

  List<OrderCardData> _filtered(List<OrderCardData> orders, List<String> tabs) {
    final tab = tabs[_tabIndex];
    return orders.where((o) {
      if (o.tab != tab) return false;
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return o.customerName.toLowerCase().contains(q) ||
          o.channelRef.toLowerCase().contains(q);
    }).toList();
  }

  List<BtSecondaryTab> _tabsFor(List<String> tabs, List<OrderCardData> orders) {
    return [
      for (var i = 0; i < tabs.length; i++)
        BtSecondaryTab(
          label: tabs[i],
          badge: _badgeForTab(tabs[i], orders),
        ),
    ];
  }

  String? _badgeForTab(String tab, List<OrderCardData> orders) {
    final count = orders.where((o) => o.tab == tab).length;
    return count > 0 ? '$count' : null;
  }

  Future<void> _showFilterSheet() async {
    final result = await showOrdersFilterSheet(
      context: context,
      initial: _appliedFilters,
    );
    if (result != null && mounted) {
      setState(() => _appliedFilters = result);
    }
  }

  void _removeFilterAt(int index) {
    setState(() => _appliedFilters = _appliedFilters.removeDisplayLabelAt(index));
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
            for (final option in ['Order Date', 'SLA', 'Channel'])
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
            _sortOrder = 'Newest first';
            _sortBy = 'Order Date';
          });
          Navigator.pop(context);
        },
        onApply: () => Navigator.pop(context),
        applyLabel: 'Apply Sort',
      ),
    );
  }

  Future<void> _openOrderDetail(OrderCardData order) async {
    final detail = await repo.getOrderDetail(order.id, fallback: order);
    final reasons = await repo.getRejectionReasons();
    if (!mounted) return;

    var initialTabIndex = 0;
    if (detail.showShippingTab && detail.shipping != null) {
      initialTabIndex = 1;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderDetailScreen(
          order: detail,
          rejectionReasons: reasons,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterLabels = _appliedFilters.displayLabels;

    return ColoredBox(
      color: BtColors.screenBg,
      child: FutureBuilder<_OrdersLoadResult>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData) {
            return Center(
              child: Text('Could not load orders', style: BtTypography.bodyMdRegular),
            );
          }

          final data = snapshot.data!;
          final orders = _filtered(data.orders, data.tabs);

          return Column(
            children: [
              BtListScreenHeader(
                title: 'Orders',
                subtitle: widget.warehouseName,
                searchHint: 'Search orders',
                searchController: _searchController,
                onSearchChanged: (v) => setState(() => _search = v),
                tabs: _tabsFor(data.tabs, data.orders),
                selectedTabIndex: _tabIndex,
                onTabSelected: (i) => setState(() => _tabIndex = i),
                showFilterSort: !_isToFixTab,
                onFilterTap: _showFilterSheet,
                onSortTap: _showSortSheet,
                filterCount: _appliedFilters.count,
                activeFilterLabels: _isToFixTab ? const [] : filterLabels,
                onActiveFilterTap: _showFilterSheet,
                onRemoveFilter: _isToFixTab ? null : _removeFilterAt,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  itemCount: orders.isEmpty ? 1 : orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.lg),
                  itemBuilder: (context, index) {
                    if (orders.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Text(
                            'No orders in ${data.tabs[_tabIndex]}',
                            style: BtTypography.bodyMdRegular,
                          ),
                        ),
                      );
                    }
                    return OrderCard(
                      data: orders[index],
                      onTap: () => _openOrderDetail(orders[index]),
                      onAction: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${orders[index].actionLabel} — coming soon',
                            ),
                          ),
                        );
                      },
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
}

class _OrdersLoadResult {
  const _OrdersLoadResult({required this.tabs, required this.orders});

  final List<String> tabs;
  final List<OrderCardData> orders;
}
