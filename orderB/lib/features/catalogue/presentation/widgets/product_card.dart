import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/brandkit/app_decorations.dart';
import '../../../../core/brandkit/app_text_styles.dart';
import '../../../../core/constants.dart';
import '../../data/models/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import 'product_image_box.dart';

/// List-view product card with live qty counter on the add button.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;
  final bool isFavourite;
  final VoidCallback onToggleFavourite;

  /// Optional override for the price shown on this card. Used by the
  /// cart screen to display the customer's actual selected variant
  /// price (e.g. Medium @ Rs 30) instead of the product's display
  /// price (e.g. Simmi.price = Rs 20, the cheapest Small variant).
  /// Null on browse surfaces where the product's own price is
  /// authoritative.
  final double? priceOverride;

  /// Optional replacement for the bottom-right [AddCounter]. The
  /// default counter aggregates quantity across every cart line that
  /// shares this product id and increments by re-calling
  /// `addProduct(product)` (which auto-picks the first variant) —
  /// fine on browse surfaces, broken on the cart screen where two
  /// lines can share a product id but carry different
  /// variant+addon combos. Cart-line widgets pass their own counter
  /// here so +/− target the specific [CartItem] index.
  final Widget? trailingCounter;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onQuickAdd,
    required this.isFavourite,
    required this.onToggleFavourite,
    this.priceOverride,
    this.trailingCounter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final qty = context.select<CartProvider, int>((cart) => cart.items
        .where((i) => i.product.id == product.id)
        .fold(0, (sum, i) => sum + i.quantity));

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Product image (network with emoji fallback). The
                  // discount badge that used to sit here is gone —
                  // the strikethrough original price in the price row
                  // below carries the same signal more cleanly.
                  ProductImageBox(
                    imageUrl: product.imageUrl,
                    emojiFallback: product.image,
                    emojiFontSize: 40,
                    width: 90,
                    height: 90,
                  ),
                  const SizedBox(width: 16),
                  // Text column
                  Expanded(
                    child: SizedBox(
                      height: 90,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Name + favourite
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colors.primary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: onToggleFavourite,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Icon(
                                    isFavourite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: isFavourite
                                        ? colors.error
                                        : colors.secondary,
                                    size: 16,
                                    key: ValueKey(isFavourite),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(product.time, style: theme.textTheme.labelSmall),
                          // Price — sticker (product.price) struck
                          // through next to the discounted price when
                          // an autoDiscount rule is set. Skipped when
                          // priceOverride is set (cart surfaces show
                          // the actual paid price directly).
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  if (priceOverride == null &&
                                      product.discountedPrice != null) ...[
                                    Text(
                                      AppConstants.formatPrice(product.price),
                                      style: AppTextStyles.price.copyWith(
                                        color: colors.onSurfaceVariant,
                                        decoration:
                                            TextDecoration.lineThrough,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      AppConstants.formatPrice(
                                          priceOverride ??
                                              product.discountedPrice ??
                                              product.price),
                                      style: AppTextStyles.price.copyWith(
                                          color: colors.primary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Counter pinned to the bottom-right corner ─────────────────
            // Defaults to AddCounter (product-id aware, fine for browse).
            // Cart-line widgets pass their own via [trailingCounter] so
            // +/− operate on the specific cart line.
            Positioned(
              right: 14,
              bottom: 14,
              child: trailingCounter ??
                  AddCounter(
                    qty: qty,
                    productId: product.id,
                    onAdd: onQuickAdd,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Compact "+" that expands to "−  N  +" once qty > 0.
class AddCounter extends StatelessWidget {
  final int qty;
  final String productId;
  final VoidCallback onAdd;

  const AddCounter({
    super.key,
    required this.qty,
    required this.productId,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasItems = qty > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      height: 32,
      width: hasItems ? 88 : 32,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppDecorations.radiusSM),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: hasItems
          ? Row(
              children: [
                // − decrement
                Expanded(
                  child: GestureDetector(
                    onTap: () => context
                        .read<CartProvider>()
                        .updateById(productId, qty - 1),
                    child: Icon(Icons.remove_rounded,
                        color: colors.onPrimary, size: 14),
                  ),
                ),
                // Animated count
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, anim) =>
                      ScaleTransition(scale: anim, child: child),
                  child: Text(
                    '$qty',
                    key: ValueKey(qty),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                // + increment
                Expanded(
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Icon(Icons.add_rounded,
                        color: colors.onPrimary, size: 14),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: onAdd,
              child: Icon(Icons.add_rounded,
                  color: colors.onPrimary, size: 18),
            ),
    );
  }
}
