import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../features/catalogue/data/models/category.dart';
import '../features/catalogue/data/models/product.dart';
import '../features/catalogue/presentation/providers/catalogue_provider.dart';
import '../features/cart/presentation/providers/cart_provider.dart';
import '../features/favourites/presentation/providers/favourites_provider.dart';
import '../features/address/presentation/providers/address_provider.dart';
import '../features/address/presentation/widgets/address_selector.dart';
import '../features/catalogue/presentation/widgets/category_pill.dart';
import '../features/catalogue/presentation/widgets/product_card.dart';
import '../features/catalogue/presentation/widgets/grid_product_card.dart';
import '../features/orders/presentation/widgets/reorder_card.dart';
import '../features/orders/data/models/placed_order.dart';
import '../features/orders/data/models/order.dart';
import '../features/orders/presentation/providers/order_provider.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../shared/widgets/ai_tip.dart';
import '../shared/widgets/section_header.dart';
import '../core/navigation/nav_provider.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  String _sortBy = 'default';
  bool _gridView = false;
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    // Trigger an initial product fetch once the widget tree is mounted.
    // No-op if products are already loaded (e.g. user backed in from a child).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cat = context.read<CatalogueProvider>();
      if (cat.products.isEmpty &&
          cat.productsState != CatalogueLoadState.loading) {
        cat.loadAllProducts().catchError((e, st) {
          debugPrint('🚨 HomeScreen: loadAllProducts failed: $e\n$st');
        });
      }
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        // "Recent Purchases" used to come from /products/recent-purchase,
        // which is server-filtered to completed orders. We now derive the
        // list from the user's full order history below, so that load is
        // no longer needed.
        final orderProv = context.read<OrderProvider>();
        if (orderProv.orders.isEmpty && !orderProv.isLoading) {
          orderProv.fetchOrders().catchError((e, st) {
            debugPrint('🚨 HomeScreen: fetchOrders failed: $e\n$st');
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _quickAdd(Product product) {
    context.read<CartProvider>().addProduct(product);
  }

  void _showAddressSheet() {
    final prov = context.read<AddressProvider>();
    AddressBottomSheet.show(context,
        selectedId: prov.selectedId,
        onSelect: (id) => prov.select(id));
  }

  List<Product> _applyFilter(List<Product> source) {
    List<Product> list = _selectedCategory == 'all'
        ? List.of(source)
        : source.where((p) => p.category == _selectedCategory).toList();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.tags.any((t) => t.toLowerCase().contains(q));
      }).toList();
    }

    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'rating':
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'popular':
        list.sort((a, b) => b.reviews.compareTo(a.reviews));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final favProv = context.watch<FavouritesProvider>();
    final addrProv = context.watch<AddressProvider>();
    final catProv = context.watch<CatalogueProvider>();
    final authProv = context.watch<AuthProvider>();
    final orderProv = context.watch<OrderProvider>();

    final allProducts =
        catProv.products.map(Product.fromApi).toList(growable: false);
    final categories =
        catProv.visibleCategories.map(Category.fromApi).toList(growable: false);

    final filtered = _applyFilter(allProducts);
    final bool showRecent = _searchQuery.isEmpty && _selectedCategory == 'all';
    final bool isLoadingInitial =
        catProv.productsState == CatalogueLoadState.loading &&
            catProv.products.isEmpty;

    // Recent orders for authenticated users — all statuses (pending +
    // completed), valid orders only, newest-first as returned by the
    // backend. One card per order using the shared OrderCard widget.
    final List<Order> recentOrders = authProv.isAuthenticated
        ? orderProv.orders
            .where((o) => o.isValid)
            .take(8)
            .toList(growable: false)
        : const [];

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: AddressSelector(
                    selectedId: addrProv.selectedId,
                    onTap: _showAddressSheet,
                    variant: AddressSelectorVariant.header,
                  ),
                ),
                const SizedBox(width: 12),
                // Notification bell
                IconButton(
                  onPressed: () => context.push('/profile/notifications'),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).dividerColor,
                    foregroundColor:
                        Theme.of(context).colorScheme.onSurfaceVariant,
                    minimumSize: const Size(44, 44),
                  ),
                  icon: const Icon(Icons.notifications_outlined, size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Search ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _SearchBar(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              onClear: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Category Pills ───────────────────────────────────────
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              children: [
                CategoryPill(
                  label: 'All',
                  icon: '✦',
                  active: _selectedCategory == 'all',
                  onTap: () {
                    setState(() => _selectedCategory = 'all');
                    if (_scrollController.hasClients) {
                      _scrollController.animateTo(0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut);
                    }
                    context.read<NavProvider>().triggerCategoryChange();
                  },
                ),
                const SizedBox(width: 10),
                ...categories.map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: CategoryPill(
                      label: c.label,
                      icon: c.icon,
                      active: _selectedCategory == c.id,
                      onTap: () {
                        setState(() => _selectedCategory = c.id);
                        if (_scrollController.hasClients) {
                          _scrollController.animateTo(0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut);
                        }
                        context.read<NavProvider>().triggerCategoryChange();
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          // ── Scrollable content ───────────────────────────────────
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
              children: [
                // ── AI Tip ───────────────────────────────────────────────
                const AiTip(),
                const SizedBox(height: 16),

                 // Recent orders preview
                 if (showRecent) ...[
                   if (authProv.isAuthenticated && recentOrders.isNotEmpty) ...[
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Recent Orders',
                             style: Theme.of(context).textTheme.headlineSmall),
                         GestureDetector(
                           onTap: () => context.push('/home/recent_orders'),
                           child: Text('View all →',
                               style: Theme.of(context)
                                   .textTheme
                                   .bodySmall
                                   ?.copyWith(
                                       color: Theme.of(context)
                                           .colorScheme
                                           .tertiary,
                                       fontWeight: FontWeight.w500,
                                       fontSize: 13)),
                         ),
                       ],
                     ),
                     const SizedBox(height: 14),
                     SizedBox(
                       height: 175,
                       child: ListView.separated(
                         scrollDirection: Axis.horizontal,
                         physics: const BouncingScrollPhysics(),
                         itemCount: recentOrders.length,
                         separatorBuilder: (_, __) =>
                             const SizedBox(width: 14),
                         itemBuilder: (_, i) {
                           final order = recentOrders[i];
                           return SizedBox(
                             width: 260,
                             child: OrderCard(
                               order: order,
                               onTap: () =>
                                   context.push('/home/recent_orders'),
                               onReorder: () {
                                 debugPrint(
                                     '🏠 RecentOrder reorder tapped: ${order.id} (${order.items.length} items)');
                                 context.read<CartProvider>().reorder(order);
                                 context.push('/cart');
                               },
                               onTrack: () => context.push(
                                 '/checkout/success/tracking',
                                 extra: PlacedOrder.fromOrder(order),
                               ),
                             ),
                           );
                         },
                       ),
                     ),
                     const SizedBox(height: 24),
                   ],
                 ],

                // Search result info
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${filtered.length} result${filtered.length != 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),

                // Section title + Sort + View toggle
                SectionHeader(
                  title: 'Fresh Today',
                  trailing: Row(
                    children: [
                      _SortButton(
                        sortBy: _sortBy,
                        onChanged: (v) => setState(() => _sortBy = v),
                      ),
                      const SizedBox(width: 6),
                      _ViewToggle(
                        isGrid: _gridView,
                        onToggle: (v) => setState(() => _gridView = v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Loading / empty state
                if (isLoadingInitial)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 64),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (filtered.isEmpty)
                  _EmptyState(
                    onClear: () => setState(() {
                      _searchQuery = '';
                      _searchCtrl.clear();
                      _sortBy = 'default';
                      _selectedCategory = 'all';
                    }),
                  )
                else if (_gridView)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return GridProductCard(
                        product: p,
                        onTap: () => context.push('/home/product', extra: p),
                        onQuickAdd: () => _quickAdd(p),
                        isFavourite: favProv.isFavourite(p.id),
                        onToggleFavourite: () => favProv.toggle(p.id),
                      );
                    },
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      return ProductCard(
                        product: p,
                        onTap: () => context.push('/home/product', extra: p),
                        onQuickAdd: () => _quickAdd(p),
                        isFavourite: favProv.isFavourite(p.id),
                        onToggleFavourite: () => favProv.toggle(p.id),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private helper widgets ────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
      decoration: InputDecoration(
        hintText: 'Search breads, pastries...',
        prefixIcon: Icon(Icons.search_rounded,
            color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: onClear,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.close_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 18),
                ),
              )
            : null,
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onChanged;

  const _SortButton({required this.sortBy, required this.onChanged});

  static const _options = [
    ('default', 'Default'),
    ('price_low', 'Price: Low → High'),
    ('price_high', 'Price: High → Low'),
    ('rating', 'Top Rated'),
    ('popular', 'Most Popular'),
  ];

  @override
  Widget build(BuildContext context) {
    final isActive = sortBy != 'default';
    return TextButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (_) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Sort by',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                ..._options.map((opt) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      onTap: () {
                        onChanged(opt.$1);
                        Navigator.pop(context);
                      },
                      title: Text(opt.$2,
                          style: Theme.of(context).textTheme.bodyLarge),
                      trailing: sortBy == opt.$1
                          ? Icon(Icons.check_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryContainer)
                          : null,
                    )),
              ],
            ),
          ),
        );
      },
      statesController:
          WidgetStatesController({if (isActive) WidgetState.selected}),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const Icon(Icons.sort_rounded, size: 20),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onToggle;

  const _ViewToggle({required this.isGrid, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: false, icon: Icon(Icons.view_list_rounded)),
        ButtonSegment(value: true, icon: Icon(Icons.grid_view_rounded)),
      ],
      selected: {isGrid},
      onSelectionChanged: (set) => onToggle(set.first),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onClear;

  const _EmptyState({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Lottie.asset(
            'assets/animations/empty_search.json',
            width: 200,
            repeat: false,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.search_off_rounded,
              size: 96,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Text('No items found',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text('Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onClear,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }
}
