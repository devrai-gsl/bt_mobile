import 'package:bt_mobile/core/network/fixtures/bt_fixture_loader.dart';

class AuthFlowData {
  const AuthFlowData({
    required this.lockedEmail,
    required this.permanentLockedEmail,
    required this.concurrentEmail,
    required this.forgotPassword,
    required this.otpLogin,
    required this.loginLocked,
    required this.concurrentLogin,
  });

  final String lockedEmail;
  final String permanentLockedEmail;
  final String concurrentEmail;
  final ForgotPasswordFlow forgotPassword;
  final OtpLoginFlow otpLogin;
  final LoginLockedFlow loginLocked;
  final ConcurrentLoginFlow concurrentLogin;

  factory AuthFlowData.fromJson(Map<String, dynamic> json) {
    final triggers = json['demo_triggers'] as Map<String, dynamic>? ?? {};
    return AuthFlowData(
      lockedEmail: triggers['locked_email'] as String? ?? 'locked@bt.com',
      permanentLockedEmail:
          triggers['permanent_locked_email'] as String? ?? 'permanent-locked@bt.com',
      concurrentEmail: triggers['concurrent_email'] as String? ?? 'concurrent@bt.com',
      forgotPassword: ForgotPasswordFlow.fromJson(
        json['forgot_password'] as Map<String, dynamic>? ?? {},
      ),
      otpLogin: OtpLoginFlow.fromJson(
        json['otp_login'] as Map<String, dynamic>? ?? {},
      ),
      loginLocked: LoginLockedFlow.fromJson(
        json['login_locked'] as Map<String, dynamic>? ?? {},
      ),
      concurrentLogin: ConcurrentLoginFlow.fromJson(
        json['concurrent_login'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AuthFlowStepCopy {
  const AuthFlowStepCopy({
    required this.title,
    this.subtitle = '',
    this.fieldLabel,
    this.fieldHint,
    this.passwordLabel,
    this.confirmLabel,
    this.primaryButton = 'Continue',
    this.secondaryButton,
    this.linkLabel,
    this.errorMessage,
  });

  final String title;
  final String subtitle;
  final String? fieldLabel;
  final String? fieldHint;
  final String? passwordLabel;
  final String? confirmLabel;
  final String primaryButton;
  final String? secondaryButton;
  final String? linkLabel;
  final String? errorMessage;

  factory AuthFlowStepCopy.fromJson(Map<String, dynamic> json) {
    return AuthFlowStepCopy(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      fieldLabel: json['field_label'] as String?,
      fieldHint: json['field_hint'] as String?,
      passwordLabel: json['password_label'] as String?,
      confirmLabel: json['confirm_label'] as String?,
      primaryButton: json['primary_button'] as String? ?? 'Continue',
      secondaryButton: json['secondary_button'] as String?,
      linkLabel: json['link_label'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  String formatSubtitle({String? email, String? maskedPhone, int? seconds}) {
    var text = subtitle;
    if (email != null) text = text.replaceAll('{email}', email);
    if (maskedPhone != null) {
      text = text.replaceAll('{masked_phone}', maskedPhone);
    }
    if (seconds != null) {
      text = text.replaceAll('{seconds}', '$seconds');
    }
    return text;
  }
}

class ForgotPasswordFlow {
  const ForgotPasswordFlow({
    required this.knownEmails,
    required this.emailStep,
    required this.emailSentStep,
    required this.newPasswordStep,
    required this.successStep,
    required this.invalidEmailStep,
    required this.weakPasswordError,
  });

  final List<String> knownEmails;
  final AuthFlowStepCopy emailStep;
  final AuthFlowStepCopy emailSentStep;
  final AuthFlowStepCopy newPasswordStep;
  final AuthFlowStepCopy successStep;
  final AuthFlowStepCopy invalidEmailStep;
  final String weakPasswordError;

  factory ForgotPasswordFlow.fromJson(Map<String, dynamic> json) {
    final steps = json['steps'] as Map<String, dynamic>? ?? {};
    return ForgotPasswordFlow(
      knownEmails: List<String>.from(json['known_emails'] as List? ?? []),
      emailStep: AuthFlowStepCopy.fromJson(
        steps['email'] as Map<String, dynamic>? ?? {},
      ),
      emailSentStep: AuthFlowStepCopy.fromJson(
        steps['email_sent'] as Map<String, dynamic>? ?? {},
      ),
      newPasswordStep: AuthFlowStepCopy.fromJson(
        steps['new_password'] as Map<String, dynamic>? ?? {},
      ),
      successStep: AuthFlowStepCopy.fromJson(
        steps['success'] as Map<String, dynamic>? ?? {},
      ),
      invalidEmailStep: AuthFlowStepCopy.fromJson(
        steps['invalid_email'] as Map<String, dynamic>? ?? {},
      ),
      weakPasswordError: (steps['weak_password'] as Map?)?['error_message']
              as String? ??
          'Password must be at least 8 characters.',
    );
  }

  bool isKnownEmail(String email) =>
      knownEmails.contains(email.trim().toLowerCase());
}

class OtpLoginFlow {
  const OtpLoginFlow({
    required this.maskedPhone,
    required this.demoOtp,
    required this.resendSeconds,
    required this.request,
    required this.verifyEmpty,
    required this.verifyErrorMessage,
    required this.resendLabel,
    required this.resendTimerLabel,
  });

  final String maskedPhone;
  final String demoOtp;
  final int resendSeconds;
  final AuthFlowStepCopy request;
  final AuthFlowStepCopy verifyEmpty;
  final String verifyErrorMessage;
  final String resendLabel;
  final String resendTimerLabel;

  factory OtpLoginFlow.fromJson(Map<String, dynamic> json) {
    final resend = json['verify_resend'] as Map<String, dynamic>? ?? {};
    return OtpLoginFlow(
      maskedPhone: json['masked_phone'] as String? ?? '•••0897',
      demoOtp: json['demo_otp'] as String? ?? '123456',
      resendSeconds: json['resend_seconds'] as int? ?? 30,
      request: AuthFlowStepCopy.fromJson(
        json['request'] as Map<String, dynamic>? ?? {},
      ),
      verifyEmpty: AuthFlowStepCopy.fromJson(
        json['verify_empty'] as Map<String, dynamic>? ?? {},
      ),
      verifyErrorMessage: (json['verify_error'] as Map?)?['error_message']
              as String? ??
          'Invalid OTP.',
      resendLabel: resend['resend_label'] as String? ?? 'Resend OTP',
      resendTimerLabel:
          resend['resend_timer_label'] as String? ?? 'Resend OTP in {seconds}s',
    );
  }
}

class LoginLockedVariant {
  const LoginLockedVariant({
    required this.title,
    required this.message,
    required this.primaryButton,
    required this.secondaryButton,
    this.unlockMinutes,
  });

  final String title;
  final String message;
  final String primaryButton;
  final String secondaryButton;
  final int? unlockMinutes;

  String formatMessage() {
    if (unlockMinutes == null) return message;
    return message.replaceAll('{minutes}', '$unlockMinutes');
  }

  factory LoginLockedVariant.fromJson(Map<String, dynamic> json) {
    return LoginLockedVariant(
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      primaryButton: json['primary_button'] as String? ?? 'Back to Login',
      secondaryButton: json['secondary_button'] as String? ?? 'Back to Login',
      unlockMinutes: json['unlock_minutes'] as int?,
    );
  }
}

class LoginLockedFlow {
  const LoginLockedFlow({
    required this.temporary,
    required this.permanent,
  });

  final LoginLockedVariant temporary;
  final LoginLockedVariant permanent;

  factory LoginLockedFlow.fromJson(Map<String, dynamic> json) {
    return LoginLockedFlow(
      temporary: LoginLockedVariant.fromJson(
        json['temporary'] as Map<String, dynamic>? ?? {},
      ),
      permanent: LoginLockedVariant.fromJson(
        json['permanent'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class ConcurrentLoginProfile {
  const ConcurrentLoginProfile({
    required this.fullName,
    required this.initials,
    required this.roleLine,
  });

  final String fullName;
  final String initials;
  final String roleLine;

  factory ConcurrentLoginProfile.fromJson(Map<String, dynamic> json) {
    return ConcurrentLoginProfile(
      fullName: json['full_name'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      roleLine: json['role_line'] as String? ?? '',
    );
  }
}

class ConcurrentLoginFlow {
  const ConcurrentLoginFlow({
    required this.title,
    required this.profile,
    required this.primaryButton,
    required this.secondaryButton,
  });

  final String title;
  final ConcurrentLoginProfile profile;
  final String primaryButton;
  final String secondaryButton;

  factory ConcurrentLoginFlow.fromJson(Map<String, dynamic> json) {
    return ConcurrentLoginFlow(
      title: json['title'] as String? ?? 'Welcome back',
      profile: ConcurrentLoginProfile.fromJson(
        json['profile'] as Map<String, dynamic>? ?? {},
      ),
      primaryButton: json['primary_button'] as String? ?? 'Continue',
      secondaryButton:
          json['secondary_button'] as String? ?? 'Log in with a different account',
    );
  }
}

class AuthFlowRepository {
  AuthFlowRepository({BtFixtureLoader? loader})
      : _loader = loader ?? BtFixtureLoader();

  final BtFixtureLoader _loader;
  AuthFlowData? _cache;

  Future<AuthFlowData> getConfig() async {
    _cache ??= AuthFlowData.fromJson(await _loader.loadData('auth_flows.json'));
    return _cache!;
  }
}
