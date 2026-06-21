class OrderProcessingAction {
  const OrderProcessingAction({
    required this.type,
    required this.loaderLabel,
    required this.loaderMs,
    required this.successMessage,
    required this.updatesOrder,
  });

  final String type;
  final String loaderLabel;
  final int loaderMs;
  final String successMessage;
  final bool updatesOrder;

  factory OrderProcessingAction.fromJson(Map<String, dynamic> json) {
    return OrderProcessingAction(
      type: json['type'] as String? ?? 'async',
      loaderLabel: json['loader_label'] as String? ?? 'Processing…',
      loaderMs: json['loader_ms'] as int? ?? 1500,
      successMessage: json['success_message'] as String? ?? 'Done',
      updatesOrder: json['updates_order'] as bool? ?? false,
    );
  }
}

class OrderCourierOption {
  const OrderCourierOption({required this.id, required this.name});

  final String id;
  final String name;

  factory OrderCourierOption.fromJson(Map<String, dynamic> json) {
    return OrderCourierOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class OrderProcessingActionsData {
  const OrderProcessingActionsData({
    required this.actions,
    required this.couriers,
  });

  final Map<String, OrderProcessingAction> actions;
  final List<OrderCourierOption> couriers;

  OrderProcessingAction? actionFor(String label) => actions[label];

  factory OrderProcessingActionsData.fromJson(Map<String, dynamic> json) {
    final actions = <String, OrderProcessingAction>{};
    final actionsRaw = json['actions'] as Map<String, dynamic>? ?? {};
    actionsRaw.forEach((key, value) {
      actions[key] = OrderProcessingAction.fromJson(value as Map<String, dynamic>);
    });

    return OrderProcessingActionsData(
      actions: actions,
      couriers: (json['couriers'] as List? ?? [])
          .map((e) => OrderCourierOption.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
