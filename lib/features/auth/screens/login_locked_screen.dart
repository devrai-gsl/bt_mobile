import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bt_mobile/config/app_config.dart';
import 'package:bt_mobile/features/auth/repositories/auth_flow_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/branding/bt_app_branding.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/auth/screens/forgot_password_screen.dart';

enum LoginLockedScreenVariant { temporary, permanent }

class LoginLockedScreen extends StatelessWidget {
  const LoginLockedScreen({
    super.key,
    this.variant = LoginLockedScreenVariant.temporary,
  });

  final LoginLockedScreenVariant variant;

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
            final copy = variant == LoginLockedScreenVariant.temporary
                ? snapshot.data!.loginLocked.temporary
                : snapshot.data!.loginLocked.permanent;

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
                  Icon(Icons.lock_outline, size: 72, color: BtColors.badgeRed),
                  const SizedBox(height: BtSpacing.lg),
                  Text(copy.title, style: BtTypography.heading2xlMedium),
                  const SizedBox(height: BtSpacing.sm),
                  Text(
                    copy.formatMessage(),
                    style: BtTypography.bodyMdRegularParagraph,
                  ),
                  const Spacer(),
                  BtPrimaryButton(
                    label: copy.primaryButton,
                    onPressed: () {
                      if (variant == LoginLockedScreenVariant.temporary) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const ForgotPasswordScreen(),
                          ),
                        );
                      } else {
                        launchUrl(
                          Uri.parse(AppConfig.ssoPortalUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: BtSpacing.md),
                  BtOutlineButton(
                    label: copy.secondaryButton,
                    onPressed: () => Navigator.pop(context),
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
