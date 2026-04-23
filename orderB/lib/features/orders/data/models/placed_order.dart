/// Snapshot of a just-placed order, passed to the success screen.
class PlacedOrder {
  final String id;
  final String eta;
  final List<PlacedOrderItem> items;
  final double total;
  final String addressLabel;
  final String addressFull;

  const PlacedOrder({
    required this.id,
    required this.eta,
    required this.items,
    required this.total,
    required this.addressLabel,
    required this.addressFull,
  });
}

class PlacedOrderItem {
  final String name;
  final String image;
  final int quantity;
  final double price;
  final Map<String, String> selectedVariants;

  const PlacedOrderItem({
    required this.name,
    required this.image,
    required this.quantity,
    required this.price,
    this.selectedVariants = const {},
  });
}
