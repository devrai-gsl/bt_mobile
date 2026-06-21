import 'package:flutter/material.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/shared/components/bt_app_shell.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.controller,
    this.companyAddress,
    this.companyPhone,
  });

  final AuthController controller;
  final String? companyAddress;
  final String? companyPhone;

  @override
  Widget build(BuildContext context) {
    return BtAppShell(
      controller: controller,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
    );
  }
}
