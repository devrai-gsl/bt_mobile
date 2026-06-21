import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';
import 'package:bt_mobile/core/widgets/buttons/bt_buttons.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_input_field.dart';
import 'package:bt_mobile/core/widgets/inputs/bt_secondary_tabs.dart';

class BtListScreenHeader extends StatelessWidget {
  const BtListScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.searchHint,
    this.searchController,
    this.onSearchChanged,
    this.tabs,
    this.selectedTabIndex = 0,
    this.onTabSelected,
    this.showFilterSort = true,
    this.onFilterTap,
    this.onSortTap,
    this.filterCount = 0,
    this.activeFilterLabels = const [],
    this.onActiveFilterTap,
    this.onRemoveFilter,
    this.showBack = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final String? searchHint;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final List<BtSecondaryTab>? tabs;
  final int selectedTabIndex;
  final ValueChanged<int>? onTabSelected;
  final bool showFilterSort;
  final VoidCallback? onFilterTap;
  final VoidCallback? onSortTap;
  final int filterCount;
  final List<String> activeFilterLabels;
  final VoidCallback? onActiveFilterTap;
  final ValueChanged<int>? onRemoveFilter;
  final bool showBack;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtColors.surface,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BtSpacing.lg,
              BtSpacing.sm,
              BtSpacing.lg,
              BtSpacing.md,
            ),
            child: Row(
              children: [
                if (showBack) ...[
                  IconButton(
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: BtSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: BtTypography.headingLgSemibold),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: BtTypography.bodySmRegular),
                      ],
                    ],
                  ),
                ),
                if (showFilterSort) ...[
                  _HeaderIconButton(
                    icon: Icons.tune,
                    onTap: onFilterTap,
                    badgeCount: filterCount,
                  ),
                  const SizedBox(width: 4),
                  _HeaderIconButton(icon: Icons.swap_vert, onTap: onSortTap),
                ],
              ],
            ),
          ),
          if (searchHint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                BtSpacing.lg,
                0,
                BtSpacing.lg,
                BtSpacing.md,
              ),
              child: BtSearchField(
                hint: searchHint!,
                controller: searchController,
                onChanged: onSearchChanged,
              ),
            ),
          if (tabs != null && onTabSelected != null)
            BtSecondaryTabs(
              tabs: tabs!,
              selectedIndex: selectedTabIndex,
              onSelected: onTabSelected!,
            ),
          if (activeFilterLabels.isNotEmpty)
            Container(
              color: BtColors.chipBg,
              padding: const EdgeInsets.fromLTRB(
                BtSpacing.lg,
                BtSpacing.md,
                BtSpacing.lg,
                BtSpacing.md,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < activeFilterLabels.length && i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      BtRemovableFilterChip(
                        label: activeFilterLabels[i],
                        onTap: onActiveFilterTap,
                        onRemove: onRemoveFilter == null
                            ? null
                            : () => onRemoveFilter!(i),
                      ),
                    ],
                    if (activeFilterLabels.length > 3) ...[
                      const SizedBox(width: 8),
                      BtRemovableFilterChip(
                        label: '+${activeFilterLabels.length - 3} more filters',
                        onTap: onActiveFilterTap,
                        leading: const Icon(
                          Icons.tune,
                          size: 16,
                          color: BtColors.textBody,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: BtColors.surfaceMuted,
          borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(icon, size: 20, color: BtColors.textBody),
            ),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: BtColors.brandGreen,
                borderRadius: BorderRadius.circular(100),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Center(
                child: Text(
                  '$badgeCount',
                  style: BtTypography.bodySmSemibold.copyWith(
                    color: BtColors.surface,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<T?> showBtBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  Widget? footer,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: BtColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(BtSpacing.radiusXl),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 52,
                height: 4,
                decoration: BoxDecoration(
                  color: BtColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  BtSpacing.xl,
                  BtSpacing.lg,
                  BtSpacing.lg,
                  BtSpacing.md,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(title, style: BtTypography.headingXlSemibold),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(child: SingleChildScrollView(child: child)),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.all(BtSpacing.xl),
                  child: footer,
                ),
            ],
          ),
        ),
      );
    },
  );
}

class BtSheetActions extends StatelessWidget {
  const BtSheetActions({
    super.key,
    required this.onReset,
    required this.onApply,
    this.applyLabel = 'Apply',
  });

  final VoidCallback onReset;
  final VoidCallback onApply;
  final String applyLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: BtOutlineButton(label: 'Reset', onPressed: onReset),
        ),
        const SizedBox(width: BtSpacing.md),
        Expanded(
          child: BtPrimaryButton(label: applyLabel, onPressed: onApply),
        ),
      ],
    );
  }
}

class BtRadioOption extends StatelessWidget {
  const BtRadioOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BtColors.radioSelectedBg : BtColors.surface,
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
              Expanded(
                child: Text(
                  label,
                  style: selected
                      ? BtTypography.bodyBaseMedium
                      : BtTypography.bodyBaseRegular,
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? BtColors.brandGreen : BtColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BtFilterChip extends StatelessWidget {
  const BtFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: leading,
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: BtTypography.bodyMdMedium.copyWith(
        color: selected ? BtColors.chipText : BtColors.textBody,
      ),
      backgroundColor: BtColors.chipBg,
      selectedColor: BtColors.chipSelectedBg,
      side: BorderSide(
        color: selected ? BtColors.chipSelectedBorder : BtColors.border,
      ),
      shape: const StadiumBorder(),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class BtRemovableFilterChip extends StatelessWidget {
  const BtRemovableFilterChip({
    super.key,
    required this.label,
    this.onTap,
    this.onRemove,
    this.leading,
  });

  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtColors.chipBg,
      shape: StadiumBorder(
        side: BorderSide(color: BtColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 6),
              ],
              Text(label, style: BtTypography.bodyMdMedium),
              if (onRemove != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onRemove,
                  child: const Icon(Icons.close, size: 16, color: BtColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class BtInfoAlert extends StatelessWidget {
  const BtInfoAlert({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(BtSpacing.lg),
      decoration: BoxDecoration(
        color: BtColors.surfaceMuted,
        borderRadius: BorderRadius.circular(BtSpacing.radiusLg),
        border: Border.all(color: BtColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 20, color: BtColors.textBody),
          const SizedBox(width: BtSpacing.md),
          Expanded(
            child: Text(
              message,
              style: BtTypography.bodySmRegularParagraph,
            ),
          ),
        ],
      ),
    );
  }
}
