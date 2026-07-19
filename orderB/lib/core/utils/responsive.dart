import 'package:flutter/material.dart';

/// Responsive helpers that **scale up** content on larger screens and
/// **increase horizontal padding** so content doesn't stretch edge-to-edge
/// on tablets/iPads. Font sizes, images, and buttons grow proportionally;
/// wider screens use more grid columns and put empty space on the sides
/// instead of making everything comically wide.
///
/// Breakpoints:
/// - phone (< 600px)     → scale 1.0, 24px padding, 2 columns
/// - tablet (600–900px)  → scale 1.15, 112px padding, 2–3 columns
/// - desktop (> 900px)   → scale 1.3,  192px padding, 4 columns
abstract final class Responsive {
  static const double _phone = 600;
  static const double _tablet = 900;



  /// Multiplier for font sizes, image sizes, button heights, etc.
  static double scale(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _tablet) return 1.3;
    if (w >= _phone) return 1.15;
    return 1.0;
  }



  /// Number of columns for product grids.
  static int gridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _tablet) return 4;
    if (w >= 700) return 3;
    return 2;
  }



  /// Horizontal padding for screen edges. Doubles on tablets, quadruples
  /// on desktop so the content area stays readable.
  static double horizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _tablet) return 192;
    if (w >= _phone) return 112;
    return 24;
  }

  /// Vertical spacing between sections.
  static double sectionSpacing(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= _tablet) return 28;
    if (w >= _phone) return 20;
    return 16;
  }
}
