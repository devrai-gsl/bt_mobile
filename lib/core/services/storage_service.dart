import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bt_mobile/features/auth/models/user_profile.dart';

class StorageService {
  StorageService({
    FlutterSecureStorage? secureStorage,
  }) : _secure = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _accessTokenKey = 'bt_mobile_access_token';
  static const _refreshTokenKey = 'bt_mobile_refresh_token';
  static const _rememberedProfileKey = 'bt_mobile_remembered_profile';
  static const _rememberMePrefKey = 'bt_mobile_remember_me';

  final FlutterSecureStorage _secure;

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMePrefKey) ?? true;
  }

  Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMePrefKey, value);
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    UserProfile? rememberedProfile,
  }) async {
    await _secure.write(key: _accessTokenKey, value: accessToken);
    await _secure.write(key: _refreshTokenKey, value: refreshToken);
    if (rememberedProfile != null) {
      await _secure.write(
        key: _rememberedProfileKey,
        value: jsonEncode(rememberedProfile.toJson()),
      );
    } else {
      await _secure.delete(key: _rememberedProfileKey);
    }
  }

  Future<String?> readAccessToken() => _secure.read(key: _accessTokenKey);

  Future<String?> readRefreshToken() => _secure.read(key: _refreshTokenKey);

  Future<UserProfile?> readRememberedProfile() async {
    final raw = await _secure.read(key: _rememberedProfileKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return UserProfile.fromJson(decoded);
    }
    return null;
  }

  Future<void> clearSession({bool clearRememberMe = false}) async {
    await _secure.delete(key: _accessTokenKey);
    await _secure.delete(key: _refreshTokenKey);
    await _secure.delete(key: _rememberedProfileKey);
    if (clearRememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_rememberMePrefKey);
    }
  }
}

/// Backward-compatible alias during migration.
typedef SecureSessionStore = StorageService;
