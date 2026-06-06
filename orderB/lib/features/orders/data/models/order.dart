import '../../../../core/constants.dart';

class OrderItem {
  final String name;

  /// Emoji fallback or relative/absolute image path.
  final String image;
  final int qty;
  final double price;
  final Map<String, String> selectedVariants;
  final String? productId;

  const OrderItem({
    required this.name,
    required this.image,
    this.qty = 1,
    this.price = 0,
    this.selectedVariants = const {},
    this.productId,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Items can arrive as { product: {...}, quantity, price, selectedVariants }
    // or as flat { name, image, qty, price }.
    final productNode = json['product'];
    final String name;
    final String image;
    String? prodId;

    if (productNode is Map<String, dynamic>) {
      prodId = (productNode['_id'] ?? productNode['id'])?.toString();
      name = (productNode['name'] ?? productNode['productName'] ?? 'Item')
          .toString();
      final rawImg =
          productNode['image'] ?? productNode['imageUrl'] ?? '';
      image = AppConstants.resolveImageUrl(rawImg.toString()) ??
          rawImg.toString();
    } else {
      if (productNode != null) {
        prodId = productNode.toString();
      } else {
        prodId = (json['productId'] ?? json['product'])?.toString();
      }
      name =
          (json['name'] ?? json['productName'] ?? 'Item').toString();
      final rawImg = json['image'] ?? json['imageUrl'] ?? json['productImage'] ?? '';
      image = AppConstants.resolveImageUrl(rawImg.toString()) ??
          rawImg.toString();
    }

    final qty = (json['quantity'] ?? json['qty'] ?? 1) as int? ?? 1;
    final price =
        (json['price'] ?? json['unitPrice'] ?? 0).toDouble();

    Map<String, String> variants = const {};
    final rawVariants = json['selectedVariants'];
    if (rawVariants is Map) {
      variants = rawVariants
          .map((k, v) => MapEntry(k.toString(), v.toString()));
    }

    return OrderItem(
      name: name,
      image: image,
      qty: qty,
      price: price,
      selectedVariants: variants,
      productId: prodId,
    );
  }
}

/// A completed / past order record fetched from the API.
class Order {
  final String id;

  /// Human-readable date string (e.g. "Today, 10:32 AM" or "Feb 21, 2024").
  final String date;

  /// Raw ISO-8601 timestamp from the API — kept for sorting.
  final DateTime? createdAt;

  final List<OrderItem> items;
  final double total;

  /// Status string exactly as returned by the API ("pending", "delivered", etc.)
  final String status;

  const Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    this.createdAt,
  });

  /// Returns false for ghost / malformed orders where the backend returned a
  /// ticket whose product references were not populated (all items fall back
  /// to the generic "Item" name and the total is zero).
  bool get isValid {
    if (items.isEmpty) return false;
    final allGeneric = items.every((i) => i.name == 'Item');
    return !(allGeneric && total == 0);
  }

  /// Parse a single order object from the API response.
  /// Handles both `_id` (Mongoose) and `id` keys defensively.
  factory Order.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? '').toString();

    DateTime? createdAt;
    final rawDate = json['createdAt'] ?? json['date'];
    if (rawDate != null) {
      createdAt = DateTime.tryParse(rawDate.toString());
    }

    final date = createdAt != null
        ? _formatDate(createdAt)
        : (rawDate?.toString() ?? '');

    final rawItems = json['items'];
    final items = <OrderItem>[];
    if (rawItems is List) {
      for (final wrapper in rawItems) {
        if (wrapper is Map<String, dynamic>) {
          // /api/ticket/my-orders nests items inside items[].item[]
          final nested = wrapper['item'];
          if (nested is List && nested.isNotEmpty) {
            for (final innerItem in nested) {
              if (innerItem is Map<String, dynamic>) {
                items.add(OrderItem.fromJson(innerItem));
              }
            }
          } else {
            // Flat structure used by /api/ticket/ or other endpoints
            items.add(OrderItem.fromJson(wrapper));
          }
        }
      }
    }

    final total = ((json['totalAmount'] ??
                json['total'] ??
                json['grandTotal'] ??
                0) as num)
        .toDouble();

    final status = (json['status'] ?? json['orderStatus'] ?? 'pending')
        .toString()
        .toLowerCase();

    return Order(
      id: '#${id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase()}',
      date: date,
      createdAt: createdAt,
      items: items,
      total: total,
      status: _normaliseStatus(status),
    );
  }

  static String _normaliseStatus(String raw) {
    switch (raw) {
      case 'delivered':
      case 'completed':
        return 'Delivered';
      case 'picked_up':
      case 'pickedup':
      case 'picked up':
        return 'Picked Up';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      case 'processing':
        return 'Processing';
      case 'out_for_delivery':
      case 'out for delivery':
        return 'Out for Delivery';
      default:
        return raw.isEmpty
            ? 'Pending'
            : raw[0].toUpperCase() + raw.substring(1);
    }
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final timeStr =
        '${_pad(dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour)}:${_pad(dt.minute)} ${dt.hour >= 12 ? 'PM' : 'AM'}';

    if (date == today) return 'Today, $timeStr';

    final yesterday = today.subtract(const Duration(days: 1));
    if (date == yesterday) return 'Yesterday, $timeStr';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, $timeStr';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
