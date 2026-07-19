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

/// A discount rule that fired on an order line. Carries the metadata
/// (name + rate + type) so receipts can show "Saved Rs X via [name]".
class OrderItemDiscount {
  /// Backend's catalogue id for the discount rule.
  final String id;
  final String name;

  /// "percentage" or "flat" — backend's own enum.
  final String type;

  /// For percentage: 10 means 10%. For flat: the absolute amount.
  final double rate;

  const OrderItemDiscount({
    required this.id,
    this.name = '',
    this.type = '',
    this.rate = 0,
  });

  factory OrderItemDiscount.fromJson(Map<String, dynamic> json) {
    return OrderItemDiscount(
      id: (json['discount'] ?? json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      rate: ((json['rate'] as num?) ?? 0).toDouble(),
    );
  }
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

  /// Tax charged on this line (0 when not taxable / not applied). Summed
  /// across items to drive the order-level "Tax" row.
  final double taxAmount;
  final bool taxApplied;

  /// Discount in absolute currency knocked off this line (17.9 = Rs 17.9
  /// off). Separate from the discount metadata (name/rate/type) — that
  /// lives in [discountsApplied] for receipt-style display.
  final double discount;

  /// Customer note attached at checkout (e.g. "less spicy"). Empty when
  /// none was set.
  final String note;

  /// Discount metadata as the backend returned it — one entry per
  /// discount rule that fired on this line. Useful for "Saved Rs X via
  /// [name]" rows in the receipt.
  final List<OrderItemDiscount> discountsApplied;

  const OrderItem({
    required this.name,
    required this.image,
    this.qty = 1,
    this.price = 0,
    this.selectedVariants = const {},
    this.productId,
    this.addons = const [],
    this.taxAmount = 0,
    this.taxApplied = false,
    this.discount = 0,
    this.note = '',
    this.discountsApplied = const [],
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

    // Prefer the catalogue id (`addon` / `addonId`) over the
    // Mongoose subdoc `_id` — only the catalogue id matches against
    // product.addons during enrichment.
    final List<OrderItemAddon> addons = [];
    final rawAddons = json['addons'];
    if (rawAddons is List) {
      for (final raw in rawAddons) {
        if (raw is Map) {
          final id =
              (raw['addon'] ?? raw['addonId'] ?? raw['_id'] ?? raw['id'] ?? '')
                  .toString();
          if (id.isEmpty) continue;
          final priceRaw = raw['price'] ?? raw['unitPrice'];
          addons.add(OrderItemAddon(
            id: id,
            name: raw['name']?.toString() ?? '',
            price: (priceRaw as num?)?.toDouble() ?? 0,
            quantity: (raw['quantity'] as num?)?.toInt() ?? 1,
          ));
        } else if (raw is String && raw.isNotEmpty) {
          addons.add(OrderItemAddon(id: raw));
        }
      }
    }

    final discountsApplied = <OrderItemDiscount>[];
    final rawDiscounts = json['discounts'];
    if (rawDiscounts is List) {
      for (final raw in rawDiscounts) {
        if (raw is Map<String, dynamic>) {
          discountsApplied.add(OrderItemDiscount.fromJson(raw));
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
      taxAmount: ((json['taxAmount'] as num?) ?? 0).toDouble(),
      taxApplied: (json['taxApplied'] as bool?) ?? false,
      discount: ((json['discount'] as num?) ?? 0).toDouble(),
      note: (json['note'] ?? '').toString(),
      discountsApplied: discountsApplied,
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
        taxAmount: taxAmount,
        taxApplied: taxApplied,
        discount: discount,
        note: note,
        discountsApplied: discountsApplied,
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

  /// Order lifecycle status as returned by the API ("Pending", "Delivered",
  /// etc.). Today the backend rarely populates this — see [displayStatus]
  /// for the UI's actual signal.
  final String status;

  /// Payment state — "paid" or "unpaid". Default for newly-placed cash
  /// orders is "unpaid"; merchant flips it from rebuzzpos POS.
  final String paidStatus;

  /// True once the merchant has closed/checked out the ticket on the POS.
  /// Independent of [paidStatus] in principle.
  final bool checkedOut;

  /// Human-readable order number from the backend (e.g. 295). Null for
  /// older orders / endpoints that don't return it.
  final int? invoice;

  /// "cash" today, "fonepay" / etc. later. Empty when not returned.
  final String paymentMethod;

  /// Address-record id the backend stored on the order. Resolves to a
  /// full Address by hitting the address repo if needed.
  final String? deliveryLocationId;

  /// Order-level discount in absolute currency (sum of all line discounts
  /// the backend pre-aggregated). Zero when nothing fired.
  final double discount;

  /// Sum of per-line `taxAmount`s — surfaced as a "Tax" row when > 0.
  final double tax;

  const Order({
    required this.id,
    required this.date,
    required this.items,
    required this.total,
    required this.status,
    this.createdAt,
    this.paidStatus = 'unpaid',
    this.checkedOut = false,
    this.invoice,
    this.paymentMethod = '',
    this.deliveryLocationId,
    this.discount = 0,
    this.tax = 0,
  });

  Order copyWith({List<OrderItem>? items, double? total}) => Order(
        id: id,
        date: date,
        createdAt: createdAt,
        items: items ?? this.items,
        total: total ?? this.total,
        status: status,
        paidStatus: paidStatus,
        checkedOut: checkedOut,
        invoice: invoice,
        paymentMethod: paymentMethod,
        deliveryLocationId: deliveryLocationId,
        discount: discount,
        tax: tax,
      );

  /// Falls back to payment state when the backend leaves [status] as
  /// the default "Pending" — which is the case for most orders today.
  /// Real lifecycle states ("Delivered", "Cancelled", etc.) win when
  /// the backend sends them.
  String get displayStatus {
    if (status != 'Pending') return status;
    if (checkedOut && paidStatus == 'paid') return 'Completed';
    return paidStatus == 'paid' ? 'Paid' : 'Unpaid';
  }

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
      // Backend stores UTC. The string usually carries a 'Z', but
      // we've been burned before — when it doesn't, tryParse falls
      // back to "local" and our .toLocal() becomes a no-op (so the
      // user sees a UTC timestamp on their Nepal clock, off by
      // 5h45m). Coerce to UTC when no tz was seen, then convert.
      var parsed = DateTime.tryParse(rawDate.toString());
      if (parsed != null) {
        if (!parsed.isUtc) {
          parsed = DateTime.utc(
            parsed.year,
            parsed.month,
            parsed.day,
            parsed.hour,
            parsed.minute,
            parsed.second,
            parsed.millisecond,
            parsed.microsecond,
          );
        }
        createdAt = parsed.toLocal();
      }
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

    // /ticket endpoints disagree on which key carries the order total.
    // Try the canonical names in order, fall back to summing items.
    double pickNum(List<dynamic> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is num && v > 0) return v.toDouble();
      }
      return 0;
    }

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

    // Backend sometimes returns 0 or a single-line value. Trust the
    // sum when it's bigger.
    if (items.isNotEmpty) {
      final itemsSum =
          items.fold<double>(0, (sum, it) => sum + it.price * it.qty);
      if (total == 0 || (itemsSum > 0 && itemsSum > total)) {
        total = itemsSum;
      }
    }

    final status = (json['status'] ?? json['orderStatus'] ?? 'pending')
        .toString()
        .toLowerCase();

    final paidStatus = (json['paidStatus'] ?? 'unpaid').toString().toLowerCase();
    final checkedOut = (json['checkedOut'] as bool?) ?? false;
    final invoice = (json['invoice'] as num?)?.toInt();
    final paymentMethod =
        (json['paymentMethod'] ?? '').toString().toLowerCase();

    // deliveryLocation comes back as an id string on POST/my-orders. The
    // detail screen can resolve it to a full address via the address
    // repo when needed.
    final deliveryLocationId = json['deliveryLocation'] is String
        ? json['deliveryLocation'] as String
        : null;

    final orderDiscount = ((json['discount'] as num?) ?? 0).toDouble();
    final taxTotal =
        items.fold<double>(0, (sum, it) => sum + it.taxAmount * it.qty);

    return Order(
      id: '#${id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id.toUpperCase()}',
      date: date,
      createdAt: createdAt,
      items: items,
      total: total,
      status: _normaliseStatus(status),
      paidStatus: paidStatus,
      checkedOut: checkedOut,
      invoice: invoice,
      paymentMethod: paymentMethod,
      deliveryLocationId: deliveryLocationId,
      discount: orderDiscount,
      tax: taxTotal,
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
