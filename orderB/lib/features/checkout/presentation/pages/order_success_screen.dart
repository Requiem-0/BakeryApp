import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../features/orders/data/models/placed_order.dart';

class OrderSuccessScreen extends StatefulWidget {
  final PlacedOrder order;

  const OrderSuccessScreen({super.key, required this.order});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));

    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _shareOrder() {
    final o = widget.order;
    final items = o.items
        .map((i) =>
            '${i.name} x${i.quantity} — ${AppConstants.formatPrice(i.price * i.quantity)}')
        .join('\n');
    final text = 'Order ${o.id}\n\n'
        '$items\n\n'
        'Total: ${AppConstants.formatPrice(o.total)}\n'
        'Pickup: ${o.addressLabel}, ${o.addressFull}\n'
        'Est. ready by ${o.eta}';
    SharePlus.instance.share(ShareParams(text: text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final o = widget.order;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // ─── Share button ──────────────────────────────
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _shareOrder,
                  icon: Icon(Icons.share_outlined,
                      color: colors.onSurfaceVariant, size: 22),
                ),
              ),
              const Spacer(flex: 2),

              // ─── Animated checkmark ─────────────────────────
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [colors.primary, colors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.check_rounded,
                      color: colors.onPrimary, size: 52),
                ),
              ),
              const SizedBox(height: 28),

              // ─── Title & subtitle ───────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text('Order Placed!',
                        style: theme.textTheme.displayMedium),
                    const SizedBox(height: 8),
                    Text(
                      '${o.id}  •  Est. ready by ${o.eta}',
                      style:
                          theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ─── Order details card ────────────────────────
              FadeTransition(
                opacity: _fadeAnim,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Item list
                        ...o.items.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text(item.image,
                                      style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(item.name,
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                    fontWeight:
                                                        FontWeight.w500),
                                            overflow:
                                                TextOverflow.ellipsis),
                                        Text('x${item.quantity}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 12)),
                                        if (item.selectedVariants.isNotEmpty)
                                          Text(
                                            item.selectedVariants.entries
                                                .map((e) => '${e.key}: ${e.value}')
                                                .join(' · '),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 10),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    AppConstants.formatPrice(
                                        item.price * item.quantity),
                                    style: theme.extension<AppThemeExtension>()!
                                        .receiptStyle,
                                  ),
                                ],
                              ),
                            )),
                        Divider(height: 20, color: theme.dividerColor),
                        // Total
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(AppConstants.formatPrice(o.total),
                                style: theme.textTheme.headlineSmall),
                          ],
                        ),
                        Divider(height: 20, color: theme.dividerColor),
                        // Delivery info
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: colors.error, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(o.addressLabel,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.w600)),
                                  Text(o.addressFull,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // ─── CTAs ───────────────────────────────────────
              PrimaryButton(
                label: 'Track My Order',
                onTap: () => context.push('/cart/checkout/success/tracking',
                    extra: o),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  alignment: Alignment.center,
                  child: Text('Back to Home',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
