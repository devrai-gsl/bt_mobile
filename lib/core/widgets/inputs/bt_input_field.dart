import 'package:flutter/material.dart';

import 'package:bt_mobile/core/theme/bt_colors.dart';
import 'package:bt_mobile/core/theme/bt_spacing.dart';
import 'package:bt_mobile/core/theme/bt_typography.dart';

class BtInputField extends StatelessWidget {
  const BtInputField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.obscureText = false,
    this.errorText,
    this.keyboardType,
    this.suffix,
    this.onSubmitted,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final bool obscureText;
  final String? errorText;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: BtTypography.bodyMdMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          onSubmitted: onSubmitted,
          style: BtTypography.bodyBaseRegular,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}

class BtSearchField extends StatelessWidget {
  const BtSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      style: BtTypography.bodyBaseRegular,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, size: 20, color: BtColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BtSpacing.inputPaddingH,
          vertical: BtSpacing.inputPaddingV,
        ),
      ),
    );
  }
}
