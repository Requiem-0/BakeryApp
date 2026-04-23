import '../../../catalogue/data/models/product.dart';

/// A cart line item: product + quantity + selected variant choices.
class CartItem {
  final Product product;
  int quantity;

  /// Map of variant group title → selected option (e.g. {'Fillings': 'Chicken'}).
  final Map<String, String> selectedVariants;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedVariants = const {},
  });
}
