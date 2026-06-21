import 'package:bt_mobile/features/orders/models/orders_models.dart';

class OrderDetailItem {
  const OrderDetailItem({
    required this.sku,
    required this.name,
    required this.qty,
    required this.price,
    required this.itemRef,
    required this.channelSku,
    required this.channelProductId,
    required this.itoId,
    this.acceptQty,
  });

  final String sku;
  final String name;
  final int qty;
  final String price;
  final String itemRef;
  final String channelSku;
  final String channelProductId;
  final String itoId;
  final int? acceptQty;

  factory OrderDetailItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailItem(
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qty: json['qty'] as int? ?? 0,
      price: json['price'] as String? ?? '',
      itemRef: json['item_ref'] as String? ?? '',
      channelSku: json['channel_sku'] as String? ?? '',
      channelProductId: json['channel_product_id'] as String? ?? '',
      itoId: json['ito_id'] as String? ?? '',
      acceptQty: json['accept_qty'] as int?,
    );
  }
}

class PackagingOption {
  const PackagingOption({
    required this.id,
    required this.label,
    required this.shortCode,
  });

  final String id;
  final String label;
  final String shortCode;

  factory PackagingOption.fromJson(Map<String, dynamic> json) {
    return PackagingOption(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      shortCode: json['short_code'] as String? ?? '',
    );
  }
}

class OrderAddress {
  const OrderAddress({
    required this.name,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
  });

  final String name;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final String phone;

  String get formatted {
    final parts = [
      name,
      line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      '$city, $state $pincode',
      phone,
    ];
    return parts.join('\n');
  }

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      name: json['name'] as String? ?? '',
      line1: json['line1'] as String? ?? '',
      line2: json['line2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
    );
  }
}

class OrderShippingInfo {
  const OrderShippingInfo({
    required this.courierName,
    required this.trackingNumber,
    required this.dimensions,
    required this.weight,
    required this.packagingOpted,
    required this.packagingOptions,
    this.selectedPackagingId,
    this.selectedPackagingTitle,
    this.selectedDimensions,
    this.selectedWeight,
    this.deliveryAddress,
    this.billingAddress,
  });

  final String courierName;
  final String trackingNumber;
  final String dimensions;
  final String weight;
  final bool packagingOpted;
  final List<PackagingOption> packagingOptions;
  final String? selectedPackagingId;
  final String? selectedPackagingTitle;
  final String? selectedDimensions;
  final String? selectedWeight;
  final OrderAddress? deliveryAddress;
  final OrderAddress? billingAddress;

  bool get hasSelectedPackaging => selectedPackagingId != null;

