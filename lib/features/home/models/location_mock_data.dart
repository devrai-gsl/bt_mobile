class WarehouseLocation {
  const WarehouseLocation({
    required this.id,
    required this.name,
    this.recentLabel,
  });

  final int id;
  final String name;
  final String? recentLabel;
}

const mockWarehouseLocations = <WarehouseLocation>[
  WarehouseLocation(id: 1, name: 'Goa Warehouse', recentLabel: 'Currently Active'),
  WarehouseLocation(id: 2, name: 'Bengaluru HSR Layout', recentLabel: 'Yesterday'),
  WarehouseLocation(id: 3, name: 'Bhiwandi DC', recentLabel: '3d ago'),
  WarehouseLocation(id: 4, name: 'Chennai Ambattur', recentLabel: 'Last month'),
  WarehouseLocation(id: 5, name: 'Bengaluru Indiranagar'),
  WarehouseLocation(id: 6, name: 'Bengaluru Whitefield'),
];
