/// App-wide constants. Single source of truth for brand name, currency, etc.
///
/// [appName] and [currency] are *mutable* — they start at the hardcoded
/// defaults below and get overwritten via [applyBranding] once the
/// BusinessProvider's `current` slot loads from the API. Every callsite
/// reads them at render time, so the override propagates automatically on
/// the next rebuild after [applyBranding] runs. This is a single-business
/// app so we don't need them to be reactive mid-session — bootstrap
/// timing is enough.
abstract final class AppConstants {
  static String appName = 'Breaking Bread Bakery';
  static String currency = 'Rs';

  // ── Environment switch ────────────────────────────────────────────────────
  // One bool, three things switch: API host, image host, business id.
  // Easier than playing whack-a-mole with three separate constants every
  // time we move between dev and prod.

  /// `true` for prod builds, `false` for dev. Touches [apiBaseUrl],
  /// [imageHostUrl], and [bakeryBusinessId] in one shot.
  static const bool useProd = false;

  /// Beta's "sakjfhaskj" — the test catalogue with every variant +
  /// addon shape we needed to debug against (Momo's 2-axis variants,
  /// Simmi's variant+addon combo, Cafe Lungo's addon-only setup, etc).
  static const String devBusinessId = '69ccbebf7b052d7ab7e0b435';

  /// Breaking Bread Pvt Ltd — the actual customer.
  static const String prodBusinessId = '65db0f54d0199c9b3dc7ab15';

  /// The bakery's `_id` on the rebuzzpos POS backend. This app is a
  /// single-business storefront, so every product/category/popularity
  /// call is scoped to this id via the `/api/businesses/{id}/products/*`
  /// endpoints.
  static const String bakeryBusinessId =
      useProd ? prodBusinessId : devBusinessId;

  /// JSON API base URL. ApiClient reads from this.
  static const String apiBaseUrl = useProd
      ? 'https://api.order.rebuzzpos.com/api'
      : 'https://api.beta.order.rebuzzpos.com/api';

  /// Host that serves product and business-logo images — a *different*
  /// subdomain from the API host (images on `*.rebuzzpos.com`, JSON on
  /// `*.order.rebuzzpos.com`). Easy to confuse.
  static const String imageHostUrl = useProd
      ? 'https://appapi.rebuzzpos.com'
      : 'https://api.beta.rebuzzpos.com';

  /// Format a price value for display (e.g. "Rs 500").
  static String formatPrice(double price) =>
      '$currency ${price.toStringAsFixed(0)}';

  /// Overwrite the mutable branding fields from API-loaded values. Pass
  /// primitives (not the [ApiBusiness] model) so this file stays free of
  /// feature-layer imports — `core/` shouldn't depend on `features/`.
  /// Empty/null inputs are ignored so partial backend data doesn't blank
  /// out the defaults.
  static void applyBranding({
    String? appName,
    String? currency,
  }) {
    final n = appName?.trim();
    if (n != null && n.isNotEmpty) AppConstants.appName = n;
    final c = currency?.trim();
    if (c != null && c.isNotEmpty) AppConstants.currency = c;
  }

  /// Build an absolute image URL from whatever the API returned.
  /// Returns null for null/empty input. Pass-through if already absolute.
  static String? resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleaned = path.startsWith('/') ? path.substring(1) : path;
    return '$imageHostUrl/$cleaned';
  }
}