  factory OrderShippingInfo.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['packaging_options'] as List? ?? [];
    return OrderShippingInfo(
      courierName: json['courier_name'] as String? ?? '',
      trackingNumber: json['tracking_number'] as String? ?? '',
      dimensions: json['dimensions'] as String? ?? '',
      weight: json['weight'] as String? ?? '',
      packagingOpted: json['packaging_opted'] as bool? ?? false,
      packagingOptions: optionsRaw
          .map((e) => PackagingOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      selectedPackagingId: json['selected_packaging_id'] as String?,
      selectedPackagingTitle: json['selected_packaging_title'] as String?,
      selectedDimensions: json['selected_dimensions'] as String?,
      selectedWeight: json['selected_weight'] as String?,
      deliveryAddress: json['delivery_address'] != null
          ? OrderAddress.fromJson(
              json['delivery_address'] as Map<String, dynamic>,
            )
          : null,
      billingAddress: json['billing_address'] != null
          ? OrderAddress.fromJson(
              json['billing_address'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class OrderTransaction {
  const OrderTransaction({
    required this.receivedAt,
    required this.source,
    required this.sourceReference,
    required this.grossValue,
    required this.isSystem,
  });

  final String receivedAt;
  final String source;
  final String sourceReference;
  final String grossValue;
  final bool isSystem;

  factory OrderTransaction.fromJson(Map<String, dynamic> json) {
    return OrderTransaction(
      receivedAt: json['received_at'] as String? ?? '',
      source: json['source'] as String? ?? '',
      sourceReference: json['source_reference'] as String? ?? '',
      grossValue: json['gross_value'] as String? ?? '',
      isSystem: json['is_system'] as bool? ?? false,
    );
  }
}

class LinkedReturnSummary {
  const LinkedReturnSummary({
    required this.id,
    required this.channelReturnRef,
    required this.returnType,
    required this.status,
    required this.awb,
  });

  final String id;
  final String channelReturnRef;
  final String returnType;
  final String status;
  final String awb;

  factory LinkedReturnSummary.fromJson(Map<String, dynamic> json) {
    return LinkedReturnSummary(
      id: json['id'] as String? ?? '',
      channelReturnRef: json['channel_return_ref'] as String? ?? '',
      returnType: json['return_type'] as String? ?? '',
      status: json['status'] as String? ?? '',
      awb: json['awb'] as String? ?? '',
    );
  }
}

class OrderDetailData {
  const OrderDetailData({
    required this.id,
    required this.customerName,
    required this.createdAt,
    required this.badges,
    required this.channelName,
    required this.orderType,
    required this.channelOrderRef,
    required this.subOrderId,
    required this.items,
    required this.shippingFee,
    required this.codFee,
    required this.discount,
    required this.orderTotal,
    this.pendingAcceptance = false,
    this.isShipped = false,
    this.showPartialAccept = false,
    this.transactionCount = 0,
    this.primaryAction,
    this.secondaryAction,
    this.showScanBar = false,
    this.shipping,
    this.transactions = const [],
    this.linkedReturns = const [],
  });

  final String id;
  final String customerName;
  final String createdAt;
  final List<String> badges;
  final String channelName;
  final String orderType;
  final String channelOrderRef;
  final String subOrderId;
  final List<OrderDetailItem> items;
  final String shippingFee;
  final String codFee;
  final String discount;
  final String orderTotal;
  final bool pendingAcceptance;
  final bool isShipped;
  final bool showPartialAccept;
  final int transactionCount;
  final String? primaryAction;
  final String? secondaryAction;
  final bool showScanBar;
  final OrderShippingInfo? shipping;
  final List<OrderTransaction> transactions;
  final List<LinkedReturnSummary> linkedReturns;

  int get itemCount => items.length;
  int get totalQty => items.fold(0, (sum, i) => sum + i.qty);

  bool get showShippingTab => !pendingAcceptance;
  bool get showReturnsTab => isShipped;

  factory OrderDetailData.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    final txRaw = json['transactions'] as List? ?? [];
    final returnsRaw = json['linked_returns'] as List? ?? [];
    return OrderDetailData(
      id: json['id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      badges: List<String>.from(json['badges'] as List? ?? []),
      channelName: json['channel_name'] as String? ?? '',
      orderType: json['order_type'] as String? ?? '',
      channelOrderRef: json['channel_order_ref'] as String? ?? '',
      subOrderId: json['sub_order_id'] as String? ?? '',
      items: itemsRaw
          .map((e) => OrderDetailItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      shippingFee: json['shipping_fee'] as String? ?? '',
      codFee: json['cod_fee'] as String? ?? '',
      discount: json['discount'] as String? ?? '',
      orderTotal: json['order_total'] as String? ?? '',
      pendingAcceptance: json['pending_acceptance'] as bool? ?? false,
      isShipped: json['is_shipped'] as bool? ?? false,
      showPartialAccept: json['show_partial_accept'] as bool? ?? false,
      transactionCount: json['transaction_count'] as int? ?? 0,
      primaryAction: json['primary_action'] as String?,
      secondaryAction: json['secondary_action'] as String?,
      showScanBar: json['show_scan_bar'] as bool? ?? false,
      shipping: json['shipping'] != null
          ? OrderShippingInfo.fromJson(json['shipping'] as Map<String, dynamic>)
          : null,
      transactions: txRaw
          .map((e) => OrderTransaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      linkedReturns: returnsRaw
          .map((e) => LinkedReturnSummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory OrderDetailData.fromCard(OrderCardData card) {
    return OrderDetailData(
      id: card.id,
      customerName: card.customerName,
      createdAt: card.date,
      badges: card.badges,
      channelName: card.channelRef.split(' · ').first,
      orderType: card.statusLabel,
      channelOrderRef: card.channelRef,
      subOrderId: '—',
      items: card.items
          .map(
            (i) => OrderDetailItem(
              sku: i.sku,
              name: i.name,
              qty: int.tryParse(i.qty.split(' ').first) ?? 1,
              price: card.total,
              itemRef: '—',
              channelSku: i.sku,
              channelProductId: '—',
              itoId: '—',
            ),
          )
          .toList(),
      shippingFee: card.shipping ?? '₹0.00',
      codFee: '₹0.00',
      discount: '- ₹0.00',
      orderTotal: card.total,
      primaryAction: card.actionLabel,
    );
  }
}
