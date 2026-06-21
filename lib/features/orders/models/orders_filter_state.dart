import 'package:flutter/material.dart';

import 'package:bt_mobile/features/orders/models/orders_filter_definitions.dart';

class OrdersFilterState {
  const OrdersFilterState({
    this.selectedKeys = const {},
    this.customRanges = const {},
    this.productFamilyQuery = '',
  });

  final Set<String> selectedKeys;
  final Map<String, DateTimeRange> customRanges;
  final String productFamilyQuery;

  bool get isEmpty =>
      selectedKeys.isEmpty &&
      customRanges.isEmpty &&
      productFamilyQuery.trim().isEmpty;

  int get count {
    var total = selectedKeys.length + customRanges.length;
    if (productFamilyQuery.trim().isNotEmpty) total++;
    return total;
  }

  List<String> get displayLabels {
    final labels = <String>[];

    for (final key in selectedKeys) {
      final parts = key.split('::');
      if (parts.length == 2) {
        labels.add(parts[1]);
      }
    }

    for (final entry in customRanges.entries) {
      final section = orderFilterSectionById(entry.key);
      final title = section?.title ?? entry.key;
      final start = _formatDate(entry.value.start);
      final end = _formatDate(entry.value.end);
      labels.add('$title: $start – $end');
    }

    final query = productFamilyQuery.trim();
    if (query.isNotEmpty) {
      labels.add('Family: $query');
    }

    return labels;
  }

  OrdersFilterState copyWith({
    Set<String>? selectedKeys,
    Map<String, DateTimeRange>? customRanges,
    String? productFamilyQuery,
  }) {
    return OrdersFilterState(
      selectedKeys: selectedKeys ?? this.selectedKeys,
      customRanges: customRanges ?? this.customRanges,
      productFamilyQuery: productFamilyQuery ?? this.productFamilyQuery,
    );
  }

  OrdersFilterState toggle(String key) {
    final next = Set<String>.from(selectedKeys);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    return copyWith(selectedKeys: next);
  }

  OrdersFilterState removeDisplayLabelAt(int index) {
    final labels = displayLabels;
    if (index >= labels.length) return this;

    final label = labels[index];

    for (final key in selectedKeys) {
      final parts = key.split('::');
      if (parts.length == 2 && parts[1] == label) {
        final next = Set<String>.from(selectedKeys)..remove(key);
        return copyWith(selectedKeys: next);
      }
    }

    for (final entry in customRanges.entries) {
      final section = orderFilterSectionById(entry.key);
      final title = section?.title ?? entry.key;
      final start = _formatDate(entry.value.start);
      final end = _formatDate(entry.value.end);
      if ('$title: $start – $end' == label) {
        final next = Map<String, DateTimeRange>.from(customRanges)
          ..remove(entry.key);
        return copyWith(customRanges: next);
      }
    }

    if (label.startsWith('Family: ')) {
      return copyWith(productFamilyQuery: '');
    }

    return this;
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
  }
}
