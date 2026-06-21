import 'package:flutter/material.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/features/auth/screens/access_denied_screen.dart';
import 'package:bt_mobile/features/auth/screens/continue_as_screen.dart';
import 'package:bt_mobile/features/auth/screens/login_screen.dart';
import 'package:bt_mobile/features/home/screens/dashboard_screen_wrapper.dart';

/// Root navigation driven by [AuthController.route].
class AppRoutes {
  const AppRoutes._();

  static Widget home(AuthController controller) {
    switch (controller.route) {
      case AuthRoute.loading:
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      case AuthRoute.login:
        return LoginScreen(controller: controller);
      case AuthRoute.continueAs:
        return ContinueAsScreen(controller: controller);
      case AuthRoute.accessDenied:
        return AccessDeniedScreen(controller: controller);
      case AuthRoute.dashboard:
        return DashboardScreen(controller: controller);
    }
  }
}
