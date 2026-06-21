import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/features/auth/repositories/auth_flow_repository.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/branding/bt_app_branding.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';

enum _OtpStep { request, verify }

class LoginOtpScreen extends StatefulWidget {
  const LoginOtpScreen({super.key, required this.controller});

  final AuthController controller;

  @override
  State<LoginOtpScreen> createState() => _LoginOtpScreenState();
}

class _LoginOtpScreenState extends State<LoginOtpScreen> {
  final _repo = AuthFlowRepository();
  final _phoneController = TextEditingController();
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  late final Future<AuthFlowData> _configFuture = _repo.getConfig();
  _OtpStep _step = _OtpStep.request;
  String? _error;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _resendTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startResendTimer(int seconds) {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = seconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  void _sendOtp(OtpLoginFlow flow) {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid mobile number');
      return;
    }
    setState(() {
      _error = null;
      _step = _OtpStep.verify;
    });
    _startResendTimer(flow.resendSeconds);
  }

  String _enteredOtp() => _controllers.map((c) => c.text).join();

  void _verifyOtp(OtpLoginFlow flow) {
    final otp = _enteredOtp();
    if (otp.length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    if (otp != flow.demoOtp) {
      setState(() => _error = flow.verifyErrorMessage);
      return;
    }
    setState(() => _error = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP verified — API coming soon.')),
    );
  }

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_error != null) setState(() => _error = null);
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
            final flow = snapshot.data!.otpLogin;
            final copy = _step == _OtpStep.request ? flow.request : flow.verifyEmpty;

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
                  Text(copy.title, style: BtTypography.heading2xlMedium),
                  const SizedBox(height: BtSpacing.sm),
                  Text(
                    _step == _OtpStep.request
                        ? copy.subtitle
                        : copy.formatSubtitle(maskedPhone: flow.maskedPhone),
                    style: BtTypography.bodyMdRegularParagraph,
                  ),
                  const SizedBox(height: BtSpacing.xl),
                  if (_step == _OtpStep.request)
                    BtInputField(
                      label: copy.fieldLabel ?? 'Mobile Number',
                      controller: _phoneController,
                      hint: copy.fieldHint ?? 'Enter mobile number',
                      keyboardType: TextInputType.phone,
                    )
                  else
                    Row(
                      children: [
                        for (var i = 0; i < 6; i++) ...[
                          if (i > 0) const SizedBox(width: BtSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _controllers[i],
                              focusNode: _focusNodes[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: BtTypography.bodyLgMedium,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (v) => _onDigitChanged(i, v),
                              decoration: const InputDecoration(
                                counterText: '',
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: BtSpacing.md),
                    Text(
                      _error!,
                      style: BtTypography.bodyMdRegular.copyWith(
                        color: BtColors.badgeRed,
                      ),
                    ),
                  ],
                  if (_step == _OtpStep.verify && _resendSeconds > 0) ...[
                    const SizedBox(height: BtSpacing.md),
                    Text(
                      flow.resendTimerLabel.replaceAll(
                        '{seconds}',
                        '$_resendSeconds',
                      ),
                      style: BtTypography.bodySmRegular.copyWith(
                        color: BtColors.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (_step == _OtpStep.verify && _resendSeconds == 0) ...[
                    const SizedBox(height: BtSpacing.md),
                    Center(
                      child: BtTextLinkButton(
                        label: flow.resendLabel,
                        onPressed: () => _startResendTimer(flow.resendSeconds),
                      ),
                    ),
                  ],
                  const SizedBox(height: BtSpacing.xl),
                  BtPrimaryButton(
                    label: copy.primaryButton,
                    onPressed: () {
                      if (_step == _OtpStep.request) {
                        _sendOtp(flow);
                      } else {
                        _verifyOtp(flow);
                      }
                    },
                  ),
                  const SizedBox(height: BtSpacing.md),
                  BtOutlineButton(
                    label: copy.secondaryButton ?? 'Back to Login',
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (_step == _OtpStep.request && copy.linkLabel != null) ...[
                    const SizedBox(height: BtSpacing.md),
                    Center(
                      child: BtTextLinkButton(
                        label: copy.linkLabel!,
                        onPressed: () {
                          setState(() => _step = _OtpStep.verify);
                          _startResendTimer(flow.resendSeconds);
                        },
                      ),
                    ),
                  ],
                  if (_step == _OtpStep.verify) ...[
                    const SizedBox(height: BtSpacing.xl),
                    BtInfoAlert(
                      message:
                          'Did not receive the code? Check your registered mobile '
                          'number or contact your administrator.',
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
}
