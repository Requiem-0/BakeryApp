import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../../../../features/catalogue/data/models/product.dart';
import '../../../../features/catalogue/data/datasources/catalogue_local_datasource.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/favourites/presentation/providers/favourites_provider.dart';
import '../../../../features/address/presentation/providers/address_provider.dart';
import '../../../../features/address/presentation/widgets/address_selector.dart';
import '../../../../features/catalogue/presentation/widgets/category_pill.dart';
import '../../../../features/catalogue/presentation/widgets/product_card.dart';
import '../../../../features/catalogue/presentation/widgets/grid_product_card.dart';
import '../../../../features/orders/presentation/widgets/reorder_card.dart';
import '../../../../shared/widgets/ai_tip.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../core/navigation/nav_provider.dart';
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

  List<Product> get _filtered {
    List<Product> list = _selectedCategory == 'all'
        ? List.of(CatalogueLocalDatasource.products)
        : CatalogueLocalDatasource.products
            .where((p) => p.category == _selectedCategory)
            .toList();

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
    final filtered = _filtered;
    final bool showRecent = _searchQuery.isEmpty && _selectedCategory == 'all';

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
                ...CatalogueLocalDatasource.categories.map((c) {
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
          const SizedBox(height: 16),

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
                                    color:
                                        Theme.of(context).colorScheme.tertiary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: CatalogueLocalDatasource.recentOrders.length.clamp(0, 3),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => context.push('/home/recent_orders'),
                        child: SizedBox(
                          width: 200,
                          child: OrderCard(
                            order: CatalogueLocalDatasource.recentOrders[i],
                            featured: i == 0,
                            onReorder: () {
                              context
                                  .read<CartProvider>()
                                  .reorder(CatalogueLocalDatasource.recentOrders[i]);
                              context.push('/cart');
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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

                // Empty state
                if (filtered.isEmpty)
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
            ? IconButton(
                onPressed: onClear,
                icon: Icon(Icons.close_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 16),
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
        children: [
          Flexible(
            child: Lottie.asset(
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
