/// An item in a past order.
class OrderItem {
  final String name;
  final String image;
  final int qty;
  final Map<String, String> selectedVariants;

  const OrderItem({
    required this.name,
    required this.image,
    required this.qty,
    this.selectedVariants = const {},
  });
}

/// A completed/past order record.
class Order {
  final String id;
  final String date;
  final List<OrderItem> items;
  final double total;
  final String status;

  const Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
  });
}
