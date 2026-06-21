class ReturnItemLine {
  const ReturnItemLine({
    required this.sku,
    required this.name,
    required this.qty,
  });

  final String sku;
  final String name;
  final String qty;

  factory ReturnItemLine.fromJson(Map<String, dynamic> json) {
    return ReturnItemLine(
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      qty: json['qty'] as String? ?? '',
    );
  }
}

class ReturnCardData {
  const ReturnCardData({
    required this.id,
    required this.customerName,
    required this.statusLabel,
    required this.badges,
    required this.channelRef,
    required this.returnRef,
    required this.date,
    required this.items,
    required this.total,
    this.actionLabel,
    this.tab = '',
    this.transitStatus,
    this.courier,
    this.awb,
  });

  final String id;
  final String customerName;
  final String statusLabel;
  final List<String> badges;
  final String channelRef;
  final String returnRef;
  final String date;
  final List<ReturnItemLine> items;
  final String total;
  final String? actionLabel;
  final String tab;
  final String? transitStatus;
  final String? courier;
  final String? awb;

  factory ReturnCardData.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return ReturnCardData(
      id: json['id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      badges: List<String>.from(json['badges'] as List? ?? []),
      channelRef: json['channel_ref'] as String? ?? '',
      returnRef: json['return_ref'] as String? ?? '',
      date: json['date'] as String? ?? '',
      items: itemsRaw
          .map((e) => ReturnItemLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as String? ?? '',
      actionLabel: json['action_label'] as String?,
      tab: json['tab'] as String? ?? '',
      transitStatus: json['transit_status'] as String?,
      courier: json['courier'] as String?,
      awb: json['awb'] as String?,
    );
  }
}

class ReturnsListData {
  const ReturnsListData({required this.tabs, required this.returns});

  final List<String> tabs;
  final List<ReturnCardData> returns;

