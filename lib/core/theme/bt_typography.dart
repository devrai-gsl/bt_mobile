import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bt_colors.dart';

/// Typography tokens from Figma (Onest headings, Inter body).
abstract final class BtTypography {
  static TextStyle get heading2xlMedium => GoogleFonts.onest(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        height: 1.25,
        color: BtColors.textPrimary,
      );

  static TextStyle get headingXlSemibold => GoogleFonts.onest(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 4 / 3,
        color: BtColors.textPrimary,
      );

  static TextStyle get headingXlMedium => GoogleFonts.onest(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        height: 4 / 3,
        color: BtColors.textPrimary,
      );

  static TextStyle get headingLgSemibold => GoogleFonts.onest(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodyLgMedium => GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodyBaseSemibold => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.5,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodyBaseMedium => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.5,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodyBaseRegular => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: BtColors.textBody,
      );

  static TextStyle get bodyMdSemibold => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodyMdMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodyMdRegular => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: BtColors.textBody,
      );

  static TextStyle get bodyMdRegularParagraph => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 22 / 14,
        color: BtColors.textBody,
      );

  static TextStyle get bodySmSemibold => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        height: 4 / 3,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodySmMedium => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 4 / 3,
        color: BtColors.textPrimary,
      );

  static TextStyle get bodySmRegular => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 4 / 3,
        color: BtColors.textSecondary,
      );

  static TextStyle get bodySmRegularParagraph => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: BtColors.textBody,
      );

  static TextStyle get bodyXsSemibold => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: BtColors.textBody,
      );

  static TextStyle get link => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
        color: BtColors.brandGreen,
      );
}
