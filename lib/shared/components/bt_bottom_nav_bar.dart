import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'app_nav_id.dart';

class BtBottomNavBar extends StatelessWidget {
  const BtBottomNavBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AppNavId selected;
  final ValueChanged<AppNavId> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BtColors.surface,
        border: Border(top: BorderSide(color: BtColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                selected: selected == AppNavId.home,
                onTap: () => onSelect(AppNavId.home),
              ),
              _NavItem(
                label: 'Orders',
                icon: Icons.shopping_cart_outlined,
                selectedIcon: Icons.shopping_cart,
                selected: selected == AppNavId.orders,
                onTap: () => onSelect(AppNavId.orders),
              ),
              _NavItem(
                label: 'Returns',
                icon: Icons.replay_outlined,
                selectedIcon: Icons.replay,
                selected: selected == AppNavId.returns,
                onTap: () => onSelect(AppNavId.returns),
              ),
              _NavItem(
                label: 'More',
                icon: Icons.menu,
                selectedIcon: Icons.menu,
                selected: selected == AppNavId.more,
                onTap: () => onSelect(AppNavId.more),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? BtColors.brandGreen.withValues(alpha: 0.12)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                selected ? selectedIcon : icon,
                size: 22,
                color: selected ? BtColors.brandGreen : BtColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: selected
                  ? BtTypography.bodySmSemibold
                  : BtTypography.bodySmMedium.copyWith(
                      color: BtColors.textSecondary,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
