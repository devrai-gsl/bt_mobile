import 'package:bt_mobile/core/network/fixtures/bt_mock_api.dart';
import 'package:bt_mobile/features/orders/models/order_detail_models.dart';
import 'package:bt_mobile/features/orders/models/order_processing_models.dart';
import 'package:bt_mobile/features/orders/models/orders_models.dart';

class OrdersRepository {
  OrdersRepository({BtMockApi? api}) : _api = api ?? BtMockApi();

  final BtMockApi _api;
  List<String>? _tabsCache;
  List<OrderCardData>? _ordersCache;
  Map<String, OrderDetailData>? _detailsCache;
  List<String>? _rejectionReasonsCache;
  OrderProcessingActionsData? _actionsCache;

  Future<OrderProcessingActionsData> getProcessingActions() async {
    _actionsCache ??= OrderProcessingActionsData.fromJson(
      await _api.getOrderProcessingActions(),
    );
    return _actionsCache!;
  }

  Future<List<String>> getTabs() async {
    _tabsCache ??= List<String>.from(
      (await _api.getOrdersList())['tabs'] as List? ?? orderTabsFallback,
    );
    return _tabsCache!;
  }

  Future<List<OrderCardData>> getOrders() async {
    if (_ordersCache != null) return _ordersCache!;
    final data = await _api.getOrdersList();
    final raw = data['orders'] as List? ?? [];
    _ordersCache = raw
        .map((e) => OrderCardData.fromJson(e as Map<String, dynamic>))
        .toList();
    return _ordersCache!;
  }

  Future<OrderDetailData> getOrderDetail(String id, {OrderCardData? fallback}) async {
    await _ensureDetailsLoaded();
    final detail = _detailsCache![id];
    if (detail != null) return detail;
    if (fallback != null) return OrderDetailData.fromCard(fallback);
    throw StateError('Order detail not found: $id');
  }

  Future<List<String>> getRejectionReasons() async {
    await _ensureDetailsLoaded();
    return _rejectionReasonsCache ?? [];
  }

  Future<void> _ensureDetailsLoaded() async {
    if (_detailsCache != null) return;
    final data = await _api.getOrderDetails();
    _rejectionReasonsCache = List<String>.from(
      data['rejection_reasons'] as List? ?? [],
    );
    final orders = data['orders'] as Map<String, dynamic>? ?? {};
    _detailsCache = orders.map(
      (key, value) => MapEntry(
        key,
        OrderDetailData.fromJson(value as Map<String, dynamic>),
      ),
    );
  }

  void clearCache() {
    _tabsCache = null;
    _ordersCache = null;
    _detailsCache = null;
    _rejectionReasonsCache = null;
    _actionsCache = null;
  }
}

const orderTabsFallback = [
  'To Fix',
  'New',
  'Packing',
  'Ready to Ship',
  'Shipped',
];
