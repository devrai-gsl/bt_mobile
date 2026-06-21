import 'package:flutter/material.dart';

import 'package:bt_mobile/features/auth/providers/auth_controller.dart';
import 'package:bt_mobile/features/auth/models/user_profile.dart';
import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/branding/bt_logo.dart';
import 'package:bt_mobile/features/returns/screens/create_return_screen.dart';
import 'package:bt_mobile/features/scanner/screens/scan_picklist_screen.dart';

typedef DashboardNavCallback = void Function([int? tabIndex]);

class DashboardBody extends StatelessWidget {
  const DashboardBody({
    super.key,
    required this.user,
    required this.controller,
    this.onViewAllOrders,
    this.onViewAllReturns,
    this.onOrdersTab,
    this.onReturnsTab,
    this.onNotificationsTap,
    this.notificationBadgeCount = 0,
    this.selectedLocation = 'Goa Warehouse',
    this.onLocationTap,
    this.canSwitchLocation = true,
  });

  final UserProfile user;
  final AuthController controller;
  final VoidCallback? onViewAllOrders;
  final VoidCallback? onViewAllReturns;
  final DashboardNavCallback? onOrdersTab;
  final DashboardNavCallback? onReturnsTab;
  final VoidCallback? onNotificationsTap;
  final int notificationBadgeCount;
  final String selectedLocation;
  final VoidCallback? onLocationTap;
  final bool canSwitchLocation;

  @override
  Widget build(BuildContext context) {
    final firstName =
        user.firstName.isNotEmpty ? user.firstName : user.fullName;
    final warehouse = canSwitchLocation
        ? selectedLocation
        : (user.warehouseName ?? selectedLocation);

    return ColoredBox(
      color: BtColors.screenBg,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          BtSpacing.screenHorizontal,
          BtSpacing.sm,
          BtSpacing.screenHorizontal,
          BtSpacing.screenBottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DashboardHeader(
              controller: controller,
              notificationBadgeCount: notificationBadgeCount,
              onNotificationsTap: onNotificationsTap,
            ),
            const SizedBox(height: BtSpacing.xl),
            _GreetingRow(
              greeting: 'Hi $firstName',
              warehouse: warehouse,
              canSwitch: canSwitchLocation,
              onLocationTap: onLocationTap,
            ),
            const SizedBox(height: BtSpacing.xl),
            _OrdersOverviewSection(
              onViewAll: onViewAllOrders,
              onTab: onOrdersTab,
            ),
            const SizedBox(height: BtSpacing.xl),
            _ReturnActionsSection(
              onViewAll: onViewAllReturns,
              onTab: onReturnsTab,
            ),
            const SizedBox(height: BtSpacing.xl),
            const _MoreSection(),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.controller,
    this.notificationBadgeCount = 0,
    this.onNotificationsTap,
  });

  final AuthController controller;
  final int notificationBadgeCount;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BtLogo(size: 36),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onNotificationsTap,
              icon: const Icon(Icons.notifications_outlined),
              color: BtColors.textPrimary,
            ),
            if (notificationBadgeCount > 0)
              Positioned(
                right: 10,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: BtColors.badgeRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$notificationBadgeCount',
                    textAlign: TextAlign.center,
                    style: BtTypography.bodyXsSemibold.copyWith(
                      color: BtColors.surface,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow({
    required this.greeting,
    required this.warehouse,
    required this.canSwitch,
    this.onLocationTap,
  });

  final String greeting;
  final String warehouse;
  final bool canSwitch;
  final VoidCallback? onLocationTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(greeting, style: BtTypography.headingXlMedium)),
        _LocationPill(
          label: warehouse,
          canSwitch: canSwitch,
          onTap: onLocationTap,
        ),
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.label,
    required this.canSwitch,
    this.onTap,
  });

  final String label;
  final bool canSwitch;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: BtColors.surface,
        borderRadius: BorderRadius.circular(BtSpacing.radiusPill),
        border: Border.all(color: BtColors.borderInput),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: BtColors.brandGreen,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: BtTypography.bodyMdMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (canSwitch) ...[
            const SizedBox(width: 2),
            const Icon(Icons.unfold_more, size: 16, color: BtColors.textSecondary),
          ],
        ],
      ),
    );

    if (!canSwitch || onTap == null) {
      return child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BtSpacing.radiusPill),
        child: child,
      ),
    );
  }
}

class _OrdersOverviewSection extends StatelessWidget {
  const _OrdersOverviewSection({this.onViewAll, this.onTab});

