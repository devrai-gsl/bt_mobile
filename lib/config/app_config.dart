import 'package:flutter/foundation.dart';

/// Runtime configuration for API and external links.
class AppConfig {
  AppConfig._();

  /// Override at run time:
  /// `flutter run --dart-define=BT_API_BASE_URL=http://10.0.2.2`
  static const String apiBaseUrl = String.fromEnvironment(
    'BT_API_BASE_URL',
    defaultValue: 'http://10.0.2.2',
  );

  static const String apiVersion = '2.0';

  static String get mobileAuthBase => '$apiBaseUrl/api/$apiVersion/mobile_auth';

  static const String ssoPortalUrl = 'https://sso.ginesys.one/login';

  /// Auto-open the dashboard on launch with a mock session (skips login UI).
  ///
  /// `flutter run --dart-define=BT_SKIP_LOGIN=true`
  static bool get skipLogin {
    return const String.fromEnvironment('BT_SKIP_LOGIN') == 'true';
  }

  /// Skip real login API calls for all users (testing only).
  ///
  /// Prefer the Devrai credential bypass in [AuthController] instead.
  /// `flutter build apk --dart-define=BT_BYPASS_LOGIN_AUTH=true`
  static bool get bypassLoginAuth {
    return const String.fromEnvironment('BT_BYPASS_LOGIN_AUTH') == 'true';
  }

  /// Local dev login without API when email/username and password are both Devrai.
  static const devLoginId = 'devrai';
  static const devLoginPassword = 'devrai';

  /// Run the tutorial-style sandbox UI for hot reload practice.
  ///
  /// `flutter run --dart-define=BT_DEV_SANDBOX=true`
  static bool get devSandbox {
    if (!kDebugMode) {
      return false;
    }
    return const String.fromEnvironment('BT_DEV_SANDBOX') == 'true';
  }
}
