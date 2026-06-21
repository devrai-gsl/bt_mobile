import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_badge.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/returns/models/returns_models.dart';

class ReturnCard extends StatelessWidget {
  const ReturnCard({
    super.key,
    required this.data,
    this.onAction,
  });

  final ReturnCardData data;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
        boxShadow: [
          BoxShadow(
            color: BtColors.brandGreen.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(BtSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.customerName, style: BtTypography.bodyBaseSemibold),
                      const SizedBox(height: 2),
                      Text(data.statusLabel, style: BtTypography.bodySmRegular),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 6,
                  children: data.badges
                      .map(
                        (b) => BtBadge(
                          label: b,
                          backgroundColor: BtColors.surfaceMuted,
                          textColor: BtColors.textBody,
                          pill: true,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: BtSpacing.md),
            _MetaRow(icon: Icons.storefront_outlined, text: data.channelRef),
            const SizedBox(height: 4),
            _MetaRow(icon: Icons.replay, text: data.returnRef),
            const SizedBox(height: 4),
            _MetaRow(icon: Icons.schedule, text: data.date),
            const SizedBox(height: BtSpacing.md),
            for (final item in data.items) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BtSkuBadge(sku: item.sku),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item.name, style: BtTypography.bodyMdRegular),
                  ),
                  Text(item.qty, style: BtTypography.bodySmMedium),
                ],
              ),
            ],
            const SizedBox(height: BtSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(data.total, style: BtTypography.bodyMdMedium),
                ),
                if (data.actionLabel != null)
                  BtSmallActionButton(
                    label: data.actionLabel!,
                    onPressed: onAction,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: BtColors.textBody),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: BtTypography.bodyMdRegular)),
      ],
    );
  }
}
