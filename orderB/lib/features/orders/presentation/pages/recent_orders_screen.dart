import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../catalogue/presentation/providers/catalogue_provider.dart';
import '../../../catalogue/data/models/product.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/order.dart';
import '../widgets/reorder_card.dart';
import '../widgets/order_invoice_sheet.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../shared/widgets/app_back_button.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/providers/order_provider.dart';
import '../../../../core/constants.dart';

class RecentOrdersScreen extends StatefulWidget {
  const RecentOrdersScreen({super.key});

  @override
  State<RecentOrdersScreen> createState() => _RecentOrdersScreenState();
}

class _RecentOrdersScreenState extends State<RecentOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pageCtrl;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    _pageCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isAuthenticated) {
        context.read<OrderProvider>().fetchOrders().catchError((e, st) {
          debugPrint('🚨 RecentOrdersScreen: fetchOrders failed: $e\n$st');
        });
      }
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final authProv = context.watch<AuthProvider>();
    final orderProv = context.watch<OrderProvider>();

    // Authed users get their real orders straight from OrderProvider.
    // Guests have nothing here — the My Orders tile in profile already
    // gates guests through /login, but render an empty state defensively
    // in case they reach this route by some other path (deep link, etc).
    final List<Order> orders =
        authProv.isAuthenticated ? orderProv.orders : const [];
    final bool isLoadingOrders =
        authProv.isAuthenticated && orderProv.isLoading && orders.isEmpty;

    final double totalSpent = orders.fold<double>(0, (sum, o) => sum + o.total);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: AppBackButton(),
        ),
        title: const Text('Recent Orders'),
      ),
      body: isLoadingOrders
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
          ? _EmptyOrders()
          : FadeTransition(
              opacity: _pageFade,
              child: SlideTransition(
                position: _pageSlide,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  children: [
                    // ── Summary Header ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(24),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.onSurfaceVariant],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('THIS MONTH',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colors.secondary,
                                letterSpacing: 1.5,
                                fontSize: 11,
                              )),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${orders.length}',
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      color: colors.onPrimary,
                                      fontSize: 32,
                                    ),
                                  ),
                                  Text(
                                    'orders placed',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onPrimary.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.formatPrice(totalSpent),
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      color: colors.onPrimary,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Text(
                                    'total spent',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onPrimary.withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Dynamic Order cards with staggered load animations ──
                    ...List.generate(orders.length, (i) {
                      final order = orders[i];
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (i * 100).clamp(0, 500)),
                        curve: Curves.easeOut,
                        builder: (context, val, child) {
                          return Opacity(
                            opacity: val,
                            child: Transform.translate(
                              offset: Offset(0, 15 * (1 - val)),
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OrderCard(
                            order: order,
                            onTap: () => OrderInvoiceSheet.show(context, order),
                            onReorder: () async {
                              debugPrint('📋 RecentOrdersScreen reorder tapped: order ${order.id} with ${order.items.length} item(s)');
                              final cat = context.read<CatalogueProvider>();
                              if (cat.products.isEmpty && cat.productsState != CatalogueLoadState.loading) {
                                debugPrint('   → Products not loaded yet, loading first...');
                                await cat.loadAllProducts();
                                debugPrint('   → Products loaded: ${cat.products.length} product(s)');
                              }
                              if (!context.mounted) return;
                              final prods = cat.products.map(Product.fromApi).toList(growable: false);
                              debugPrint('   → Calling reorder() with ${prods.length} available product(s)');
                              context.read<CartProvider>().reorder(order, availableProducts: prods);
                              debugPrint('   → Navigating to /cart');
                              context.push('/cart');
                            },
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 80, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text('No orders yet',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Your order history will appear here once you place your first order.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.storefront_rounded, size: 18),
              label: const Text('Browse menu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                side: BorderSide(color: theme.dividerColor, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
