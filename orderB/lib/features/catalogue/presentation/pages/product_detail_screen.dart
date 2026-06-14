import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants.dart';
import '../../data/models/product.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../favourites/presentation/providers/favourites_provider.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../cart/presentation/widgets/product_bottom_cta.dart';
import '../providers/catalogue_provider.dart';
import '../widgets/grid_product_card.dart';

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

  /// Currently-picked [VariantItem._id]. Null only before initState lands
  /// the default selection or when the product has no variants at all.
  /// We track by ID (not list index) so the picker degrades gracefully
  /// if variantItems are reordered between fetches.
  String? _selectedVariantItemId;

  /// Resolves the user's pick to a concrete [VariantItem]. Defaults to
  /// the first available variantItem until the user makes a choice — so
  /// the live price line never reads as 0 on first paint.
  VariantItem? get _selectedVariantItem {
    final items = widget.product.variantItems;
    if (items.isEmpty) return null;
    if (_selectedVariantItemId != null) {
      for (final v in items) {
        if (v.id == _selectedVariantItemId) return v;
      }
    }
    return items.first;
  }

  /// Legacy field for the cart's [CartItem.selectedVariants] payload —
  /// derived from whichever variantItem is currently picked, so the
  /// option-title labels reach the cart unchanged.
  Map<String, String> get _variantSelections {
    final picked = _selectedVariantItem;
    final groups = widget.product.variants;
    if (picked == null || groups.isEmpty) return const {};
    return {
      for (var i = 0; i < groups.length && i < picked.optionValues.length; i++)
        groups[i].title: picked.optionValues[i],
    };
  }

  /// Effective per-unit price: the chosen variant's price if any,
  /// otherwise the product's base price.
  double get _effectivePrice =>
      _selectedVariantItem?.price ?? widget.product.price;

  /// Per-unit addon total — sum of (addon price × selected qty) across
  /// every addon the user has toggled on.
  double get _selectedAddonsTotal {
    if (_selectedAddons.isEmpty) return 0;
    double sum = 0;
    for (final entry in _selectedAddons.entries) {
      final addon = widget.product.addons.firstWhere(
        (a) => a.id == entry.key,
        orElse: () =>
            const ProductAddon(id: '', name: '', price: 0),
      );
      sum += addon.price * entry.value;
    }
    return sum;
  }

  /// Map of addon `_id` → selected quantity. Empty means none. The cart
  /// layer expects exactly this shape on `addProduct`.
  final Map<String, int> _selectedAddons = {};

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favProv = context.watch<FavouritesProvider>();
    final isFav = favProv.isFavourite(widget.product.id);

    final double totalPrice =
        (_effectivePrice + _selectedAddonsTotal) * _quantity;

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
                      margin: const EdgeInsets.only(
                          left: 8, right: 16, top: 8, bottom: 8),
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
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroImage(product: widget.product),
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

                      // Subtitle (description first-clause or business name).
                      // Skip the slot entirely when empty so the chips
                      // don't float in a void of whitespace.
                      if (widget.product.time.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(widget.product.time,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],

                      // Live unit price hint — shows what the customer
                      // will pay per unit at their current variant +
                      // addon selection. Always visible so the picker
                      // gives immediate price feedback, not just when
                      // they tap "+".
                      if ((_effectivePrice + _selectedAddonsTotal) > 0) ...[
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.formatPrice(
                              _effectivePrice + _selectedAddonsTotal),
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],

                      // Description — same story as the subtitle slot.
                      if (widget.product.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 16),
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
                      ],

                      // Tags
                      if (widget.product.tags.isNotEmpty) ...[
                        const SizedBox(height: 18),
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
                      ],
                      const SizedBox(height: 24),

                      // Variants — vertical list of selectable rows, each
                      // showing the variant's label and resolved price on
                      // the right. Matches the reference UX: customer can
                      // compare prices at a glance instead of tapping
                      // chips one at a time. Multi-axis variants flatten
                      // into one list ("Chicken · steam"); single-axis
                      // shows the label as-is. Hidden entirely for plain
                      // products with no variantItems.
                      if (widget.product.variantItems.isNotEmpty) ...[
                        const _SectionHeader(title: 'Variants'),
                        const SizedBox(height: 12),
                        ...widget.product.variantItems.map((v) {
                          final isSelected =
                              v.id == _selectedVariantItem?.id;
                          return _VariantRow(
                            label: v.label,
                            price: v.price,
                            isSelected: isSelected,
                            onTap: () => setState(() {
                              _selectedVariantItemId = v.id;
                            }),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // Addons — optional add-ons per the product's
                      // `addons[]` array (e.g. Egg, Cheese). Each row has
                      // a checkbox-style toggle and a quantity stepper.
                      if (widget.product.addons.isNotEmpty) ...[
                        const _SectionHeader(title: 'Add-ons'),
                        const SizedBox(height: 12),
                        ...widget.product.addons.map((addon) {
                          final qty = _selectedAddons[addon.id] ?? 0;
                          return _AddonRow(
                            addon: addon,
                            quantity: qty,
                            onChanged: (next) {
                              setState(() {
                                if (next <= 0) {
                                  _selectedAddons.remove(addon.id);
                                } else {
                                  _selectedAddons[addon.id] = next;
                                }
                              });
                            },
                          );
                        }),
                        const SizedBox(height: 24),
                      ],

                      // "You may also like" — same category, current
                      // product excluded. Doubles as engagement bait
                      // AND fills the empty middle for plain products
                      // that have no variants/addons/description so
                      // the screen doesn't look like a void.
                      _RelatedProducts(current: widget.product),

                      // Padding so the floating CTA never sits on top
                      // of the last card.
                      const SizedBox(height: 120),
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
                    variant: _selectedVariantItem,
                    addons: Map.unmodifiable(_selectedAddons),
                    selectedVariants: _variantSelections);
              }
            },
            onCheckout: () {
              if (_quantity > 0) {
                final cart = context.read<CartProvider>();
                if (!cart.contains(widget.product)) {
                  cart.addProduct(widget.product,
                      quantity: _quantity,
                      variant: _selectedVariantItem,
                      addons: Map.unmodifiable(_selectedAddons),
                      selectedVariants: _variantSelections);
                }
                context.push('/cart');
              } else {
                AppToast.error(context, 'Please select at least 1 item');
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Private Helper Widgets ───────────────────────────────────────

/// Full-bleed hero. Image stretches edge-to-edge with `BoxFit.cover`,
/// emoji renders large + centered on a neutral surface when no URL is
/// available, and the badge overlays the bottom-left corner.
class _HeroImage extends StatelessWidget {
  final Product product;

  const _HeroImage({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUrl = product.imageUrl != null && product.imageUrl!.isNotEmpty;

    final fallback = Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Text(product.image, style: const TextStyle(fontSize: 110)),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasUrl)
          CachedNetworkImage(
            imageUrl: product.imageUrl!,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 120),
            placeholder: (_, __) => fallback,
            errorWidget: (_, __, ___) => fallback,
          )
        else
          fallback,
        if (product.badge != null)
          Positioned(
            bottom: 16,
            left: 20,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('✦ ${product.badge}',
                  style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        if (product.autoDiscount != null)
          Positioned(
            bottom: 16,
            right: 20,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.autoDiscount!.badgeLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.w800,
                  fontSize: 9,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

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

/// One row in the variant picker. Renders the variant's label on the
/// left, its resolved price on the right, and a radio-style circle in
/// the lead position that fills in when picked. Whole row is the tap
/// target — easier to hit than a small radio dot.
class _VariantRow extends StatelessWidget {
  final String label;
  final double price;
  final bool isSelected;
  final VoidCallback onTap;

  const _VariantRow({
    required this.label,
    required this.price,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? colors.primary.withValues(alpha: 0.08)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.primary : theme.dividerColor,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isSelected ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? colors.primary : theme.dividerColor,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check_rounded,
                        size: 14, color: colors.onPrimary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              Text(
                AppConstants.formatPrice(price),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One row in the addon picker. Toggles on with a tap on the row body
/// (sets qty to 1 from 0, or 0 from any positive); the −/+ controls
/// nudge the quantity once it's on. The whole row collapses visually
/// when qty == 0 so the picker stays scannable for products with many
/// add-ons.
class _AddonRow extends StatelessWidget {
  final ProductAddon addon;
  final int quantity;
  final ValueChanged<int> onChanged;

  const _AddonRow({
    required this.addon,
    required this.quantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isOn = quantity > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => onChanged(isOn ? 0 : 1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isOn
                ? colors.primary.withValues(alpha: 0.08)
                : theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isOn ? colors.primary : theme.dividerColor,
              width: 1.4,
            ),
          ),
          child: Row(
            children: [
              // Check-state indicator
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: isOn ? colors.primary : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOn ? colors.primary : theme.dividerColor,
                    width: 1.5,
                  ),
                ),
                child: isOn
                    ? Icon(Icons.check_rounded,
                        size: 14, color: colors.onPrimary)
                    : null,
              ),
              const SizedBox(width: 12),
              // Name + price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addon.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        )),
                    Text('+${AppConstants.formatPrice(addon.price)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        )),
                  ],
                ),
              ),
              // Qty stepper — only shown once the addon is toggled on
              if (isOn)
                Row(
                  children: [
                    _AddonStepperButton(
                      icon: Icons.remove_rounded,
                      onTap: () => onChanged(quantity - 1),
                    ),
                    SizedBox(
                      width: 28,
                      child: Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _AddonStepperButton(
                      icon: Icons.add_rounded,
                      onTap: () => onChanged(quantity + 1),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddonStepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _AddonStepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: colors.onPrimary),
      ),
    );
  }
}

/// Horizontal "You may also like" carousel that pulls from the same
/// category as [current]. Renders nothing when the catalogue has no
/// siblings to suggest — keeps the empty case clean.
class _RelatedProducts extends StatelessWidget {
  final Product current;

  const _RelatedProducts({required this.current});

  @override
  Widget build(BuildContext context) {
    final catProv = context.watch<CatalogueProvider>();
    final favProv = context.watch<FavouritesProvider>();
    final related = catProv.products
        .map(Product.fromApi)
        .where((p) =>
            p.id != current.id &&
            p.category.isNotEmpty &&
            p.category == current.category)
        .take(6)
        .toList();
    if (related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('You may also like',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        SizedBox(
          height: 230,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemCount: related.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) {
              final p = related[i];
              return SizedBox(
                width: 160,
                child: GridProductCard(
                  product: p,
                  onTap: () => context.push('/home/product', extra: p),
                  onQuickAdd: () =>
                      context.read<CartProvider>().addProduct(p),
                  isFavourite: favProv.isFavourite(p.id),
                  onToggleFavourite: () => favProv.toggle(p.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
