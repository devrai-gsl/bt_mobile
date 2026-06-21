import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bt_mobile/config/app_config.dart';
import 'package:bt_mobile/features/auth/repositories/auth_flow_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/branding/bt_app_branding.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';

enum _ForgotPasswordStep { email, emailSent, newPassword, success }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _repo = AuthFlowRepository();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late final Future<AuthFlowData> _configFuture = _repo.getConfig();
  _ForgotPasswordStep _step = _ForgotPasswordStep.email;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink(ForgotPasswordFlow flow) async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Email is required');
      return;
    }
    if (!flow.isKnownEmail(email)) {
      setState(() => _error = flow.invalidEmailStep.errorMessage);
      return;
    }
    setState(() {
      _error = null;
      _step = _ForgotPasswordStep.emailSent;
    });
  }

  void _resetPassword(ForgotPasswordFlow flow) {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.length < 8 || password != confirm) {
      setState(() => _error = flow.weakPasswordError);
      return;
    }
    setState(() {
      _error = null;
      _step = _ForgotPasswordStep.success;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.surface,
      body: SafeArea(
        child: FutureBuilder<AuthFlowData>(
          future: _configFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final flow = snapshot.data!.forgotPassword;
            return SingleChildScrollView(
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
                  ..._buildStepContent(flow),
                  if (_error != null) ...[
                    const SizedBox(height: BtSpacing.md),
                    Text(
                      _error!,
                      style: BtTypography.bodyMdRegular.copyWith(
                        color: BtColors.badgeRed,
                      ),
                    ),
                  ],
                  const SizedBox(height: BtSpacing.xl),
                  ..._buildActions(flow),
                  if (_step == _ForgotPasswordStep.email) ...[
                    const SizedBox(height: BtSpacing.xl),
                    const BtInfoAlert(
                      message:
                          'Your Browntape credentials are managed via the Ginesys '
                          'SSO portal. You can also reset your password there.',
                    ),
                    const SizedBox(height: BtSpacing.sm),
                    Center(
                      child: BtTextLinkButton(
                        label: 'SSO Portal',
                        onPressed: () => launchUrl(
                          Uri.parse(AppConfig.ssoPortalUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildStepContent(ForgotPasswordFlow flow) {
    return switch (_step) {
      _ForgotPasswordStep.email => [
          Text(flow.emailStep.title, style: BtTypography.heading2xlMedium),
          const SizedBox(height: BtSpacing.sm),
          Text(
            flow.emailStep.subtitle,
            style: BtTypography.bodyMdRegularParagraph,
          ),
          const SizedBox(height: BtSpacing.xl),
          BtInputField(
            label: flow.emailStep.fieldLabel ?? 'Email',
            controller: _emailController,
            hint: flow.emailStep.fieldHint ?? 'Enter your email',
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      _ForgotPasswordStep.emailSent => [
          Text(flow.emailSentStep.title, style: BtTypography.heading2xlMedium),
          const SizedBox(height: BtSpacing.sm),
          Text(
            flow.emailSentStep.formatSubtitle(email: _emailController.text.trim()),
            style: BtTypography.bodyMdRegularParagraph,
          ),
          const SizedBox(height: BtSpacing.xl),
          Icon(Icons.mark_email_read_outlined, size: 72, color: BtColors.brandGreen),
        ],
      _ForgotPasswordStep.newPassword => [
          Text(flow.newPasswordStep.title, style: BtTypography.heading2xlMedium),
          const SizedBox(height: BtSpacing.sm),
          Text(
            flow.newPasswordStep.subtitle,
            style: BtTypography.bodyMdRegularParagraph,
          ),
          const SizedBox(height: BtSpacing.xl),
          BtInputField(
            label: flow.newPasswordStep.passwordLabel ?? 'New Password',
            controller: _passwordController,
            obscureText: true,
          ),
          const SizedBox(height: BtSpacing.md),
          BtInputField(
            label: flow.newPasswordStep.confirmLabel ?? 'Confirm Password',
            controller: _confirmController,
            obscureText: true,
          ),
        ],
      _ForgotPasswordStep.success => [
          Text(flow.successStep.title, style: BtTypography.heading2xlMedium),
          const SizedBox(height: BtSpacing.sm),
          Text(
            flow.successStep.subtitle,
            style: BtTypography.bodyMdRegularParagraph,
          ),
          const SizedBox(height: BtSpacing.xl),
          Icon(Icons.check_circle_outline, size: 72, color: BtColors.brandGreen),
        ],
    };
  }

  List<Widget> _buildActions(ForgotPasswordFlow flow) {
    return switch (_step) {
      _ForgotPasswordStep.email => [
          BtPrimaryButton(
            label: flow.emailStep.primaryButton,
            onPressed: () => _sendResetLink(flow),
          ),
          if (flow.emailStep.secondaryButton != null) ...[
            const SizedBox(height: BtSpacing.md),
            BtOutlineButton(
              label: flow.emailStep.secondaryButton!,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ],
      _ForgotPasswordStep.emailSent => [
          BtPrimaryButton(
            label: flow.emailSentStep.primaryButton,
            onPressed: () => setState(() => _step = _ForgotPasswordStep.newPassword),
          ),
          const SizedBox(height: BtSpacing.md),
          BtOutlineButton(
            label: flow.emailSentStep.secondaryButton ?? 'Back to Login',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      _ForgotPasswordStep.newPassword => [
          BtPrimaryButton(
            label: flow.newPasswordStep.primaryButton,
            onPressed: () => _resetPassword(flow),
          ),
        ],
      _ForgotPasswordStep.success => [
          BtPrimaryButton(
            label: flow.successStep.primaryButton,
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
          ),
        ],
    };
  }
}
