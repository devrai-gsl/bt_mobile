import 'package:bt_mobile/features/auth/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UserProfile maps inventory manager access', () {
    const profile = UserProfile(
      id: 1,
      email: 'inv@example.com',
      username: 'inv',
      firstName: 'Inv',
      lastName: 'Manager',
      roleId: 19,
      roleTitle: 'inventory manager',
      companyId: 10,
      companyTitle: 'Acme',
      accessLevel: 'inventory_denied',
      canPersistSession: false,
    );

    expect(profile.isInventoryManager, isTrue);
    expect(profile.canPersistSession, isFalse);
  });
}
