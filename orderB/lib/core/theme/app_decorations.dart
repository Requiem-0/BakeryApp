import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Shared decorations, shadows and border-radius constants.
abstract final class AppDecorations {
  // ─── Border Radii ───────────────────────────────────────────
  static const double radiusXS = 8.0;
  static const double radiusS = 10.0;
  static const double radiusSM = 12.0;
  static const double radiusM = 14.0;
  static const double radiusML = 16.0;
  static const double radiusL = 18.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusCard = 20.0;
  static const double radiusPill = 50.0;

  // ─── Box Shadows ────────────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> cardShadowHovered = [
    BoxShadow(
      color: Color(0x1F4A3728),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> ctaShadow = [
    BoxShadow(
      color: Color(0x404A3728),
      blurRadius: 30,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> sheetShadow = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 40,
      offset: Offset(0, -10),
    ),
  ];

  // ─── Common Decorations ─────────────────────────────────────
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: AppColors.beige),
        boxShadow: cardShadow,
      );

  static BoxDecoration get cardHovered => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(color: AppColors.beige),
        boxShadow: cardShadowHovered,
      );

  static BoxDecoration get productImage => BoxDecoration(
        borderRadius: BorderRadius.circular(radiusM),
        gradient: AppColors.productImageGradient,
      );

  static BoxDecoration get primaryGradientBox => BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(radiusL),
        boxShadow: ctaShadow,
      );

  static BoxDecoration get beigeRounded => BoxDecoration(
        color: AppColors.beige,
        borderRadius: BorderRadius.circular(radiusM),
      );

  static BoxDecoration get whiteRounded => const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.all(Radius.circular(radiusL)),
      );

  static BoxDecoration get bottomSheet => const BoxDecoration(
        color: AppColors.warmWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(radiusXXL),
          topRight: Radius.circular(radiusXXL),
        ),
      );
}
