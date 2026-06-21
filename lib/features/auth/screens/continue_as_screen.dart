import 'package:flutter/material.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/features/auth/models/user_profile.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';

class ContinueAsScreen extends StatelessWidget {
  const ContinueAsScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  Widget build(BuildContext context) {
    final profile = controller.rememberedProfile;
    if (profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: BtColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(BtSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: BtSpacing.xl),
              Text(
                'Continue as',
                style: BtTypography.heading2xlMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: BtSpacing.xl),
              _AccountCard(profile: profile),
              const Spacer(),
              BtPrimaryButton(
                label: 'Continue',
                loading: controller.busy,
                onPressed: controller.busy ? null : controller.continueAs,
              ),
              const SizedBox(height: BtSpacing.md),
              BtOutlineButton(
                label: 'Log in with a different account',
                onPressed:
                    controller.busy ? null : controller.useDifferentAccount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BtSpacing.xl),
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: BtColors.brandGreen,
            child: Text(
              profile.initials,
              style: BtTypography.bodyBaseSemibold.copyWith(
                color: BtColors.surface,
              ),
            ),
          ),
          const SizedBox(width: BtSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.fullName, style: BtTypography.bodyBaseSemibold),
                const SizedBox(height: 4),
                Text(profile.roleTitle, style: BtTypography.bodyMdRegular),
                const SizedBox(height: 4),
                Text(
                  profile.companyLine,
                  style: BtTypography.bodySmRegular,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
