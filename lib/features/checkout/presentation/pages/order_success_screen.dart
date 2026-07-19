import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/item_image.dart';
import '../../../../core/brandkit/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../features/orders/data/models/placed_order.dart';
import '../../../../core/utils/responsive.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final o = widget.order;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
          child: Column(
            children: [
              const Spacer(flex: 2),


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
                                  ItemImage(image: item.image, size: 20),
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
                                        // Variant + addons subtitle —
                                        // single " · "-joined string so
                                        // every combination renders the
                                        // same way as the checkout and
                                        // invoice-sheet receipts. Falls
                                        // back to variantLabel when the
                                        // structured map is empty
                                        // (quick-add items).
                                        Builder(builder: (_) {
                                          final variantText = item
                                                  .selectedVariants.isNotEmpty
                                              ? item.selectedVariants.entries
                                                  .map((e) =>
                                                      '${e.key}: ${e.value}')
                                                  .join(' · ')
                                              : (item.variantLabel ?? '');
                                          final parts = <String>[
                                            if (variantText.isNotEmpty)
                                              variantText,
                                            ...item.addons,
                                          ];
                                          if (parts.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          return Text(
                                            parts.join(' · '),
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 10),
                                          );
                                        }),
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
                        // Total — line items above are already
                        // post-discount (item.price = unitPrice +
                        // addonPerUnit), so they sum to o.total.
                        // Clean bill format — no separate discount
                        // breakdown below.
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


              PrimaryButton(
                label: 'View My Orders',
                onTap: () => context.go('/home/recent_orders'),
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
