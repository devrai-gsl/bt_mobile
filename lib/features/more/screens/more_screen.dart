import 'package:flutter/material.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/features/returns/screens/create_return_screen.dart';
import 'package:bt_mobile/features/scanner/screens/scan_picklist_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final user = controller.session?.user;

    return ColoredBox(
      color: BtColors.screenBg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(BtSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (user != null) ...[
                Text('Account', style: BtTypography.bodyMdMedium.copyWith(
                  color: BtColors.textSecondary,
                )),
                const SizedBox(height: BtSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(BtSpacing.lg),
                  decoration: BoxDecoration(
                    color: BtColors.surface,
                    borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
                    border: Border.all(color: BtColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: BtTypography.bodyBaseSemibold),
                      const SizedBox(height: 4),
                      Text(user.roleTitle, style: BtTypography.bodySmRegular),
                      const SizedBox(height: 4),
                      Text(user.companyLine, style: BtTypography.bodySmRegular),
                    ],
                  ),
                ),
                const SizedBox(height: BtSpacing.xl),
              ],
              Text('More', style: BtTypography.bodyMdMedium.copyWith(
                color: BtColors.textSecondary,
              )),
              const SizedBox(height: BtSpacing.md),
              _MoreCard(
                children: [
                  _MoreTile(
                    icon: Icons.add,
                    title: 'Create Return',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CreateReturnScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MoreTile(
                    icon: Icons.qr_code_scanner_outlined,
                    title: 'Scan Picklist',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ScanPicklistScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MoreTile(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () => _snack(context, 'Settings'),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _MoreTile(
                    icon: Icons.logout,
                    title: 'Sign out',
                    onTap: controller.busy ? null : controller.confirmLogout,
                    destructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _snack(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — coming soon.')),
    );
  }
}

class _MoreCard extends StatelessWidget {
  const _MoreCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
        boxShadow: [
          BoxShadow(
            color: BtColors.brandGreen.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: destructive ? BtColors.badgeRed : BtColors.textBody,
      ),
      title: Text(
        title,
        style: BtTypography.bodyMdMedium.copyWith(
          color: destructive ? BtColors.badgeRed : BtColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: BtColors.textMuted),
    );
  }
}
