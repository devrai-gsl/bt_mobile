import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';

class BtBadge extends StatelessWidget {
  const BtBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.pill = true,
  });

  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final bool pill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? BtColors.badgeYellow,
        borderRadius: BorderRadius.circular(pill ? BtSpacing.radiusPill : 4),
        border: backgroundColor == null
            ? null
            : Border.all(color: backgroundColor!),
      ),
      child: Text(
        label,
        style: BtTypography.bodyXsSemibold.copyWith(
          color: textColor ?? BtColors.textBody,
        ),
      ),
    );
  }
}

class BtCountBadge extends StatelessWidget {
  const BtCountBadge({
    super.key,
    required this.count,
    this.selected = false,
  });

  final String count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? BtColors.brandGreen : BtColors.border,
        borderRadius: BorderRadius.circular(BtSpacing.radiusPill),
      ),
      child: Text(
        count,
        style: BtTypography.bodySmSemibold.copyWith(
          color: selected ? BtColors.surface : BtColors.textBody,
        ),
      ),
    );
  }
}

class BtSkuBadge extends StatelessWidget {
  const BtSkuBadge({super.key, required this.sku});

  final String sku;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: BtColors.skuBadge,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        sku,
        style: BtTypography.bodyXsSemibold.copyWith(color: BtColors.surface),
      ),
    );
  }
}
