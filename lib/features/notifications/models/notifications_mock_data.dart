enum NotificationType {
  newOrder,
  cancelled,
  autoRejectWarning,
  autoRejected,
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.section,
    this.isRead = false,
  });

  final String id;
  final NotificationType type;
  final String title;
  final String subtitle;
  final String timeLabel;
  final String section;
  final bool isRead;

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      timeLabel: timeLabel,
      section: section,
      isRead: isRead ?? this.isRead,
    );
  }
}

final initialNotifications = <NotificationItem>[
  const NotificationItem(
    id: '1',
    type: NotificationType.newOrder,
    title: 'New Order Received',
    subtitle: '#621521 · ₹300 · Shopify PM',
    timeLabel: '2 min',
    section: 'Today',
  ),
  const NotificationItem(
    id: '2',
    type: NotificationType.cancelled,
    title: 'Order Cancelled',
    subtitle: '#621521 · ₹300 · Shopify PM',
    timeLabel: '18 min',
    section: 'Today',
  ),
  const NotificationItem(
    id: '3',
    type: NotificationType.autoRejectWarning,
    title: 'Auto-Reject Warning',
    subtitle: '#621521 will be auto-rejected in 2h 2m',
    timeLabel: '1 hr',
    section: 'Today',
  ),
  const NotificationItem(
    id: '4',
    type: NotificationType.autoRejected,
    title: 'Order Auto-rejected',
    subtitle: '#621521 · ₹300 · Shopify PM',
    timeLabel: '2 hr',
    section: 'Today',
    isRead: true,
  ),
  const NotificationItem(
    id: '5',
    type: NotificationType.newOrder,
    title: 'New Order Received',
    subtitle: '#621521 · ₹300 · Shopify PM',
    timeLabel: '18 hr',
    section: 'Yesterday',
    isRead: true,
  ),
  const NotificationItem(
    id: '6',
    type: NotificationType.cancelled,
    title: 'Order Cancelled',
    subtitle: '#621521 · ₹300 · Shopify PM',
    timeLabel: '19 hr',
    section: 'Yesterday',
    isRead: true,
  ),
  const NotificationItem(
    id: '7',
    type: NotificationType.autoRejectWarning,
    title: 'Auto-Reject Warning',
    subtitle: '#621521 will be auto-rejected soon',
    timeLabel: '20 hr',
    section: 'Yesterday',
    isRead: true,
  ),
  const NotificationItem(
    id: '8',
    type: NotificationType.autoRejected,
    title: 'Order Auto-rejected',
    subtitle: '#621521 · ₹300 · Shopify PM',
    timeLabel: '21 hr',
    section: 'Yesterday',
    isRead: true,
  ),
];
