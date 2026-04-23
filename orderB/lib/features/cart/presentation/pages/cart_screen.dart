import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../../../address/presentation/providers/address_provider.dart';
import '../../../catalogue/data/datasources/catalogue_local_datasource.dart';
import '../../../address/presentation/widgets/address_selector.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../catalogue/presentation/widgets/product_card.dart';
import '../../../catalogue/presentation/widgets/grid_product_card.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../favourites/presentation/providers/favourites_provider.dart';
import '../widgets/empty_cart_view.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_text_styles.dart';
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

    final cartIds = cart.items.map((i) => i.product.id).toSet();
    final suggestions = CatalogueLocalDatasource.products
        .where((p) => !cartIds.contains(p.id))
        .take(4)
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: AppBackButton(),
        ),
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
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: cart.items.isEmpty
                      ? const EmptyCartView()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 150),
                          children: [
                            ...cart.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: ProductCard(
                                  product: item.product,
                                  onTap: () => context.push('/home/product',
                                      extra: item.product),
                                  onQuickAdd: () =>
                                      cart.addProduct(item.product),
                                  isFavourite:
                                      favProv.isFavourite(item.product.id),
                                  onToggleFavourite: () =>
                                      favProv.toggle(item.product.id),
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
                                    const SizedBox(height: 10),
                                    const _PriceSummaryRow(
                                        label: 'Baking fee', value: 2.50),
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
                          ],
                        ),
                ),
              ],
            ),

            // Checkout button
            if (cart.items.isNotEmpty)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: PrimaryButton(
                  label: 'Checkout — ${AppConstants.formatPrice(cart.total)}',
                  onTap: () {
                    if (cart.items.isNotEmpty) {
                      context.push('/cart/checkout');
                    }
                  },
                ),
              ),
          ],
        ),
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
