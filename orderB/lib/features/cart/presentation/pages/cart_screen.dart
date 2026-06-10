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

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _showAddressSheet(BuildContext context) {
    final prov = context.read<AddressProvider>();
    AddressBottomSheet.show(context,
        selectedId: prov.selectedId,
        onSelect: (id) => prov.select(id));
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addrProv = context.watch<AddressProvider>();
    final favProv = context.watch<FavouritesProvider>();
    final catProv = context.watch<CatalogueProvider>();

    debugPrint('🛒 CartScreen.build() — cart.items=${cart.items.length}, totalCount=${cart.totalCount}, subtotal=${cart.subtotal}');
    if (cart.items.isNotEmpty) {
      for (final item in cart.items) {
        debugPrint('   • ${item.product.name} x${item.quantity} @ ${item.product.price} (id=${item.product.id})');
      }
    } else {
      debugPrint('   ⚠️ Cart is EMPTY');
    }

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
                padding: const EdgeInsets.only(right: 24),
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
                : ListView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    children: [
                      ...cart.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProductCard(
                                product: item.product,
                                priceOverride: item.unitPrice,
                                onTap: () => context.push('/home/product',
                                    extra: item.product),
                                onQuickAdd: () =>
                                    cart.addProduct(item.product),
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
                                  value: cart.subtotal),
                              // Service charge only renders when the
                              // business actually has one set on the
                              // backend — keeps the summary clean for
                              // bakeries that don't levy a fee.
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

          // Checkout button pinned to bottom
          if (cart.items.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
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

  const _PriceSummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        Text(AppConstants.formatPrice(value),
            style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600)),
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
