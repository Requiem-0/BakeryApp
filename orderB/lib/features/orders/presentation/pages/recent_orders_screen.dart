import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../catalogue/data/datasources/catalogue_local_datasource.dart';
import '../widgets/reorder_card.dart';
import '../widgets/order_invoice_sheet.dart';
import '../../../cart/presentation/providers/cart_provider.dart';
import '../../../../shared/widgets/app_back_button.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants.dart';

class RecentOrdersScreen extends StatefulWidget {
  const RecentOrdersScreen({super.key});

  @override
  State<RecentOrdersScreen> createState() => _RecentOrdersScreenState();
}

class _RecentOrdersScreenState extends State<RecentOrdersScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pageCtrl;
  late final Animation<double> _pageFade;
  late final Animation<Offset> _pageSlide;
  late final List<AnimationController> _cardCtrls;

  final _orders = CatalogueLocalDatasource.recentOrders;
  late final double _totalSpent =
      _orders.fold<double>(0, (sum, o) => sum + o.total);

  @override
  void initState() {
    super.initState();

    _pageCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _pageFade = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOut));

    _cardCtrls = List.generate(
      _orders.length,
      (_) => AnimationController(
          vsync: this, duration: const Duration(milliseconds: 400)),
    );

    _pageCtrl.forward();
    for (var i = 0; i < _cardCtrls.length; i++) {
      Future.delayed(Duration(milliseconds: 150 + i * 100), () {
        if (mounted) _cardCtrls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    for (final c in _cardCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: AppBackButton(),
        ),
        title: const Text('Recent Orders'),
      ),
      body: _orders.isEmpty
          ? _EmptyOrders()
          : FadeTransition(
              opacity: _pageFade,
              child: SlideTransition(
                position: _pageSlide,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  children: [
                    // ── This Month summary ──────────────────────
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
                                    '${_orders.length}',
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                      color: colors.onPrimary,
                                      fontSize: 32,
                                    ),
                                  ),
                                  Text(
                                    'orders placed',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onPrimary
                                          .withValues(alpha: 0.5),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppConstants.formatPrice(_totalSpent),
                                    style: theme.textTheme.displayLarge
                                        ?.copyWith(
                                      color: colors.onPrimary,
                                      fontSize: 24,
                                    ),
                                  ),
                                  Text(
                                    'total spent',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.onPrimary
                                          .withValues(alpha: 0.5),
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

                    // ── Order cards ─────────────────────────────
                    ...List.generate(_orders.length, (i) {
                      final order = _orders[i];
                      final ctrl = _cardCtrls[i];
                      return FadeTransition(
                        opacity: CurvedAnimation(
                            parent: ctrl, curve: Curves.easeOut),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: ctrl, curve: Curves.easeOut)),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: OrderCard(
                              order: order,
                              onTap: () => OrderInvoiceSheet.show(context, order),
                              onReorder: () {
                                context.read<CartProvider>().reorder(order);
                                context.push('/cart');
                              },
                            ),
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
              'Your order history will appear here',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
