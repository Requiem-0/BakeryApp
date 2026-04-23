/// App-wide constants. Single source of truth for brand name, currency, etc.
abstract final class AppConstants {
  static const String appName = 'Breaking Bread Bakery';
  static const String currency = 'Rs';

  /// Format a price value for display (e.g. "Rs 500").
  static String formatPrice(double price) =>
      '$currency ${price.toStringAsFixed(0)}';
}
