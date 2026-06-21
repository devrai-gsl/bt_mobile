import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

class AcknowledgeSuccessScreen extends StatelessWidget {
  const AcknowledgeSuccessScreen({
    super.key,
    required this.info,
    required this.items,
    this.showOtp = false,
    this.otp,
  });

  final AckSuccessInfo info;
  final List<AckReturnScan> items;
  final bool showOtp;
  final AckOtpPreview? otp;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BtColors.screenBg,
      appBar: AppBar(
        title: Text(info.title),
        backgroundColor: BtColors.surface,
        foregroundColor: BtColors.textPrimary,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(BtSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle, color: BtColors.brandGreen, size: 56),
            const SizedBox(height: BtSpacing.lg),
            Text(info.message, style: BtTypography.bodyMdRegular),
            const SizedBox(height: BtSpacing.sm),
            Text(info.reference, style: BtTypography.bodySmRegular),
            if (showOtp && otp != null) ...[
              const SizedBox(height: BtSpacing.xl),
              Text('Acknowledgement OTP', style: BtTypography.bodyMdMedium),
              const SizedBox(height: BtSpacing.sm),
              Text(
                otp!.otp,
                style: BtTypography.headingXlSemibold.copyWith(
                  letterSpacing: 4,
                  color: BtColors.brandGreen,
                ),
              ),
            ],
            const SizedBox(height: BtSpacing.xl),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: BtSpacing.md),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Container(
                    padding: const EdgeInsets.all(BtSpacing.lg),
                    decoration: BoxDecoration(
                      color: BtColors.surface,
                      borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
                      border: Border.all(color: BtColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.channelReturnRef, style: BtTypography.bodyBaseSemibold),
                        Text('${item.channel} · ${item.returnType}'),
                        Text('AWB ${item.awb}'),
                      ],
                    ),
                  );
                },
              ),
            ),
            BtPrimaryButton(
              label: 'Back to Returns Home',
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}
