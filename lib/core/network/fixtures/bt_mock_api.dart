import 'package:bt_mobile/core/network/fixtures/bt_fixture_loader.dart';

/// Mock mobile API — reads JSON fixtures that mirror future backend responses.
class BtMockApi {
  BtMockApi({BtFixtureLoader? loader}) : _loader = loader ?? BtFixtureLoader();

  final BtFixtureLoader _loader;

  Future<Map<String, dynamic>> getOrdersList() =>
      _loader.loadData('orders_list.json');

  Future<Map<String, dynamic>> getOrderDetails() =>
      _loader.loadData('order_details.json');

  Future<Map<String, dynamic>> getReturnsHome() =>
      _loader.loadData('returns_home.json');

  Future<Map<String, dynamic>> getReturnsList() =>
      _loader.loadData('returns_list.json');

  Future<Map<String, dynamic>> getReturnsAcknowledge() =>
      _loader.loadData('returns_acknowledge.json');

  Future<Map<String, dynamic>> getReturnsQc() =>
      _loader.loadData('returns_qc.json');

  Future<Map<String, dynamic>> getCreateReturn() =>
      _loader.loadData('create_return.json');

  Future<Map<String, dynamic>> getScanPicklist() =>
      _loader.loadData('scan_picklist.json');

  Future<Map<String, dynamic>> getQcCapture() =>
      _loader.loadData('qc_capture.json');

  Future<Map<String, dynamic>> getOrderProcessingActions() =>
      _loader.loadData('order_processing_actions.json');

  Future<Map<String, dynamic>> getAuthFlows() =>
      _loader.loadData('auth_flows.json');
}
