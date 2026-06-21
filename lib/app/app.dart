import 'package:flutter/material.dart';

import 'package:bt_mobile/app/di/app_dependencies.dart';
import 'package:bt_mobile/app/routes/app_routes.dart';
import 'package:bt_mobile/core/theme/bt_theme.dart';
import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/l10n/app_strings.dart';

class BrowntapeApp extends StatefulWidget {
  const BrowntapeApp({super.key});

  @override
  State<BrowntapeApp> createState() => _BrowntapeAppState();
}

class _BrowntapeAppState extends State<BrowntapeApp> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AppDependencies.createAuthController()..bootstrap();
    _authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appTitle,
      theme: BtTheme.light(),
      home: AppRoutes.home(_authController),
    );
  }
}
