import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_badge.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/features/orders/models/orders_models.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.data,
    this.onTap,
    this.onAction,
  });

  final OrderCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        child: Container(
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
                          Text(
                            data.customerName,
                            style: BtTypography.bodyBaseSemibold,
                          ),
                          const SizedBox(height: 2),
                          Text(data.statusLabel, style: BtTypography.bodySmRegular),
                        ],
                      ),
                    ),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: data.badges
                          .map(
                            (b) => BtBadge(
                              label: b,
                              backgroundColor: b == 'COD' || b.contains('Pending')
                                  ? BtColors.badgeYellow
                                  : BtColors.surfaceMuted,
                              textColor: BtColors.textBody,
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
                const SizedBox(height: BtSpacing.md),
                _MetaRow(icon: Icons.storefront_outlined, text: data.channelRef),
                const SizedBox(height: 4),
                _MetaRow(icon: Icons.location_on_outlined, text: data.location),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 16, color: BtColors.textBody),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(data.date, style: BtTypography.bodyMdRegular),
                    ),
                    if (data.slaBreached) ...[
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 16,
                        color: BtColors.badgeRed,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SLA Breached',
                        style: BtTypography.bodySmSemibold.copyWith(
                          color: BtColors.badgeRed,
                        ),
                      ),
                    ],
                  ],
                ),
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
                  const SizedBox(height: 8),
                ],
                if (data.moreItems != null)
                  Text(data.moreItems!, style: BtTypography.bodySmRegular),
                const SizedBox(height: BtSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data.total, style: BtTypography.bodyMdMedium),
                          if (data.shipping != null)
                            Text(data.shipping!, style: BtTypography.bodySmRegular),
                        ],
                      ),
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
