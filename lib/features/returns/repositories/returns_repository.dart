import 'package:bt_mobile/core/network/fixtures/bt_mock_api.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

class ReturnsRepository {
  ReturnsRepository({BtMockApi? api}) : _api = api ?? BtMockApi();

  final BtMockApi _api;

  Future<ReturnsHomeData> getHome() async {
    final data = await _api.getReturnsHome();
    return ReturnsHomeData.fromJson(data);
  }

  Future<ReturnsListData> getList() async {
    final data = await _api.getReturnsList();
    return ReturnsListData.fromJson(data);
  }

  Future<ReturnsAcknowledgeData> getAcknowledgeConfig() async {
    final data = await _api.getReturnsAcknowledge();
    return ReturnsAcknowledgeData.fromJson(data);
  }

  Future<ReturnsQcData> getQcConfig() async {
    final data = await _api.getReturnsQc();
    return ReturnsQcData.fromJson(data);
  }

  Future<CreateReturnData> getCreateReturnConfig() async {
    final data = await _api.getCreateReturn();
    return CreateReturnData.fromJson(data);
  }

  Future<ScanPicklistData> getScanPicklist() async {
    final data = await _api.getScanPicklist();
    return ScanPicklistData.fromJson(data);
  }

  Future<QcCaptureConfig> getQcCaptureConfig() async {
    final data = await _api.getQcCapture();
    return QcCaptureConfig.fromJson(data);
  }
}
