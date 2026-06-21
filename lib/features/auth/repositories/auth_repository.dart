import 'package:bt_mobile/core/exceptions/api_exception.dart';
import 'package:bt_mobile/core/network/clients/bt_api_client.dart';
import 'package:bt_mobile/core/services/storage_service.dart';
import 'package:bt_mobile/features/auth/models/user_profile.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final UserProfile user;
}

class AuthRepository {
  AuthRepository({
    BtApiClient? api,
    StorageService? store,
  })  : _api = api ?? BtApiClient(),
        _store = store ?? StorageService();

  final BtApiClient _api;
  final StorageService _store;

  Future<bool> getRememberMeDefault() => _store.getRememberMe();

  Future<void> setRememberMe(bool value) => _store.setRememberMe(value);

  Future<AuthSession> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    await _store.setRememberMe(rememberMe);

    final data = await _api.postJson(
      'login',
      body: {'email': email.trim(), 'password': password},
    );

    final session = _sessionFromResponse(data);
    await _persistIfAllowed(session, rememberMe: rememberMe);
    return session;
  }

  Future<AuthSession?> resumeRememberedSession() async {
    final rememberMe = await _store.getRememberMe();
    if (!rememberMe) {
      return null;
    }

    final accessToken = await _store.readAccessToken();
    final refreshToken = await _store.readRefreshToken();
    if (accessToken == null || refreshToken == null) {
      return null;
    }

    try {
      final data = await _api.getJson('session', mobileToken: accessToken);
      final user = UserProfile.fromJson(
        data['user'] as Map<String, dynamic>,
      );
      if (!user.canPersistSession) {
        await _store.clearSession();
        return null;
      }
      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
      );
    } on ApiException catch (e) {
      if (e.expired) {
        return _tryRefresh(refreshToken);
      }
      rethrow;
    }
  }

  Future<AuthSession> continueWithStoredSession() async {
    final accessToken = await _store.readAccessToken();
    final refreshToken = await _store.readRefreshToken();
    if (accessToken == null || refreshToken == null) {
      throw ApiException('Session expired', expired: true);
    }

    try {
      final data = await _api.getJson('session', mobileToken: accessToken);
      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
      );
    } on ApiException catch (e) {
      if (e.expired) {
        final refreshed = await _tryRefresh(refreshToken);
        if (refreshed != null) {
          return refreshed;
        }
      }
      rethrow;
    }
  }

  Future<UserProfile?> readRememberedProfile() => _store.readRememberedProfile();

  Future<void> logout({bool clearRememberMe = false}) async {
    final accessToken = await _store.readAccessToken();
    final refreshToken = await _store.readRefreshToken();
    if (accessToken != null) {
      try {
        await _api.postJson(
          'logout',
          mobileToken: accessToken,
          body: refreshToken == null
              ? null
              : {'refresh_token': refreshToken},
        );
      } catch (_) {
        // Best-effort server logout.
      }
    }
    await _store.clearSession(clearRememberMe: clearRememberMe);
  }

  Future<bool> hasStoredSession() async {
    final access = await _store.readAccessToken();
    final refresh = await _store.readRefreshToken();
    return access != null && refresh != null;
  }

  Future<AuthSession?> _tryRefresh(String refreshToken) async {
    try {
      final data = await _api.postJson(
        'refresh',
        body: {'refresh_token': refreshToken},
      );
      final session = _sessionFromResponse(data);
      final rememberMe = await _store.getRememberMe();
      await _persistIfAllowed(session, rememberMe: rememberMe);
      return session;
    } catch (_) {
      await _store.clearSession();
      return null;
    }
  }

  AuthSession _sessionFromResponse(Map<String, dynamic> data) {
    return AuthSession(
      accessToken: data['access_token'] as String,
      refreshToken: data['refresh_token'] as String,
      user: UserProfile.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  Future<void> _persistIfAllowed(
    AuthSession session, {
    required bool rememberMe,
  }) async {
    if (!rememberMe || !session.user.canPersistSession) {
      await _store.clearSession();
      return;
    }

    await _store.saveSession(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      rememberedProfile: session.user,
    );
  }
}
