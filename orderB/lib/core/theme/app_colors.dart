import 'package:flutter/material.dart';

/// Brand colour palette for La Petite Boulangerie.
/// Single source of truth — never hard-code colours elsewhere.
abstract final class AppColors {
  static const Color cream = Color(0xFFFFF8F0);
  static const Color beige = Color(0xFFF5E6D3);
  static const Color warmWhite = Color(0xFFFFFCF7);
  static const Color softBrown = Color(0xFF8B7355);
  static const Color darkBrown = Color(0xFF4A3728);
  static const Color caramel = Color(0xFFC4956A);
  static const Color golden = Color(0xFFD4A574);
  static const Color accent = Color(0xFFB8860B);
  static const Color lightGold = Color(0xFFF0DFC0);
  static const Color terracotta = Color(0xFFC07850);
  static const Color sage = Color(0xFFA8B89C);
  static const Color roseDust = Color(0xFFC9A9A6);
  static const Color text = Color(0xFF3D2B1F);
  static const Color textLight = Color(0xFF7A6B5D);
  static const Color white = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x14000000); // rgba(74,55,40,0.08)

  // Gradient shortcuts
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [darkBrown, softBrown],
  );

  static const Gradient heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [beige, lightGold, golden],
    stops: [0.0, 0.5, 1.0],
  );

  static const Gradient productImageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [beige, lightGold],
  );
}
