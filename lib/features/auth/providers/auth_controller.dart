import 'package:flutter/foundation.dart';

import 'package:bt_mobile/config/app_config.dart';
import 'package:bt_mobile/core/exceptions/api_exception.dart';
import 'package:bt_mobile/features/auth/models/user_profile.dart';
import 'package:bt_mobile/features/auth/repositories/auth_flow_repository.dart';
import 'package:bt_mobile/features/auth/repositories/auth_repository.dart';
import 'package:bt_mobile/features/auth/services/dev_mock_session.dart';

export 'package:bt_mobile/features/auth/repositories/auth_repository.dart'
    show AuthSession;

enum AuthRoute {
  loading,
  login,
  continueAs,
  accessDenied,
  dashboard,
}

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository, AuthFlowRepository? flowRepository})
      : _repository = repository ?? AuthRepository(),
        _flowRepository = flowRepository ?? AuthFlowRepository();

  final AuthRepository _repository;
  final AuthFlowRepository _flowRepository;
  AuthFlowData? _flowConfig;

  AuthRoute _route = AuthRoute.loading;
  AuthSession? _session;
  UserProfile? _rememberedProfile;
  String? _sessionExpiredMessage;
  bool _rememberMe = true;
  bool _busy = false;

  AuthRoute get route => _route;
  AuthSession? get session => _session;
  UserProfile? get rememberedProfile => _rememberedProfile;
  String? get sessionExpiredMessage => _sessionExpiredMessage;
  bool get rememberMe => _rememberMe;
  bool get busy => _busy;
  bool get isDevSkipLogin => isDevMockSession(_session);

  bool isLockedLoginEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized == (_flowConfig?.lockedEmail ?? 'locked@bt.com') ||
        normalized == (_flowConfig?.permanentLockedEmail ?? 'permanent-locked@bt.com');
  }

  bool isPermanentLockedLoginEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized == (_flowConfig?.permanentLockedEmail ?? 'permanent-locked@bt.com');
  }

  bool isConcurrentLoginEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return normalized == (_flowConfig?.concurrentEmail ?? 'concurrent@bt.com');
  }

  Future<void> preloadAuthFlows() async {
    _flowConfig ??= await _flowRepository.getConfig();
  }

  Future<void> bootstrap() async {
    try {
      await _bootstrapInternal().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          _route = AuthRoute.login;
          notifyListeners();
        },
      );
    } catch (_) {
      _route = AuthRoute.login;
      notifyListeners();
    }
  }

  Future<void> _bootstrapInternal() async {
    await preloadAuthFlows();

    if (AppConfig.skipLogin) {
      _applySession(devMockAuthSession());
      return;
    }

    _rememberMe = await _repository.getRememberMeDefault();
    _rememberedProfile = await _repository.readRememberedProfile();

    final hasStored = await _repository.hasStoredSession();
    if (_rememberMe && hasStored && _rememberedProfile != null) {
      _route = AuthRoute.continueAs;
      notifyListeners();
      return;
    }

    try {
      final resumed = await _repository.resumeRememberedSession();
      if (resumed != null) {
        _applySession(resumed);
        return;
      }
    } on ApiException catch (e) {
      if (e.expired) {
        _sessionExpiredMessage = 'Your session has expired. Please sign in again.';
      }
    }

    _route = AuthRoute.login;
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  Future<String?> submitLogin({
    required String email,
    required String password,
  }) async {
    final emailError = _validateEmail(email);
    final passwordError = _validatePassword(password);
    if (emailError != null || passwordError != null) {
      return emailError ?? passwordError;
    }

    _busy = true;
    notifyListeners();
    try {
      if (AppConfig.bypassLoginAuth || _isDevraiCredentials(email, password)) {
        _sessionExpiredMessage = null;
        _applySession(devMockAuthSession(email: email));
        return null;
      }

      final authSession = await _repository.login(
        email: email,
        password: password,
        rememberMe: _rememberMe,
      );
      _sessionExpiredMessage = null;
      _applySession(authSession);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> continueAs() async {
    _busy = true;
    notifyListeners();
    try {
      final authSession = await _repository.continueWithStoredSession();
      _sessionExpiredMessage = null;
      _applySession(authSession);
      return null;
    } on ApiException catch (e) {
      _sessionExpiredMessage = e.expired
          ? 'Your session has expired. Please sign in again.'
          : e.message;
      _route = AuthRoute.login;
      notifyListeners();
      return _sessionExpiredMessage;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void useDifferentAccount() {
    _route = AuthRoute.login;
    notifyListeners();
  }

  Future<void> confirmLogout() async {
    if (isDevMockSession(_session)) {
      _session = null;
      _route = AuthRoute.login;
      notifyListeners();
      return;
    }
    await _repository.logout(clearRememberMe: false);
    _session = null;
    _rememberedProfile = null;
    _route = AuthRoute.login;
    notifyListeners();
  }

  void _applySession(AuthSession authSession) {
    _session = authSession;
    _rememberedProfile = authSession.user;
    if (authSession.user.isInventoryManager) {
      _route = AuthRoute.accessDenied;
    } else {
      _route = AuthRoute.dashboard;
    }
    notifyListeners();
  }

  bool _isDevraiCredentials(String email, String password) {
    return email.trim().toLowerCase() == AppConfig.devLoginId &&
        password.trim().toLowerCase() == AppConfig.devLoginPassword;
  }

  String? _validateEmail(String email) {
    if (email.trim().isEmpty) {
      return 'Email is required';
    }
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    return null;
  }

  ({String? emailError, String? passwordError}) validateFields({
    required String email,
    required String password,
  }) {
    return (
      emailError: _validateEmail(email),
      passwordError: _validatePassword(password),
    );
  }
}
