import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';

class BtPrimaryButton extends StatelessWidget {
  const BtPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: BtColors.surface,
            ),
          )
        : Text(
            label,
            style: BtTypography.bodyBaseSemibold.copyWith(
              color: BtColors.surface,
            ),
          );

    final button = Material(
      color: onPressed == null ? BtColors.brandGreen.withValues(alpha: 0.5) : BtColors.brandGreen,
      borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BtSpacing.buttonPaddingH,
            vertical: BtSpacing.buttonPaddingV,
          ),
          child: Center(child: child),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class BtOutlineButton extends StatelessWidget {
  const BtOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: BtColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
        side: const BorderSide(color: BtColors.borderInput),
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(BtSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BtSpacing.buttonPaddingH,
            vertical: BtSpacing.buttonPaddingV,
          ),
          child: Center(
            child: Text(label, style: BtTypography.bodyBaseMedium),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class BtTextLinkButton extends StatelessWidget {
  const BtTextLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: BtColors.brandGreen,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: BtTypography.link),
    );
  }
}

class BtSmallActionButton extends StatelessWidget {
  const BtSmallActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BtColors.brandGreen,
      borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: BtTypography.bodyMdMedium.copyWith(color: BtColors.surface),
          ),
        ),
      ),
    );
  }
}
