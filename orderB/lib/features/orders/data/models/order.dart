import 'package:flutter/foundation.dart';
import '../../../../core/constants.dart';

/// One add-on attached to an order line, as returned by /my-orders.
/// Backends are inconsistent about how much detail they hydrate here;
/// fields default to empty/0 when missing.
class OrderItemAddon {
  final String id;
  final String name;
  final double price;
  final int quantity;

  const OrderItemAddon({
    required this.id,
    this.name = '',
    this.price = 0,
    this.quantity = 1,
  });

  OrderItemAddon copyWith({String? name, double? price}) => OrderItemAddon(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        quantity: quantity,
      );
}

class OrderItem {
  final String name;

  /// Emoji fallback or relative/absolute image path.
  final String image;
  final int qty;
  final double price;
  final Map<String, String> selectedVariants;
  final String? productId;

  /// Add-ons attached to this line (e.g. Egg, Cheese on a Simmi).
  /// Empty list for items that have none.
  final List<OrderItemAddon> addons;

  const OrderItem({
    required this.name,
    required this.image,
    this.qty = 1,
    this.price = 0,
    this.selectedVariants = const {},
    this.productId,
    this.addons = const [],
  });

  /// Per-unit total including addons. `price` alone is just the variant
  /// price; this getter is what the customer actually paid per unit.
  double get unitTotal {
    final addonTotal = addons.fold<double>(
      0,
      (sum, a) => sum + a.price * a.quantity,
    );
    return price + addonTotal;
  }

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

    // Addons can come back as full objects (when the backend joins the
    // Addon collection) or as bare ObjectId strings (when it doesn't).
    // Parse defensively — name/price stay empty when the backend
    // doesn't hydrate them; OrderProvider enriches the missing pieces
    // from the catalogue on read.
    final List<OrderItemAddon> addons = [];
    final rawAddons = json['addons'];
    if (rawAddons is List) {
      for (final raw in rawAddons) {
        if (raw is Map) {
          final id = (raw['_id'] ?? raw['id'] ?? raw['addon'] ?? '')
              .toString();
          if (id.isEmpty) continue;
          addons.add(OrderItemAddon(
            id: id,
            name: raw['name']?.toString() ?? '',
            price: (raw['price'] as num?)?.toDouble() ?? 0,
            quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
          ));
        } else if (raw is String && raw.isNotEmpty) {
          addons.add(OrderItemAddon(id: raw));
        }
      }
    }

    return OrderItem(
      name: name,
      image: image,
      qty: qty,
      price: price,
      selectedVariants: variants,
      productId: prodId,
      addons: addons,
    );
  }

  OrderItem copyWith({double? price, List<OrderItemAddon>? addons}) =>
      OrderItem(
        name: name,
        image: image,
        qty: qty,
        price: price ?? this.price,
        selectedVariants: selectedVariants,
        productId: productId,
        addons: addons ?? this.addons,
      );
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

  Order copyWith({List<OrderItem>? items, double? total}) => Order(
        id: id,
        date: date,
        createdAt: createdAt,
        items: items ?? this.items,
        total: total ?? this.total,
        status: status,
      );

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

    // The /ticket endpoints aren't fully consistent on the total field
    // across rebuzzpos environments — different keys carry the grand
    // total in different responses. Walk the most common ones first;
    // if all of them are missing or zero, fall back to summing the
    // items we just parsed so cards never show "Rs 0" when there's
    // clearly a real order behind them.
    double pickNum(List<dynamic> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is num && v > 0) return v.toDouble();
      }
      return 0;
    }

    // grandTotal is the final post-charges amount on the rebuzzpos
    // ticket schema — prefer it over `total`, which has been observed
    // to carry just one line item's price (no idea why). totalAmount
    // is a defensive alias older endpoints sometimes use.
    double total = pickNum(const [
      'grandTotal',
      'totalAmount',
      'total',
      'subTotal',
      'subtotal',
      'orderTotal',
      'cost',
      'amount',
      'totalCost',
      'totalPrice',
    ]);

    // If the server's totals are zero (old tickets, weird state), sum
    // the line items we parsed. Also override when the server total
    // looks suspiciously small compared to the items sum — the parser
    // would otherwise show 120 for a 495 order if `total` came back
    // wrong.
    if (items.isNotEmpty) {
      final itemsSum =
          items.fold<double>(0, (sum, it) => sum + it.price * it.qty);
      if (total == 0 || (itemsSum > 0 && itemsSum > total)) {
        total = itemsSum;
      }
    }

    if (total == 0) {
      debugPrint(
          '🟡 Order ${json['_id']}: total=0 from API and items also sum to 0 — '
          'likely an old ticket created before the unitPrice POST fix.');
    } else {
      debugPrint(
          '🟢 Order ${json['_id']}: total=$total '
          '(apiTotal=${json['total']}, apiGrandTotal=${json['grandTotal']}, '
          'items=${items.map((i) => "${i.name} x${i.qty} @${i.price}").join(", ")})');
    }

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
