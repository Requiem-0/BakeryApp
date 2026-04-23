import 'package:flutter/foundation.dart';
import '../../data/models/cart_item.dart';
import '../../../catalogue/data/models/product.dart';
import '../../../orders/data/models/order.dart';
import '../../../catalogue/data/datasources/catalogue_local_datasource.dart';

/// Manages shopping cart state.
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal =>
      _items.fold(0.0, (sum, i) => sum + i.product.price * i.quantity);

  static const double bakingFee = 2.50;
  double get total => subtotal + bakingFee;

  bool contains(Product product) =>
      _items.any((i) => i.product.id == product.id);

  void addProduct(Product product, {
    int quantity = 1,
    Map<String, String> selectedVariants = const {},
  }) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        product: product,
        quantity: quantity,
        selectedVariants: selectedVariants,
      ));
    }
    notifyListeners();
  }

  void updateQuantity(int index, int qty) {
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = qty;
    }
    notifyListeners();
  }

  void updateById(int productId, int qty) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index < 0) return;
    if (qty <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = qty;
    }
    notifyListeners();
  }

  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Finds items from a past order in the global menu and adds them to cart.
  void reorder(Order pastOrder) {
    for (final orderItem in pastOrder.items) {
      try {
        final product = CatalogueLocalDatasource.products.firstWhere(
          (p) => p.name == orderItem.name,
        );
        addProduct(product, quantity: orderItem.qty);
      } catch (e) {
        // If a product was removed from the menu, skip it
        debugPrint('Product from old order no longer found: ${orderItem.name}');
      }
    }
  }
}
