enum OrderFilterSectionKind { chips, productFamily }

class OrderFilterSectionDef {
  const OrderFilterSectionDef({
    required this.id,
    required this.title,
    this.options = const [],
    this.separatorBefore = false,
    this.customRange = false,
    this.kind = OrderFilterSectionKind.chips,
  });

  final String id;
  final String title;
  final List<String> options;
  final bool separatorBefore;
  final bool customRange;
  final OrderFilterSectionKind kind;
}

const orderFilterSections = <OrderFilterSectionDef>[
  OrderFilterSectionDef(
    id: 'date_created',
    title: 'Date Created',
    options: ['Today', 'Yesterday', 'Last 7d', 'Last 30d'],
    customRange: true,
  ),
  OrderFilterSectionDef(
    id: 'sla',
    title: 'SLA',
    options: ['SLA Breached', 'Due Today', 'Due Tomorrow'],
    customRange: true,
  ),
  OrderFilterSectionDef(
    id: 'channel',
    title: 'Channel',
    options: ['AJIO', 'AJIO MP', 'Flipkart', 'Flipkart MP', 'Shopify'],
    separatorBefore: true,
  ),
  OrderFilterSectionDef(
    id: 'order_type',
    title: 'Order Type',
    options: [
      'Seller Shipped',
      'Marketplace Fulfilled',
      'Amazon FBA',
      'Amazon Easy Ship',
      'Flipkart Advantage',
      'Marketplace Fulfilled B2B',
    ],
  ),
  OrderFilterSectionDef(
    id: 'invoice_status',
    title: 'Invoice Status',
    options: ['Assigned', 'Unassigned'],
    separatorBefore: true,
  ),
  OrderFilterSectionDef(
    id: 'payment_status',
    title: 'Payment Status',
    options: ['Paid', 'COD', 'Unpaid', 'Cancelled'],
  ),
  OrderFilterSectionDef(
    id: 'product_family',
    title: 'Product Family',
    options: ['tees', 'shirts'],
    separatorBefore: true,
    kind: OrderFilterSectionKind.productFamily,
  ),
];

String orderFilterKey(String sectionId, String value) => '$sectionId::$value';

OrderFilterSectionDef? orderFilterSectionById(String id) {
  for (final section in orderFilterSections) {
    if (section.id == id) return section;
  }
  return null;
}
