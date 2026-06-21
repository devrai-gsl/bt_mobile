import 'package:flutter/material.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/features/auth/repositories/auth_flow_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/branding/bt_app_branding.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';

class ConcurrentLoginScreen extends StatelessWidget {
  const ConcurrentLoginScreen({
    super.key,
    required this.controller,
  });

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final repo = AuthFlowRepository();
    return Scaffold(
      backgroundColor: BtColors.surface,
      body: SafeArea(
        child: FutureBuilder<AuthFlowData>(
          future: repo.getConfig(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final flow = snapshot.data!.concurrentLogin;
            final profile = flow.profile;

            return Padding(
              padding: const EdgeInsets.fromLTRB(
                BtSpacing.loginHorizontal,
                BtSpacing.loginVertical,
                BtSpacing.loginHorizontal,
                BtSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: BtSpacing.xl),
                  const BtAppBranding(),
                  const SizedBox(height: BtSpacing.xl),
                  Text(flow.title, style: BtTypography.heading2xlMedium),
                  const SizedBox(height: BtSpacing.xl),
                  Container(
                    padding: const EdgeInsets.all(BtSpacing.lg),
                    decoration: BoxDecoration(
                      color: BtColors.chipBg,
                      borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
                      border: Border.all(color: BtColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: BtColors.brandGreen,
                          child: Text(
                            profile.initials,
                            style: BtTypography.bodyBaseSemibold.copyWith(
                              color: BtColors.surface,
                            ),
                          ),
                        ),
                        const SizedBox(width: BtSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.fullName,
                                style: BtTypography.bodyBaseMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile.roleLine,
                                style: BtTypography.bodySmRegular,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  BtPrimaryButton(
                    label: flow.primaryButton,
                    loading: controller.busy,
                    onPressed: controller.busy
                        ? null
                        : () async {
                            final error = await controller.submitLogin(
                              email: 'devrai',
                              password: 'devrai',
                            );
                            if (!context.mounted) return;
                            if (error == null) {
                              Navigator.pop(context);
                            }
                          },
                  ),
                  const SizedBox(height: BtSpacing.md),
                  BtOutlineButton(
                    label: flow.secondaryButton,
                    onPressed:
                        controller.busy ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
