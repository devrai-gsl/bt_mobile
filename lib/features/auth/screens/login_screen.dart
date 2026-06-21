import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bt_mobile/config/app_config.dart';
import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/branding/bt_app_branding.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';
import 'package:bt_mobile/features/auth/screens/concurrent_login_screen.dart';
import 'package:bt_mobile/features/auth/screens/forgot_password_screen.dart';
import 'package:bt_mobile/features/auth/screens/login_locked_screen.dart';
import 'package:bt_mobile/features/auth/screens/login_otp_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  String? _emailError;
  String? _passwordError;
  String? _formError;

  @override
  void initState() {
    super.initState();
    final message = widget.controller.sessionExpiredMessage;
    if (message != null) {
      _formError = message;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final validation = widget.controller.validateFields(
      email: _emailController.text,
      password: _passwordController.text,
    );
    setState(() {
      _emailError = validation.emailError;
      _passwordError = validation.passwordError;
      _formError = null;
    });
    if (validation.emailError != null || validation.passwordError != null) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    if (widget.controller.isLockedLoginEmail(email)) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LoginLockedScreen(
            variant: widget.controller.isPermanentLockedLoginEmail(email)
                ? LoginLockedScreenVariant.permanent
                : LoginLockedScreenVariant.temporary,
          ),
        ),
      );
      return;
    }
    if (widget.controller.isConcurrentLoginEmail(email)) {
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ConcurrentLoginScreen(controller: widget.controller),
        ),
      );
      return;
    }

    final error = await widget.controller.submitLogin(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _formError = error == 'Invalid email or password'
            ? 'Invalid email or password'
            : error;
      });
    }
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const ForgotPasswordScreen(),
      ),
    );
  }

  Future<void> _openSsoPortal() async {
    final uri = Uri.parse(AppConfig.ssoPortalUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openOtpLogin() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LoginOtpScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
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
              Text('Login', style: BtTypography.heading2xlMedium),
              const SizedBox(height: BtSpacing.xl),
              BtInputField(
                label: 'Email',
                controller: _emailController,
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                errorText: _emailError,
              ),
              const SizedBox(height: BtSpacing.md),
              BtInputField(
                label: 'Password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: const [AutofillHints.password],
                errorText: _passwordError,
                suffix: IconButton(
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: BtColors.textMuted,
                  ),
                ),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: BtSpacing.sm),
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: widget.controller.rememberMe,
                      onChanged: widget.controller.busy
                          ? null
                          : (v) => widget.controller.setRememberMe(v ?? false),
                      activeColor: BtColors.brandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: BtSpacing.md),
                  Text('Remember Me', style: BtTypography.bodyMdRegular),
                  const Spacer(),
                  BtTextLinkButton(
                    label: 'Forgot Password?',
                    onPressed: _openForgotPassword,
                  ),
                ],
              ),
              if (_formError != null) ...[
                const SizedBox(height: BtSpacing.md),
                Text(
                  _formError!,
                  style: BtTypography.bodyMdRegular.copyWith(
                    color: BtColors.badgeRed,
                  ),
                ),
              ],
              const SizedBox(height: BtSpacing.md),
              BtPrimaryButton(
                label: 'Login',
                loading: widget.controller.busy,
                onPressed: widget.controller.busy ? null : _submit,
              ),
              const SizedBox(height: BtSpacing.md),
              BtOutlineButton(
                label: 'Login using OTP',
                onPressed: widget.controller.busy ? null : _openOtpLogin,
              ),
              const SizedBox(height: BtSpacing.xl),
              BtInfoAlert(
                message:
                    'Your Browntape credentials are managed via the Ginesys SSO '
                    'portal. To reset your password, or update your account, '
                    'visit the SSO Portal.',
              ),
              const SizedBox(height: BtSpacing.sm),
              Center(
                child: BtTextLinkButton(
                  label: 'SSO Portal',
                  onPressed: _openSsoPortal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
