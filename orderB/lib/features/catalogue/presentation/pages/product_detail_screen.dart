import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../favourites/presentation/providers/favourites_provider.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../cart/presentation/widgets/product_bottom_cta.dart';

import 'package:go_router/go_router.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 0;
  final TextEditingController _instructionsCtrl = TextEditingController();

  late final List<int> _selectedVariants =
      List.filled(widget.product.variants.length, 0);

  Map<String, String> get _variantSelections {
    final variants = widget.product.variants;
    return {
      for (var i = 0; i < variants.length; i++)
        variants[i].title: variants[i].options[_selectedVariants[i]],
    };
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cartItem = context
          .read<CartProvider>()
          .items
          .where((i) => i.product.id == widget.product.id)
          .firstOrNull;
      if (cartItem != null && mounted) {
        setState(() {
          _quantity = cartItem.quantity;
        });
      }
    });
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favProv = context.watch<FavouritesProvider>();
    final isFav = favProv.isFavourite(widget.product.id);

    final double totalPrice = widget.product.price * _quantity;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero Image ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: AppBackButton(),
                ),
                actions: [
                  GestureDetector(
                    onTap: () => favProv.toggle(widget.product.id),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      width: 40,
                      alignment: Alignment.center,
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.share_outlined,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 18),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: Theme.of(context)
                          .extension<AppThemeExtension>()
                          ?.heroGradient,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(widget.product.image,
                            style: const TextStyle(fontSize: 110)),
                        if (widget.product.badge != null)
                          Positioned(
                            bottom: 50,
                            left: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surface
                                    .withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('✦ ${widget.product.badge}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.w600)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Content ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(widget.product.name,
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 6),
                      Text(widget.product.time,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),

                      // Description
                      Text(widget.product.description,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  height: 1.6)),
                      const SizedBox(height: 18),

                      // Tags
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: widget.product.tags.map((tag) {
                          final isGood = tag.contains('Gluten') ||
                              tag.contains('Vegan') ||
                              tag.contains('Organic');
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 5),
                            decoration: BoxDecoration(
                              color: isGood
                                  ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              tag,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isGood
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer
                                        : Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                    fontSize: 12,
                                  ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),

                      // Variant groups
                      ...List.generate(widget.product.variants.length, (gi) {
                        final group = widget.product.variants[gi];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionHeader(title: group.title),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: List.generate(
                                  group.options.length, (oi) {
                                final isActive =
                                    _selectedVariants[gi] == oi;
                                return _VariantChip(
                                  label: group.options[oi],
                                  isActive: isActive,
                                  onTap: () => setState(
                                      () => _selectedVariants[gi] = oi),
                                );
                              }),
                            ),
                            const SizedBox(height: 24),
                          ],
                        );
                      }),

                      // Special Instructions
                      Text(
                        'Special Instructions',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _instructionsCtrl,
                        maxLines: 4,
                        style: Theme.of(context).textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'E.g. No onions, sauce on the side...',
                          hintStyle:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                  ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: const EdgeInsets.all(20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.5)),
                          ),
                        ),
                      ),
                      const SizedBox(
                          height: 120), // Padding for the floating action bar
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom CTA ───────────────────────────────────────────
          ProductBottomCta(
            quantity: _quantity,
            totalPrice: totalPrice,
            onDecrement: () {
              if (_quantity > 0) {
                setState(() => _quantity--);
                final cart = context.read<CartProvider>();
                if (cart.contains(widget.product)) {
                  cart.updateById(widget.product.id, _quantity);
                }
              }
            },
            onIncrement: () {
              setState(() => _quantity++);
              final cart = context.read<CartProvider>();
              if (cart.contains(widget.product)) {
                cart.updateById(widget.product.id, _quantity);
              } else {
                cart.addProduct(widget.product,
                    quantity: _quantity,
                    selectedVariants: _variantSelections);
              }
            },
            onCheckout: () {
              if (_quantity > 0) {
                final cart = context.read<CartProvider>();
                if (!cart.contains(widget.product)) {
                  cart.addProduct(widget.product,
                      quantity: _quantity,
                      selectedVariants: _variantSelections);
                }
                context.push('/cart');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select at least 1 item')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Private Helper Widgets ───────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }
}

class _VariantChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _VariantChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? colors.primary : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? colors.primary : Theme.of(context).dividerColor,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isActive ? colors.onPrimary : colors.onSurface,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
        ),
      ),
    );
  }
}
