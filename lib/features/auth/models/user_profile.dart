class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.roleId,
    required this.roleTitle,
    required this.companyId,
    required this.companyTitle,
    required this.accessLevel,
    required this.canPersistSession,
    this.warehouseId,
    this.warehouseName,
  });

  final int id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final int roleId;
  final String roleTitle;
  final int companyId;
  final String companyTitle;
  final String accessLevel;
  final bool canPersistSession;
  final int? warehouseId;
  final String? warehouseName;

  String get fullName {
    final parts = [firstName, lastName].where((p) => p.trim().isNotEmpty);
    if (parts.isNotEmpty) {
      return parts.join(' ').trim();
    }
    return email;
  }

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty) {
      return '?';
    }
    final bits = name.split(RegExp(r'\s+'));
    if (bits.length == 1) {
      return bits.first.substring(0, 1).toUpperCase();
    }
    return '${bits.first.substring(0, 1)}${bits.last.substring(0, 1)}'
        .toUpperCase();
  }

  bool get isInventoryManager => accessLevel == 'inventory_denied';

  bool get isWarehouseManager => accessLevel == 'warehouse_scoped';

  bool get hasFullAccess => accessLevel == 'full';

  String get companyLine {
    if (isWarehouseManager && (warehouseName ?? '').isNotEmpty) {
      return '$companyTitle · $warehouseName';
    }
    return companyTitle;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      roleId: json['role_id'] as int,
      roleTitle: json['role_title'] as String? ?? '',
      companyId: json['company_id'] as int,
      companyTitle: json['company_title'] as String? ?? '',
      accessLevel: json['access_level'] as String? ?? 'denied',
      canPersistSession: json['can_persist_session'] as bool? ?? true,
      warehouseId: json['warehouse_id'] as int?,
      warehouseName: json['warehouse_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'first_name': firstName,
    'last_name': lastName,
    'role_id': roleId,
    'role_title': roleTitle,
    'company_id': companyId,
    'company_title': companyTitle,
    'access_level': accessLevel,
    'can_persist_session': canPersistSession,
    'warehouse_id': warehouseId,
    'warehouse_name': warehouseName,
  };
}
