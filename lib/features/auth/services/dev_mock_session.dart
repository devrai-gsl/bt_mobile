import 'package:bt_mobile/features/auth/repositories/auth_repository.dart';
import 'package:bt_mobile/features/auth/models/user_profile.dart';

/// Placeholder session for local UI work (Devrai dev login or [AppConfig.bypassLoginAuth]).
AuthSession devMockAuthSession({String? email}) {
  final login = email?.trim().toLowerCase() ?? 'devrai';
  const user = UserProfile(
    id: 0,
    email: 'devrai@gmail.com',
    username: 'Devrai',
    firstName: 'Devrai',
    lastName: '',
    roleId: 23,
    roleTitle: 'Warehouse Manager',
    companyId: 1,
    companyTitle: 'La Cesto',
    accessLevel: 'full',
    canPersistSession: true,
    warehouseId: 1,
    warehouseName: 'Goa Warehouse',
  );
  return AuthSession(
    accessToken: 'dev-skip-login-$login',
    refreshToken: 'dev-skip-login-$login',
    user: user,
  );
}

bool isDevMockSession(AuthSession? session) =>
    session?.accessToken.startsWith('dev-skip-login') ?? false;
