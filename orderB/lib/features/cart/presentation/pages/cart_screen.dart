import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../../../catalogue/data/models/product.dart';
import '../../../catalogue/presentation/providers/catalogue_provider.dart';
import '../../../address/presentation/widgets/address_selector.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../catalogue/presentation/widgets/product_card.dart';
import '../../../catalogue/presentation/widgets/grid_product_card.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../favourites/presentation/providers/favourites_provider.dart';
import '../widgets/empty_cart_view.dart';
import '../../../../core/brandkit/app_colors.dart';
import '../../../../core/brandkit/app_decorations.dart';
import '../../../../core/brandkit/app_text_styles.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants.dart';
import '../../../../core/utils/responsive.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showAddressSheet(BuildContext context) {
    final prov = context.read<AddressProvider>();
    AddressBottomSheet.show(context,
        selectedId: prov.selectedId,
        onSelect: (id) => prov.select(id));
  }

  Future<void> _confirmClearCart(
      BuildContext context, CartProvider cart) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'This removes everything in your cart. You can add items '
          "again from the menu.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Fire-and-forget. Awaiting after the dialog pops keeps the
    // caller's BuildContext alive while the cart rebuilds to empty;
    // on Chrome that locks the UI until the server DELETE returns.
    // Local clear already notified listeners — the rest can finish
    // whenever the server gets around to it.
    unawaited(cart.clear());
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addrProv = context.watch<AddressProvider>();
    final favProv = context.watch<FavouritesProvider>();
    final catProv = context.watch<CatalogueProvider>();

    final cartIds = cart.items.map((i) => i.product.id).toSet();
    final suggestions = catProv.products
        .map(Product.fromApi)
        .where((p) => !cartIds.contains(p.id))
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // /cart is the root of the Cart shell branch — tapping the tab lands
        // here with nothing on the stack to pop. Only show the back button
        // when this screen was actually pushed onto a navigator.
        leading: Navigator.of(context).canPop()
            ? const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: AppBackButton(),
              )
            : null,
        title: const Text('Your Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  '${cart.totalCount} item${cart.totalCount != 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const EmptyCartView()
                : RefreshIndicator(
                    // Re-syncs the server-side cart for authed users.
                    // Useful when an item the customer added on the
                    // web was modified (price/availability) between
                    // sessions. No-op for guests — `bootstrap`
                    // short-circuits without a token.
                    onRefresh: () => cart.bootstrap(),
                    child: ListView(
                    padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 0, Responsive.horizontalPadding(context), 16),
                    children: [
                      // "Clear all" mirrors the OrderCard's "Reorder"
                      // text-link style: underlined, no icon, no
                      // background, error color. Right-aligned so it
                      // doesn't visually compete with the first
                      // product card directly under it.
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 4, right: 4, bottom: 20),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () =>
                                _confirmClearCart(context, cart),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                            ),
                            child: Text(
                              'Clear all',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Theme.of(context)
                                        .colorScheme
                                        .error
                                        .withValues(alpha: 0.5),
                                  ),
                            ),
                          ),
                        ),
                      ),
                      ...cart.items.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductCard(
                                product: item.product,
                                // Per-unit cost INCLUDING addons, so the
                                // line price matches what the customer
                                // actually pays. unitPrice alone shows
                                // only the variant (Rs 40 Large), which
                                // makes the +Egg subtitle look free.
                                priceOverride: item.quantity > 0
                                    ? item.lineTotal / item.quantity
                                    : item.unitPrice,
                                onTap: () => context.push('/home/product',
                                    extra: item.product),
                                onQuickAdd: () =>
                                    cart.addProduct(item.product),
                                // Override the default product-id-based
                                // counter with one that targets THIS
                                // cart line by index — so +/− works
                                // for variant-distinct lines (two
                                // Simmis with different variant+addon
                                // combos no longer share a counter).
                                trailingCounter: _CartLineCounter(
                                  quantity: item.quantity,
                                  onIncrement: () => cart.updateQuantity(
                                      idx, item.quantity + 1),
                                  onDecrement: () => cart.updateQuantity(
                                      idx, item.quantity - 1),
                                ),
                                isFavourite:
                                    favProv.isFavourite(item.product.id),
                                onToggleFavourite: () =>
                                    favProv.toggle(item.product.id),
                              ),
                              if (item.variantItemLabel != null ||
                                  item.addons.isNotEmpty)
                                _CartLineDetail(item: item),
                            ],
                          ),
                        );
                      }),

                      // Suggestions
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('Add something extra?',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 230,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: suggestions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 14),
                            itemBuilder: (_, i) {
                              final p = suggestions[i];
                              return SizedBox(
                                width: 160,
                                child: GridProductCard(
                                  product: p,
                                  onTap: () => context
                                      .push('/home/product', extra: p),
                                  onQuickAdd: () => cart.addProduct(p),
                                  isFavourite: favProv.isFavourite(p.id),
                                  onToggleFavourite: () =>
                                      favProv.toggle(p.id),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Address
                      Text('DELIVER TO', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 8),
                      AddressSelector(
                        selectedId: addrProv.selectedId,
                        onTap: () => _showAddressSheet(context),
                        variant: AddressSelectorVariant.compact,
                      ),
                      const SizedBox(height: 16),

                      // Price summary
                      Card(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLow
                            .withValues(alpha: 0.5),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              AppDecorations.radiusCard),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.05),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _PriceSummaryRow(
                                  label: 'Subtotal',
                                  value: cart.subtotal + cart.discountTotal),
                              // Discount line only when an
                              // applyEverytime rule actually fired on
                              // a cart item — keeps the summary clean
                              // otherwise.
                              if (cart.discountTotal > 0) ...[
                                const SizedBox(height: 10),
                                _PriceSummaryRow(
                                    label: 'Discount',
                                    value: -cart.discountTotal,
                                    color: Theme.of(context).colorScheme.error),
                              ],
                              // Service charge only renders when the
                              // business actually has one set on the
                              // backend.
                              if (cart.serviceCharge > 0) ...[
                                const SizedBox(height: 10),
                                _PriceSummaryRow(
                                    label: 'Service charge',
                                    value: cart.serviceCharge),
                              ],
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                child: Divider(
                                    height: 1,
                                    color: AppColors.softBrown
                                        .withValues(alpha: 0.1)),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium),
                                  Text(
                                      AppConstants.formatPrice(cart.total),
                                      style: AppTextStyles.priceLarge
                                          .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
            ),
          ),

          // Checkout button pinned to bottom
          if (cart.items.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(Responsive.horizontalPadding(context), 8, Responsive.horizontalPadding(context), 8),
                child: PrimaryButton(
                  label: 'Checkout — ${AppConstants.formatPrice(cart.total)}',
                  onTap: () {
                    if (cart.items.isNotEmpty) {
                      context.push('/cart/checkout');
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PriceSummaryRow extends StatelessWidget {
  final String label;
  final double value;

  /// Optional override for both label and value text colour. Used by
  /// the discount row to render in the theme's error colour.
  final Color? color;

  const _PriceSummaryRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = value < 0;
    final display = isNegative
        ? '− ${AppConstants.formatPrice(-value)}'
        : AppConstants.formatPrice(value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
        Text(display,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            )),
      ],
    );
  }
}

/// Renders the chosen variant + addons under a cart line, so the customer
/// can tell their picks apart at a glance ("Chicken Momo · Steam · +Egg").
/// Hidden entirely when the line has neither — keeps simple products
/// looking simple.
class _CartLineDetail extends StatelessWidget {
  final dynamic item; // CartItem — typed loosely to avoid an extra import

  const _CartLineDetail({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <String>[
      if (item.variantItemLabel != null) item.variantItemLabel as String,
      for (final addon in item.addons)
        addon.quantity > 1
            ? '+${addon.name} ×${addon.quantity}'
            : '+${addon.name}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Text(
        parts.join(' · '),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Cart-line +/− counter. Identical visual to [AddCounter] but the
/// callbacks are wired to the specific [CartItem] index instead of
/// the product id, so two cart lines that share a product (different
/// variants/addons) each manipulate themselves cleanly.
class _CartLineCounter extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _CartLineCounter({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 32,
      width: 88,
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
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onDecrement,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.remove_rounded,
                  color: colors.onPrimary, size: 14),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '$quantity',
              key: ValueKey(quantity),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onIncrement,
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.add_rounded,
                  color: colors.onPrimary, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
