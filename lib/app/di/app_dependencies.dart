import 'package:bt_mobile/core/network/clients/bt_api_client.dart';
import 'package:bt_mobile/core/network/fixtures/bt_fixture_loader.dart';
import 'package:bt_mobile/core/network/fixtures/bt_mock_api.dart';
import 'package:bt_mobile/core/services/camera_service.dart';
import 'package:bt_mobile/core/services/storage_service.dart';
import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/features/auth/repositories/auth_flow_repository.dart';
import 'package:bt_mobile/features/auth/repositories/auth_repository.dart';
import 'package:bt_mobile/features/orders/repositories/orders_repository.dart';
import 'package:bt_mobile/features/returns/repositories/returns_repository.dart';

/// Lightweight service locator until a full DI package is added.
class AppDependencies {
  AppDependencies._();

  static final storageService = StorageService();
  static final cameraService = CameraService();
  static final apiClient = BtApiClient();
  static final fixtureLoader = BtFixtureLoader();
  static final mockApi = BtMockApi(loader: fixtureLoader);

  static final authRepository = AuthRepository(
    api: apiClient,
    store: storageService,
  );
  static final authFlowRepository = AuthFlowRepository(loader: fixtureLoader);
  static final ordersRepository = OrdersRepository(api: mockApi);
  static final returnsRepository = ReturnsRepository(api: mockApi);

  static AuthController createAuthController() => AuthController(
        repository: authRepository,
        flowRepository: authFlowRepository,
      );
}
