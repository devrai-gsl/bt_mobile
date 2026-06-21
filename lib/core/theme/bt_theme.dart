import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bt_colors.dart';
import 'bt_spacing.dart';

abstract final class BtTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: BtColors.screenBg,
      colorScheme: const ColorScheme.light(
        primary: BtColors.brandGreen,
        onPrimary: BtColors.surface,
        surface: BtColors.surface,
        onSurface: BtColors.textPrimary,
        error: BtColors.badgeRed,
      ),
      dividerColor: BtColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: BtColors.surface,
        foregroundColor: BtColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: BtColors.textPrimary,
        displayColor: BtColors.textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BtColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BtSpacing.inputPaddingH,
          vertical: BtSpacing.inputPaddingV,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
          borderSide: const BorderSide(color: BtColors.borderInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
          borderSide: const BorderSide(color: BtColors.borderInput),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
          borderSide: const BorderSide(color: BtColors.brandGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BtSpacing.radiusSm),
          borderSide: const BorderSide(color: BtColors.badgeRed),
        ),
        hintStyle: const TextStyle(color: BtColors.textMuted),
        labelStyle: const TextStyle(
          color: BtColors.textBody,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
