import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants.dart';
import '../../data/models/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';

/// Grid-view product card with live qty counter on the add button.
class GridProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onQuickAdd;
  final bool isFavourite;
  final VoidCallback onToggleFavourite;

  const GridProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onQuickAdd,
    required this.isFavourite,
    required this.onToggleFavourite,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: AppDecorations.productImage,
                  alignment: Alignment.center,
                  child:
                      Text(product.image, style: const TextStyle(fontSize: 52)),
                ),

                // Favourite button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onToggleFavourite,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.85),
                        borderRadius:
                            BorderRadius.circular(AppDecorations.radiusXS),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFavourite
                            ? colors.error
                            : colors.secondary,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Info + counter
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(product.time, style: theme.textTheme.labelSmall),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          AppConstants.formatPrice(product.price),
                          style: AppTextStyles.price.copyWith(
                              color: colors.primary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      _GridAddCounter(
                        qty: qty,
                        productId: product.id,
                        onAdd: onQuickAdd,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Compact "+" that expands to "−  N  +" once qty > 0 (grid variant).
class _GridAddCounter extends StatelessWidget {
  final int qty;
  final int productId;
  final VoidCallback onAdd;

  const _GridAddCounter({
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
      height: 28,
      width: hasItems ? 80 : 28,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppDecorations.radiusS),
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
                        color: colors.onPrimary, size: 12),
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
                      fontSize: 12,
                    ),
                  ),
                ),
                // + increment
                Expanded(
                  child: GestureDetector(
                    onTap: onAdd,
                    child: Icon(Icons.add_rounded,
                        color: colors.onPrimary, size: 12),
                  ),
                ),
              ],
            )
          : GestureDetector(
              onTap: onAdd,
              child: Icon(Icons.add_rounded,
                  color: colors.onPrimary, size: 16),
            ),
    );
  }
}
