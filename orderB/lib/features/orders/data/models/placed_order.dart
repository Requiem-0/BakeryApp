/// Snapshot of a just-placed order, passed to the success screen.
class PlacedOrder {
  final String id;
  final String eta;
  final List<PlacedOrderItem> items;

  /// Sum of all line items before any discount applies. Equals [total]
  /// when no rules fired.
  final double subtotal;

  /// Total amount knocked off via `applyEverytime` rules. Zero when no
  /// items in the order carry an active rule.
  final double discount;

  /// Final amount the customer owes — [subtotal] minus [discount] plus
  /// any service charge.
  final double total;

  final String addressLabel;
  final String addressFull;
  final String status;

  const PlacedOrder({
    required this.id,
    required this.eta,
    required this.items,
    required this.total,
    required this.addressLabel,
    required this.addressFull,
    this.subtotal = 0,
    this.discount = 0,
    this.status = 'Processing',
  });
}

class PlacedOrderItem {
  final String name;
  final String image;
  final int quantity;
  final double price;
  final Map<String, String> selectedVariants;

  /// Flat variant label (e.g. "Large", "Steam · Medium") used when
  /// [selectedVariants] is empty — that's the case for quick-add
  /// items from the home card, which only populate the label and
  /// leave the structured map blank. The receipt falls back to this
  /// so the variant name still appears on the bill.
  final String? variantLabel;

  /// Display strings for selected addons, pre-formatted for the bill —
  /// e.g. `["+Mayonnaise", "+Extra Cheese ×2"]`. The checkout layer
  /// builds these from each cart line's [CartItemAddon] list so the
  /// success screen doesn't have to redo the formatting.
  final List<String> addons;

  const PlacedOrderItem({
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
    this.selectedVariants = const {},
    this.variantLabel,
    this.addons = const [],
  });
}
