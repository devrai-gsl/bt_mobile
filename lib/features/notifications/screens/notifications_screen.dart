import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/features/notifications/models/notifications_mock_data.dart';

class NotificationsBody extends StatefulWidget {
  const NotificationsBody({
    super.key,
    required this.onBack,
    required this.onSettings,
    this.onUnreadCountChanged,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;
  final ValueChanged<int>? onUnreadCountChanged;

  @override
  State<NotificationsBody> createState() => _NotificationsBodyState();
}

class _NotificationsBodyState extends State<NotificationsBody> {
  late List<NotificationItem> _items =
      List<NotificationItem>.from(initialNotifications);

  int get _unreadCount => _items.where((n) => !n.isRead).length;

  void _syncUnreadCount() {
    widget.onUnreadCountChanged?.call(_unreadCount);
  }

  void _markAllRead() {
    setState(() {
      _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    });
    _syncUnreadCount();
  }

  void _markRead(String id) {
    setState(() {
      _items = _items
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList();
    });
    _syncUnreadCount();
  }

  void _onNotificationTap(NotificationItem item) {
    _markRead(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Open order for ${item.subtitle} — coming soon.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = <String, List<NotificationItem>>{};
    for (final item in _items) {
      sections.putIfAbsent(item.section, () => []).add(item);
    }

    return ColoredBox(
      color: BtColors.screenBg,
      child: Column(
        children: [
          _NotificationsHeader(
            onBack: widget.onBack,
            onSettings: widget.onSettings,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(BtSpacing.lg),
              children: [
                for (final section in ['Today', 'Yesterday'])
                  if (sections.containsKey(section)) ...[
                    _SectionHeader(
                      title: section,
                      showMarkAllRead: section == 'Today' && _unreadCount > 0,
                      onMarkAllRead: _markAllRead,
                    ),
                    const SizedBox(height: BtSpacing.md),
                    _NotificationCard(
                      items: sections[section]!,
                      onTap: _onNotificationTap,
                    ),
                    const SizedBox(height: BtSpacing.xl),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.onBack,
    required this.onSettings,
  });

  final VoidCallback onBack;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
            ),
            Expanded(
              child: Text(
                'Notifications',
                style: BtTypography.headingLgSemibold,
              ),
            ),
            IconButton(
              onPressed: onSettings,
              icon: const Icon(Icons.settings_outlined),
              color: BtColors.textBody,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.showMarkAllRead,
    required this.onMarkAllRead,
  });

  final String title;
  final bool showMarkAllRead;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: BtTypography.bodyMdMedium),
        const Spacer(),
        if (showMarkAllRead)
          TextButton(
            onPressed: onMarkAllRead,
            style: TextButton.styleFrom(
              foregroundColor: BtColors.brandGreen,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Mark All as Read', style: BtTypography.bodyMdSemibold),
          ),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.items,
    required this.onTap,
  });

  final List<NotificationItem> items;
  final ValueChanged<NotificationItem> onTap;

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
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _NotificationTile(
              item: items[i],
              onTap: () => onTap(items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = _NotificationStyle.forType(item.type);
    final titleStyle = item.isRead
        ? BtTypography.bodyMdMedium.copyWith(color: BtColors.textBody)
        : BtTypography.bodyMdSemibold;

    return Material(
      color: item.isRead ? BtColors.surface : BtColors.notificationUnreadBg,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(BtSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: style.iconBg,
                  borderRadius: BorderRadius.circular(
                    item.isRead ? BtSpacing.radiusSm : BtSpacing.radiusPill,
                  ),
                ),
                child: Icon(style.icon, size: 20, color: style.iconColor),
              ),
              const SizedBox(width: BtSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(item.title, style: titleStyle)),
                        if (!item.isRead) ...[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: style.dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(item.timeLabel, style: BtTypography.bodySmRegular),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(item.subtitle, style: BtTypography.bodySmRegular),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationStyle {
  const _NotificationStyle({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.dotColor,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final Color dotColor;

  static _NotificationStyle forType(NotificationType type) {
    return switch (type) {
      NotificationType.newOrder => const _NotificationStyle(
        icon: Icons.shopping_bag_outlined,
        iconBg: BtColors.notificationNewBg,
        iconColor: BtColors.accentBlue,
        dotColor: BtColors.brandGreen,
      ),
      NotificationType.cancelled => const _NotificationStyle(
        icon: Icons.cancel_outlined,
        iconBg: BtColors.slaBreachedBorder,
        iconColor: BtColors.badgeRed,
        dotColor: BtColors.badgeRed,
      ),
      NotificationType.autoRejectWarning => const _NotificationStyle(
        icon: Icons.warning_amber_rounded,
        iconBg: BtColors.notificationWarningBg,
        iconColor: BtColors.accentOrange,
        dotColor: BtColors.badgeRed,
      ),
      NotificationType.autoRejected => const _NotificationStyle(
        icon: Icons.block,
        iconBg: BtColors.surfaceMuted,
        iconColor: BtColors.textBody,
        dotColor: BtColors.textMuted,
      ),
    };
  }
}
