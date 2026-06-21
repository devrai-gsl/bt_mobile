import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_list_screen_header.dart';
import 'package:bt_mobile/features/home/models/location_mock_data.dart';

Future<String?> showLocationPickerSheet({
  required BuildContext context,
  required String selectedLocation,
  String title = 'Select Location',
}) {
  return showBtBottomSheet<String>(
    context: context,
    title: title,
    child: _LocationPickerContent(
      selectedLocation: selectedLocation,
      onSelected: (name) => Navigator.pop(context, name),
    ),
  );
}

class _LocationPickerContent extends StatefulWidget {
  const _LocationPickerContent({
    required this.selectedLocation,
    required this.onSelected,
  });

  final String selectedLocation;
  final ValueChanged<String> onSelected;

  @override
  State<_LocationPickerContent> createState() => _LocationPickerContentState();
}

class _LocationPickerContentState extends State<_LocationPickerContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<WarehouseLocation> get _filtered {
    if (_query.trim().isEmpty) {
      return mockWarehouseLocations;
    }
    final q = _query.toLowerCase();
    return mockWarehouseLocations
        .where((l) => l.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final showRecent = _query.trim().isEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        BtSpacing.xl,
        0,
        BtSpacing.xl,
        BtSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BtSearchField(
            hint: 'Search more locations',
            controller: _searchController,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: BtSpacing.xl),
          Text(
            showRecent
                ? 'Recent'
                : '${filtered.length} Match${filtered.length == 1 ? '' : 'es'}',
            style: showRecent
                ? BtTypography.bodyMdMedium
                : BtTypography.bodyMdMedium.copyWith(
                    color: BtColors.textSecondary,
                  ),
          ),
          const SizedBox(height: BtSpacing.md),
          ...filtered.map(
            (location) => Padding(
              padding: const EdgeInsets.only(bottom: BtSpacing.md),
              child: _LocationOption(
                location: location,
                selected: location.name == widget.selectedLocation,
                showRecent: showRecent,
                showActiveLabel: showRecent &&
                    location.name == widget.selectedLocation,
                onTap: () => widget.onSelected(location.name),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationOption extends StatelessWidget {
  const _LocationOption({
    required this.location,
    required this.selected,
    required this.showRecent,
    required this.showActiveLabel,
    required this.onTap,
  });

  final WarehouseLocation location;
  final bool selected;
  final bool showRecent;
  final bool showActiveLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BtColors.chipSelectedBg : BtColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
        side: BorderSide(
          color: selected ? BtColors.textMuted : BtColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BtSpacing.lg,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: selected
                      ? BtColors.chipSelectedBorder
                      : BtColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: selected ? BtColors.brandGreen : BtColors.textBody,
                ),
              ),
              const SizedBox(width: BtSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: selected
                          ? BtTypography.bodyBaseMedium
                          : BtTypography.bodyBaseRegular,
                    ),
                    if (showActiveLabel) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Currently Active',
                        style: BtTypography.bodySmMedium.copyWith(
                          color: BtColors.brandGreen,
                        ),
                      ),
                    ] else if (showRecent &&
                      location.recentLabel != null &&
                      location.recentLabel != 'Currently Active') ...[
                      const SizedBox(height: 2),
                      Text(
                        location.recentLabel!,
                        style: BtTypography.bodySmRegular,
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle,
                  size: 20,
                  color: BtColors.brandGreen,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
