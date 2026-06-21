class OrderItemLine {
  const OrderItemLine({
    required this.sku,
    required this.name,
    required this.qty,
  });

  final String sku;
  final String name;
  final String qty;

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    return OrderItemLine(
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qty: json['qty'] as String? ?? '',
    );
  }
}

class OrderCardData {
  const OrderCardData({
    required this.id,
    required this.customerName,
    required this.statusLabel,
    required this.badges,
    required this.channelRef,
    required this.location,
    required this.date,
    required this.items,
    required this.total,
    this.shipping,
    this.slaBreached = false,
    this.moreItems,
    this.actionLabel,
    this.tab = '',
  });

  final String id;
  final String customerName;
  final String statusLabel;
  final List<String> badges;
  final String channelRef;
  final String location;
  final String date;
  final List<OrderItemLine> items;
  final String total;
  final String? shipping;
  final bool slaBreached;
  final String? moreItems;
  final String? actionLabel;
  final String tab;

  factory OrderCardData.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return OrderCardData(
      id: json['id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      badges: List<String>.from(json['badges'] as List? ?? []),
      channelRef: json['channel_ref'] as String? ?? '',
      location: json['location'] as String? ?? '',
      date: json['date'] as String? ?? '',
      items: itemsRaw
          .map((e) => OrderItemLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as String? ?? '',
      shipping: json['shipping'] as String?,
      slaBreached: json['sla_breached'] as bool? ?? false,
      moreItems: json['more_items'] as String?,
      actionLabel: json['action_label'] as String?,
      tab: json['tab'] as String? ?? '',
    );
  }
}
