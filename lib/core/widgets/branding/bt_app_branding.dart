import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'bt_logo.dart';

class BtAppBranding extends StatelessWidget {
  const BtAppBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BtLogo(size: 56),
        const SizedBox(width: BtSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OMS', style: BtTypography.headingXlSemibold),
            Text(
              'BY GINESYS',
              style: BtTypography.bodyMdMedium.copyWith(
                color: BtColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
