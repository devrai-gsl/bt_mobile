import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_badge.dart';

class BtSecondaryTab {
  const BtSecondaryTab({
    required this.label,
    this.badge,
  });

  final String label;
  final String? badge;
}

class BtSecondaryTabs extends StatelessWidget {
  const BtSecondaryTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<BtSecondaryTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: BtSpacing.lg),
          child: Row(
            children: [
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: BtSpacing.lg),
                _TabItem(
                  tab: tabs[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelected(i),
                ),
              ],
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / tabs.length;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                const Divider(height: 1, color: BtColors.border),
                if (tabs.isNotEmpty)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    left: tabWidth * selectedIndex + tabWidth * 0.25,
                    bottom: 0,
                    child: Container(
                      width: tabWidth * 0.5,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: BtColors.brandGreen,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final BtSecondaryTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tab.label,
              style: selected
                  ? BtTypography.bodyMdSemibold
                  : BtTypography.bodyMdMedium.copyWith(
                      color: BtColors.textSecondary,
                    ),
            ),
            if (tab.badge != null) ...[
              const SizedBox(width: 6),
              BtCountBadge(count: tab.badge!, selected: selected),
            ],
          ],
        ),
      ),
    );
  }
}