  factory ReturnsListData.fromJson(Map<String, dynamic> json) {
    final raw = json['returns'] as List? ?? [];
    return ReturnsListData(
      tabs: List<String>.from(json['tabs'] as List? ?? []),
      returns: raw
          .map((e) => ReturnCardData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReturnsHomeTile {
  const ReturnsHomeTile({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.badgeCount,
    this.badgeColor,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String icon;
  final int? badgeCount;
  final String? badgeColor;

  factory ReturnsHomeTile.fromJson(Map<String, dynamic> json) {
    return ReturnsHomeTile(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      icon: json['icon'] as String? ?? 'list',
      badgeCount: json['badge_count'] as int?,
      badgeColor: json['badge_color'] as String?,
    );
  }
}

class ReturnsHomeSection {
  const ReturnsHomeSection({
    required this.id,
    required this.title,
    required this.tiles,
  });

  final String id;
  final String title;
  final List<ReturnsHomeTile> tiles;

  factory ReturnsHomeSection.fromJson(Map<String, dynamic> json) {
    return ReturnsHomeSection(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      tiles: (json['tiles'] as List? ?? [])
          .map((e) => ReturnsHomeTile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReturnsHomeData {
  const ReturnsHomeData({
    required this.title,
    required this.warehouseName,
    required this.sections,
  });

  final String title;
  final String warehouseName;
  final List<ReturnsHomeSection> sections;

  List<ReturnsHomeTile> get allTiles =>
      sections.expand((section) => section.tiles).toList();

  factory ReturnsHomeData.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'] as List?;
    if (sectionsRaw != null) {
      return ReturnsHomeData(
        title: json['title'] as String? ?? 'Returns Dashboard',
        warehouseName: json['warehouse_name'] as String? ?? '',
        sections: sectionsRaw
            .map((e) => ReturnsHomeSection.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    final legacyTiles = (json['tiles'] as List? ?? [])
        .map((e) => ReturnsHomeTile.fromJson(e as Map<String, dynamic>))
        .toList();
    return ReturnsHomeData(
      title: json['title'] as String? ?? 'Returns',
      warehouseName: json['warehouse_name'] as String? ?? '',
      sections: [
        ReturnsHomeSection(id: 'all', title: '', tiles: legacyTiles),
      ],
    );
  }
}

class AckChannel {
  const AckChannel({required this.id, required this.name});

  final String id;
  final String name;

  factory AckChannel.fromJson(Map<String, dynamic> json) {
    return AckChannel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class AckWarehouse {
  const AckWarehouse({
    required this.id,
    required this.name,
    required this.isDefault,
  });

  final int id;
  final String name;
  final bool isDefault;

  factory AckWarehouse.fromJson(Map<String, dynamic> json) {
    return AckWarehouse(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class AckReturnScan {
  const AckReturnScan({
    required this.id,
    required this.channelReturnRef,
    required this.channel,
    required this.returnType,
    required this.awb,
    required this.orderRef,
  });

  final String id;
  final String channelReturnRef;
  final String channel;
  final String returnType;
  final String awb;
  final String orderRef;

  factory AckReturnScan.fromJson(Map<String, dynamic> json) {
    return AckReturnScan(
      id: json['id'] as String? ?? '',
      channelReturnRef: json['channel_return_ref'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      returnType: json['return_type'] as String? ?? '',
      awb: json['awb'] as String? ?? '',
      orderRef: json['order_ref'] as String? ?? '',
    );
  }
}

class AckOtpPreview {
  const AckOtpPreview({
    required this.channelName,
    required this.courierName,
    required this.returnsCount,
    required this.otp,
  });

  final String channelName;
  final String courierName;
  final int returnsCount;
  final String otp;

  factory AckOtpPreview.fromJson(Map<String, dynamic> json) {
    return AckOtpPreview(
      channelName: json['channel_name'] as String? ?? '',
      courierName: json['courier_name'] as String? ?? '',
      returnsCount: json['returns_count'] as int? ?? 0,
      otp: json['otp'] as String? ?? '',
    );
  }
}

class ReturnsAcknowledgeData {
  const ReturnsAcknowledgeData({
    required this.showOtpWithoutAck,
    required this.requireOtpOnAck,
    required this.noOtpChannelIds,
    required this.channels,
    required this.warehouses,
    required this.knownBarcodes,
    required this.multiReturnGroups,
    required this.otpPreview,
    required this.success,
  });

  final bool showOtpWithoutAck;
  final bool requireOtpOnAck;
  final List<String> noOtpChannelIds;
  final List<AckChannel> channels;
  final List<AckWarehouse> warehouses;
  final Map<String, AckReturnScan> knownBarcodes;
  final Map<String, List<AckReturnScan>> multiReturnGroups;
  final AckOtpPreview otpPreview;
  final AckSuccessInfo success;

  bool channelRequiresOtp(String? channelId) {
    if (!requireOtpOnAck) return false;
    if (channelId == null) return true;
    return !noOtpChannelIds.contains(channelId);
  }

  factory ReturnsAcknowledgeData.fromJson(Map<String, dynamic> json) {
    final known = <String, AckReturnScan>{};
    final knownRaw = json['known_barcodes'] as Map<String, dynamic>? ?? {};
    knownRaw.forEach((key, value) {
      known[key] = AckReturnScan.fromJson(value as Map<String, dynamic>);
    });

    final groups = <String, List<AckReturnScan>>{};
    final groupsRaw = json['multi_return_groups'] as Map<String, dynamic>? ?? {};
    groupsRaw.forEach((key, value) {
      final list = value as List? ?? [];
      groups[key] = list
          .map((e) => AckReturnScan.fromJson(e as Map<String, dynamic>))
          .toList();
    });

    return ReturnsAcknowledgeData(
      showOtpWithoutAck: json['show_otp_without_ack'] as bool? ?? false,
      requireOtpOnAck: json['require_otp_on_ack'] as bool? ?? true,
      noOtpChannelIds: List<String>.from(json['no_otp_channel_ids'] as List? ?? []),
      channels: (json['channels'] as List? ?? [])
          .map((e) => AckChannel.fromJson(e as Map<String, dynamic>))
          .toList(),
      warehouses: (json['warehouses'] as List? ?? [])
          .map((e) => AckWarehouse.fromJson(e as Map<String, dynamic>))
          .toList(),
      knownBarcodes: known,
      multiReturnGroups: groups,
      otpPreview: AckOtpPreview.fromJson(
        json['otp_preview'] as Map<String, dynamic>? ?? {},
      ),
      success: AckSuccessInfo.fromJson(
        json['success'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class AckSuccessInfo {
  const AckSuccessInfo({
    required this.title,
    required this.message,
    required this.reference,
  });

  final String title;
  final String message;
  final String reference;

  factory AckSuccessInfo.fromJson(Map<String, dynamic> json) {
    return AckSuccessInfo(
      title: json['title'] as String? ?? 'Success',
      message: json['message'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
    );
  }
}

class QcCaptureConfig {
  const QcCaptureConfig({
    required this.minImages,
    required this.maxImages,
    required this.imageTags,
    required this.viewfinderHint,
    required this.previewTitle,
  });

  final int minImages;
  final int maxImages;
  final List<String> imageTags;
  final String viewfinderHint;
  final String previewTitle;

  factory QcCaptureConfig.fromJson(Map<String, dynamic> json) {
    return QcCaptureConfig(
      minImages: json['min_images'] as int? ?? 1,
      maxImages: json['max_images'] as int? ?? 5,
      imageTags: List<String>.from(json['image_tags'] as List? ?? []),
      viewfinderHint: json['viewfinder_hint'] as String? ?? '',
      previewTitle: json['preview_title'] as String? ?? 'Image Preview',
    );
  }
}

class QcReturnItem {
  const QcReturnItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.colour,
    required this.size,
    required this.qty,
    required this.qcStatus,
    this.serialNumber,
    this.badConditionReason,
  });

  final String id;
  final String sku;
  final String name;
  final String colour;
  final String size;
  final int qty;
  final String qcStatus;
  final String? serialNumber;
  final String? badConditionReason;

  QcReturnItem copyWith({String? qcStatus, String? badConditionReason}) {
    return QcReturnItem(
      id: id,
      sku: sku,
      name: name,
      colour: colour,
      size: size,
      qty: qty,
      qcStatus: qcStatus ?? this.qcStatus,
      serialNumber: serialNumber,
      badConditionReason: badConditionReason ?? this.badConditionReason,
    );
  }

  factory QcReturnItem.fromJson(Map<String, dynamic> json) {
    return QcReturnItem(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      colour: json['colour'] as String? ?? '',
      size: json['size'] as String? ?? '',
      qty: json['qty'] as int? ?? 0,
      qcStatus: json['qc_status'] as String? ?? 'pending',
      serialNumber: json['serial_number'] as String?,
      badConditionReason: json['bad_condition_reason'] as String?,
    );
  }
}

class QcReturnDetail {
  const QcReturnDetail({
    required this.id,
    required this.channelReturnRef,
    required this.orderRef,
    required this.awb,
    required this.channel,
    required this.returnDate,
    required this.customerName,
    required this.items,
    this.returnReason,
  });

  final String id;
  final String channelReturnRef;
  final String orderRef;
  final String awb;
  final String channel;
  final String returnDate;
  final String customerName;
  final List<QcReturnItem> items;
  final String? returnReason;

  QcReturnDetail copyWith({List<QcReturnItem>? items}) {
    return QcReturnDetail(
      id: id,
      channelReturnRef: channelReturnRef,
      orderRef: orderRef,
      awb: awb,
      channel: channel,
      returnDate: returnDate,
      customerName: customerName,
      items: items ?? this.items,
      returnReason: returnReason,
    );
  }

  factory QcReturnDetail.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return QcReturnDetail(
      id: json['id'] as String? ?? '',
      channelReturnRef: json['channel_return_ref'] as String? ?? '',
      orderRef: json['order_ref'] as String? ?? '',
      awb: json['awb'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      returnDate: json['return_date'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      returnReason: json['return_reason'] as String?,
      items: itemsRaw
          .map((e) => QcReturnItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReturnsQcData {
  const ReturnsQcData({
    required this.warehouseName,
    required this.channels,
    required this.mediaMode,
    required this.recording,
    required this.knownBarcodes,
    required this.returns,
    required this.badConditionReasons,
    required this.imageTags,
  });

  final String warehouseName;
  final List<AckChannel> channels;
  final String mediaMode;
  final Map<String, dynamic> recording;
  final Map<String, String> knownBarcodes;
  final Map<String, QcReturnDetail> returns;
  final List<String> badConditionReasons;
  final List<String> imageTags;

  factory ReturnsQcData.fromJson(Map<String, dynamic> json) {
    final known = <String, String>{};
    final knownRaw = json['known_barcodes'] as Map<String, dynamic>? ?? {};
    knownRaw.forEach((key, value) => known[key] = value as String);

    final returns = <String, QcReturnDetail>{};
    final returnsRaw = json['returns'] as Map<String, dynamic>? ?? {};
    returnsRaw.forEach((key, value) {
      returns[key] = QcReturnDetail.fromJson(value as Map<String, dynamic>);
    });

    return ReturnsQcData(
      warehouseName: json['warehouse_name'] as String? ?? '',
      channels: (json['channels'] as List? ?? [])
          .map((e) => AckChannel.fromJson(e as Map<String, dynamic>))
          .toList(),
      mediaMode: json['media_mode'] as String? ?? 'images_only',
      recording: Map<String, dynamic>.from(
        json['recording'] as Map? ?? {},
      ),
      knownBarcodes: known,
      returns: returns,
      badConditionReasons: List<String>.from(
        json['bad_condition_reasons'] as List? ?? [],
      ),
      imageTags: List<String>.from(json['image_tags'] as List? ?? []),
    );
  }

  int maxRecordingSeconds(QcReturnDetail? detail) {
    final base = recording['max_duration_base_seconds'] as int? ?? 90;
    final extra = recording['extra_seconds_per_item'] as int? ?? 45;
    final itemCount = detail?.items.length ?? 0;
    if (itemCount <= 2) return base;
    return base + extra * (itemCount - 2);
  }

  int get countdownSeconds => recording['countdown_seconds'] as int? ?? 3;
}

class CreateReturnSearchType {
  const CreateReturnSearchType({
    required this.id,
    required this.label,
    required this.placeholder,
  });

  final String id;
  final String label;
  final String placeholder;

  factory CreateReturnSearchType.fromJson(Map<String, dynamic> json) {
    return CreateReturnSearchType(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      placeholder: json['placeholder'] as String? ?? '',
    );
  }
}

class CreateReturnOrderItem {
  const CreateReturnOrderItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.qtyOrdered,
    required this.qtyReturnable,
    required this.price,
    this.channelItemId,
    this.revSet,
    this.qtyPreviouslyReturned = 0,
    this.defaultSelected = false,
    this.defaultReturnQty = 0,
  });

  final String id;
  final String sku;
  final String name;
  final String? channelItemId;
  final String? revSet;
  final int qtyOrdered;
  final int qtyReturnable;
  final int qtyPreviouslyReturned;
  final String price;
  final bool defaultSelected;
  final int defaultReturnQty;

  factory CreateReturnOrderItem.fromJson(Map<String, dynamic> json) {
    return CreateReturnOrderItem(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      channelItemId: json['channel_item_id'] as String?,
      revSet: json['rev_set'] as String?,
      qtyOrdered: json['qty_ordered'] as int? ?? 0,
      qtyReturnable: json['qty_returnable'] as int? ?? 0,
      qtyPreviouslyReturned: json['qty_previously_returned'] as int? ?? 0,
      price: json['price'] as String? ?? '',
      defaultSelected: json['default_selected'] as bool? ?? false,
      defaultReturnQty: json['default_return_qty'] as int? ?? 0,
    );
  }
}

class CreateReturnOrder {
  const CreateReturnOrder({
    required this.orderId,
    required this.channelOrderRef,
    required this.channel,
    required this.customerName,
    required this.orderStatus,
    required this.allowReturn,
    required this.items,
    this.returnCourier,
    this.returnAwb,
  });

  final String orderId;
  final String channelOrderRef;
  final String channel;
  final String customerName;
  final String orderStatus;
  final bool allowReturn;
  final String? returnCourier;
  final String? returnAwb;
  final List<CreateReturnOrderItem> items;

  String get blockedMessage =>
      'Create return is not allowed for orders in status $orderStatus';

  factory CreateReturnOrder.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return CreateReturnOrder(
      orderId: json['order_id'] as String? ?? '',
      channelOrderRef: json['channel_order_ref'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      orderStatus: json['order_status'] as String? ?? 'Shipped',
      allowReturn: json['allow_return'] as bool? ?? true,
      returnCourier: json['return_courier'] as String?,
      returnAwb: json['return_awb'] as String?,
      items: itemsRaw
          .map((e) => CreateReturnOrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CreateReturnCourier {
  const CreateReturnCourier({required this.id, required this.name});

  final String id;
  final String name;

  factory CreateReturnCourier.fromJson(Map<String, dynamic> json) {
    return CreateReturnCourier(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class CreateReturnData {
  const CreateReturnData({
    required this.searchTypes,
    required this.searchLoaderMs,
    required this.emptySearchMessage,
    required this.returnTypes,
    required this.returnReasonsByType,
    required this.couriers,
    required this.knownOrders,
    required this.warehouses,
    required this.successRedirectMs,
  });

  final List<CreateReturnSearchType> searchTypes;
  final int searchLoaderMs;
  final String emptySearchMessage;
  final List<String> returnTypes;
  final Map<String, List<String>> returnReasonsByType;
  final List<CreateReturnCourier> couriers;
  final Map<String, CreateReturnOrder> knownOrders;
  final List<AckWarehouse> warehouses;
  final int successRedirectMs;

  List<String> reasonsFor(String? returnType) {
    if (returnType == null) {
      return returnReasonsByType['default'] ?? [];
    }
    return returnReasonsByType[returnType] ??
        returnReasonsByType['default'] ??
        [];
  }

  factory CreateReturnData.fromJson(Map<String, dynamic> json) {
    final orders = <String, CreateReturnOrder>{};
    final ordersRaw = json['known_orders'] as Map<String, dynamic>? ?? {};
    ordersRaw.forEach((key, value) {
      orders[key] = CreateReturnOrder.fromJson(value as Map<String, dynamic>);
    });

    final reasonsRaw = json['return_reasons'];
    final reasonsByType = <String, List<String>>{};
    if (reasonsRaw is Map) {
      reasonsRaw.forEach((key, value) {
        reasonsByType[key as String] = List<String>.from(value as List? ?? []);
      });
    } else {
      reasonsByType['default'] =
          List<String>.from(json['return_reasons'] as List? ?? []);
    }

    return CreateReturnData(
      searchTypes: (json['search_types'] as List? ?? [])
          .map((e) => CreateReturnSearchType.fromJson(e as Map<String, dynamic>))
          .toList(),
      searchLoaderMs: json['search_loader_ms'] as int? ?? 1200,
      emptySearchMessage:
          json['empty_search_message'] as String? ?? 'Please enter an order ID',
      returnTypes: List<String>.from(json['return_types'] as List? ?? []),
      returnReasonsByType: reasonsByType,
      couriers: (json['couriers'] as List? ?? [])
          .map((e) => CreateReturnCourier.fromJson(e as Map<String, dynamic>))
          .toList(),
      knownOrders: orders,
      warehouses: (json['warehouses'] as List? ?? [])
          .map((e) => AckWarehouse.fromJson(e as Map<String, dynamic>))
          .toList(),
      successRedirectMs: json['success_redirect_ms'] as int? ?? 1200,
    );
  }
}

class PicklistBatch {
  const PicklistBatch({
    required this.id,
    required this.label,
    required this.orderCount,
    required this.status,
    required this.statusLabel,
    required this.createdAt,
    this.lockedBy,
  });

  final String id;
  final String label;
  final int orderCount;
  final String status;
  final String statusLabel;
  final String createdAt;
  final String? lockedBy;

  bool get isLocked => lockedBy != null && lockedBy!.isNotEmpty;

  factory PicklistBatch.fromJson(Map<String, dynamic> json) {
    return PicklistBatch(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      orderCount: json['order_count'] as int? ?? 0,
      status: json['status'] as String? ?? '',
      statusLabel: json['status_label'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      lockedBy: json['locked_by'] as String?,
    );
  }
}

class PicklistItem {
  const PicklistItem({
    required this.id,
    required this.sku,
    required this.name,
    required this.requiredQty,
    required this.pickedQty,
    required this.requiresLot,
    required this.isKitComponent,
    this.lotCode,
  });

  final String id;
  final String sku;
  final String name;
  final int requiredQty;
  final int pickedQty;
  final bool requiresLot;
  final bool isKitComponent;
  final String? lotCode;

  bool get isComplete => pickedQty >= requiredQty;

  PicklistItem copyWith({int? pickedQty, String? lotCode}) {
    return PicklistItem(
      id: id,
      sku: sku,
      name: name,
      requiredQty: requiredQty,
      pickedQty: pickedQty ?? this.pickedQty,
      requiresLot: requiresLot,
      isKitComponent: isKitComponent,
      lotCode: lotCode ?? this.lotCode,
    );
  }

  factory PicklistItem.fromJson(Map<String, dynamic> json) {
    return PicklistItem(
      id: json['id'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      name: json['name'] as String? ?? '',
      requiredQty: json['required_qty'] as int? ?? 0,
      pickedQty: json['picked_qty'] as int? ?? 0,
      requiresLot: json['requires_lot'] as bool? ?? false,
      isKitComponent: json['is_kit_component'] as bool? ?? false,
      lotCode: json['lot_code'] as String?,
    );
  }
}

class PicklistOrderWithItems {
  const PicklistOrderWithItems({
    required this.id,
    required this.customerName,
    required this.channelRef,
    required this.status,
    required this.items,
  });

  final String id;
  final String customerName;
  final String channelRef;
  final String status;
  final List<PicklistItem> items;

  bool get isComplete => items.every((i) => i.isComplete);

  PicklistOrderWithItems copyWith({List<PicklistItem>? items, String? status}) {
    return PicklistOrderWithItems(
      id: id,
      customerName: customerName,
      channelRef: channelRef,
      status: status ?? this.status,
      items: items ?? this.items,
    );
  }

  factory PicklistOrderWithItems.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List? ?? [];
    return PicklistOrderWithItems(
      id: json['id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      channelRef: json['channel_ref'] as String? ?? '',
      status: json['status'] as String? ?? '',
      items: itemsRaw
          .map((e) => PicklistItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PicklistSession {
  const PicklistSession({
    required this.id,
    required this.label,
    required this.orders,
    required this.knownItemBarcodes,
  });

  final String id;
  final String label;
  final List<PicklistOrderWithItems> orders;
  final Map<String, String> knownItemBarcodes;

  factory PicklistSession.fromJson(Map<String, dynamic> json) {
    final ordersRaw = json['orders'] as List? ?? [];
    final known = <String, String>{};
    final knownRaw = json['known_item_barcodes'] as Map<String, dynamic>? ?? {};
    knownRaw.forEach((key, value) => known[key] = value as String);

    return PicklistSession(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      orders: ordersRaw
          .map((e) => PicklistOrderWithItems.fromJson(e as Map<String, dynamic>))
          .toList(),
      knownItemBarcodes: known,
    );
  }
}

class PicklistOrder {
  const PicklistOrder({
    required this.id,
    required this.customerName,
    required this.channelRef,
    required this.itemCount,
    required this.status,
  });

  final String id;
  final String customerName;
  final String channelRef;
  final int itemCount;
  final String status;

  factory PicklistOrder.fromJson(Map<String, dynamic> json) {
    return PicklistOrder(
      id: json['id'] as String? ?? '',
      customerName: json['customer_name'] as String? ?? '',
      channelRef: json['channel_ref'] as String? ?? '',
      itemCount: json['item_count'] as int? ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}

class ActivePicklistBatch {
  const ActivePicklistBatch({
    required this.id,
    required this.label,
    required this.orders,
    required this.knownBarcodes,
  });

  final String id;
  final String label;
  final List<PicklistOrder> orders;
  final Map<String, String> knownBarcodes;

  factory ActivePicklistBatch.fromJson(Map<String, dynamic> json) {
    final ordersRaw = json['orders'] as List? ?? [];
    final known = <String, String>{};
    final knownRaw = json['known_barcodes'] as Map<String, dynamic>? ?? {};
    knownRaw.forEach((key, value) => known[key] = value as String);

    return ActivePicklistBatch(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      orders: ordersRaw
          .map((e) => PicklistOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      knownBarcodes: known,
    );
  }
}

class ScanPicklistData {
  const ScanPicklistData({
    required this.warehouseName,
    required this.batches,
    required this.activeBatch,
    required this.batchBarcodes,
    required this.sessions,
    required this.rejectionReasons,
  });

  final String warehouseName;
  final List<PicklistBatch> batches;
  final ActivePicklistBatch activeBatch;
  final Map<String, String> batchBarcodes;
  final Map<String, PicklistSession> sessions;
  final List<String> rejectionReasons;

  PicklistSession? sessionFor(String batchId) => sessions[batchId];

  factory ScanPicklistData.fromJson(Map<String, dynamic> json) {
    final batchesRaw = json['batches'] as List? ?? [];
    final batchBarcodes = <String, String>{};
    final batchBarcodesRaw = json['batch_barcodes'] as Map<String, dynamic>? ?? {};
    batchBarcodesRaw.forEach((key, value) => batchBarcodes[key] = value as String);

    final sessions = <String, PicklistSession>{};
    final sessionsRaw = json['sessions'] as Map<String, dynamic>? ?? {};
    sessionsRaw.forEach((key, value) {
      sessions[key] = PicklistSession.fromJson(value as Map<String, dynamic>);
    });

    return ScanPicklistData(
      warehouseName: json['warehouse_name'] as String? ?? '',
      batches: batchesRaw
          .map((e) => PicklistBatch.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeBatch: ActivePicklistBatch.fromJson(
        json['active_batch'] as Map<String, dynamic>? ?? {},
      ),
      batchBarcodes: batchBarcodes,
      sessions: sessions,
      rejectionReasons: List<String>.from(json['rejection_reasons'] as List? ?? []),
    );
  }
}