  final VoidCallback? onViewAll;
  final DashboardNavCallback? onTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Orders Overview',
          actionLabel: 'View All Orders',
          onAction: onViewAll ?? () {},
        ),
        const SizedBox(height: BtSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = BtSpacing.md;
            final cardWidth = (constraints.maxWidth - spacing) / 2;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _OrderStatCard(
                    count: '25',
                    countColor: BtColors.accentOrange,
                    title: 'New',
                    subtitle: 'Pending Acceptance',
                    onTap: () => onTab?.call(1),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _OrderStatCard(
                    count: '9',
                    countColor: BtColors.accentOrange,
                    title: 'Packing',
                    subtitle: 'In-progress',
                    onTap: () => onTab?.call(2),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _OrderStatCard(
                    count: '18',
                    countColor: BtColors.accentBlue,
                    title: 'Ready to ship',
                    subtitle: 'Awaiting pickup',
                    onTap: () => onTab?.call(3),
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _OrderStatCard(
                    count: '2',
                    countColor: BtColors.badgeRed,
                    title: 'SLA Breach',
                    subtitle: 'Requires attention',
                    backgroundColor: BtColors.slaBreachedBg,
                    borderColor: BtColors.slaBreachedBorder,
                    trailingIcon: Icons.error_outline,
                    trailingIconColor: BtColors.badgeRed,
                    onTap: () => onTab?.call(1),
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

class _ReturnActionsSection extends StatelessWidget {
  const _ReturnActionsSection({this.onViewAll, this.onTab});

  final VoidCallback? onViewAll;
  final DashboardNavCallback? onTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Return Actions',
          actionLabel: 'View All Returns',
          onAction: onViewAll ?? () {},
        ),
        const SizedBox(height: BtSpacing.md),
        Container(
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
          child: Column(
            children: [
              _ActionListTile(
                icon: Icons.replay_outlined,
                title: 'Acknowledge Returns',
                subtitle: 'Confirm order receipt from courier',
                onTap: () => onTab?.call(0),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ActionListTile(
                icon: Icons.fact_check_outlined,
                title: 'Perform QC',
                subtitle: 'Inspect items, mark good or bad',
                badge: '3',
                badgeSubtitle: 'Pending',
                onTap: () => onTab?.call(1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MoreSection extends StatelessWidget {
  const _MoreSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More',
          style: BtTypography.bodyMdMedium.copyWith(
            color: BtColors.textSecondary,
          ),
        ),
        const SizedBox(height: BtSpacing.md),
        Container(
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
          child: Column(
            children: [
              _SimpleListTile(
                icon: Icons.add,
                title: 'Create Return',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CreateReturnScreen(),
                    ),
                  );
                },
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SimpleListTile(
                icon: Icons.qr_code_scanner_outlined,
                title: 'Scan Picklist',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ScanPicklistScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: BtTypography.bodyMdMedium.copyWith(
              color: BtColors.textSecondary,
            ),
          ),
        ),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: BtColors.brandGreen,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(actionLabel, style: BtTypography.bodyMdSemibold),
        ),
      ],
    );
  }
}

class _OrderStatCard extends StatelessWidget {
  const _OrderStatCard({
    required this.count,
    required this.countColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.trailingIcon,
    this.trailingIconColor,
  });

  final String count;
  final Color countColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final IconData? trailingIcon;
  final Color? trailingIconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? BtColors.surface,
      borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(BtSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
            border: Border.all(color: borderColor ?? BtColors.border),
            boxShadow: [
              BoxShadow(
                color: BtColors.brandGreen.withValues(alpha: 0.05),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    count,
                    style: BtTypography.headingXlSemibold.copyWith(
                      color: countColor,
                    ),
                  ),
                  const SizedBox(height: BtSpacing.sm),
                  Text(title, style: BtTypography.bodyBaseSemibold),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BtTypography.bodySmRegular),
                ],
              ),
              if (trailingIcon != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BtColors.slaBreachedBorder,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trailingIcon,
                      size: 16,
                      color: trailingIconColor,
                    ),
                  ),
                ),
              const Positioned(
                right: 0,
                bottom: 0,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: BtColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionListTile extends StatelessWidget {
  const _ActionListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.badgeSubtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final String? badgeSubtitle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(BtSpacing.lg),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: BtColors.iconGreenBg,
                borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
              ),
              child: Icon(icon, color: BtColors.brandGreen, size: 20),
            ),
            const SizedBox(width: BtSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: BtTypography.bodyBaseMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: BtTypography.bodySmRegular),
                ],
              ),
            ),
            if (badge != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    badge!,
                    style: BtTypography.headingLgSemibold.copyWith(
                      color: BtColors.accentOrange,
                    ),
                  ),
                  if (badgeSubtitle != null)
                    Text(
                      badgeSubtitle!,
                      style: BtTypography.bodyXsSemibold.copyWith(
                        color: BtColors.accentOrange,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right, size: 20, color: BtColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _SimpleListTile extends StatelessWidget {
  const _SimpleListTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(BtSpacing.lg),
        child: Row(
          children: [
            Icon(icon, size: 20, color: BtColors.textPrimary),
            const SizedBox(width: BtSpacing.md),
            Expanded(child: Text(title, style: BtTypography.bodyMdMedium)),
            const Icon(Icons.chevron_right, size: 20, color: BtColors.textMuted),
          ],
        ),
      ),
    );
  }
}
