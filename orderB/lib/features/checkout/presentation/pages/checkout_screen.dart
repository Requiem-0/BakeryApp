import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/address/presentation/providers/address_provider.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/app_toast.dart';
import '../../../../features/cart/presentation/widgets/empty_cart_view.dart';
import '../../../../core/brandkit/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../features/address/presentation/widgets/address_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../features/orders/data/models/placed_order.dart';
import '../../../../features/orders/presentation/providers/order_provider.dart';
import '../../../../features/catalogue/presentation/providers/catalogue_provider.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isPlacing = false;

  // COD is the only supported payment method right now — Fonepay /
  // online payment is on the backlog. Keeping this as a list of one
  // makes adding more methods a no-op when the time comes; the bottom
  // sheet just becomes useful again.

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final addr = context.watch<AddressProvider>().selected;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final receiptStyle = theme.extension<AppThemeExtension>()?.receiptStyle ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final headerStyle =
        receiptStyle.copyWith(color: theme.textTheme.bodySmall?.color);
    final subtotal = cart.subtotal;
    final total = cart.total;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Checkout'),
      ),
      body: SafeArea(
        child: cart.items.isEmpty
            ? const EmptyCartView()
            : Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 140),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── Receipt Card ─────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: theme.dividerColor),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppConstants.appName,
                                style: receiptStyle.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colors.primary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _dashedLine(context),
                              const SizedBox(height: 12),
                              // Table header
                              Row(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: Text('Item', style: headerStyle),
                                  ),
                                  SizedBox(
                                    width: 70,
                                    child: Text('Qty',
                                        style: headerStyle,
                                        textAlign: TextAlign.center),
                                  ),
                                  SizedBox(
                                    width: 56,
                                    child: Text('Amt',
                                        style: headerStyle,
                                        textAlign: TextAlign.right),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Item rows
                              ...cart.items.asMap().entries.map((e) {
                                final idx = e.key;
                                final item = e.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                    children: [
                                      Expanded(
                                        flex: 5,
                                        child: Text(
                                          item.product.name,
                                          style: receiptStyle,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () => cart.updateQuantity(
                                                  idx, item.quantity - 1),
                                              child: Icon(
                                                  Icons.remove_circle_outline,
                                                  size: 16,
                                                  color: colors.onSurfaceVariant),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              child: Text('${item.quantity}',
                                                  style: receiptStyle),
                                            ),
                                            GestureDetector(
                                              onTap: () => cart.updateQuantity(
                                                  idx, item.quantity + 1),
                                              child: Icon(
                                                  Icons.add_circle_outline,
                                                  size: 16,
                                                  color: colors.primary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width: 56,
                                        child: Text(
                                          (item.product.price * item.quantity)
                                              .toStringAsFixed(0),
                                          style: receiptStyle,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.selectedVariants.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, top: 2),
                                      child: Text(
                                        item.selectedVariants.entries
                                            .map((e) => '${e.key}: ${e.value}')
                                            .join(' · '),
                                        style: headerStyle.copyWith(
                                            fontSize: 10),
                                      ),
                                    ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              _dashedLine(context),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Subtotal', style: headerStyle),
                                  Text(AppConstants.formatPrice(subtotal),
                                      style: receiptStyle),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Delivery', style: headerStyle),
                                  Text('Free', style: receiptStyle),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Grand Total',
                                      style: theme.textTheme.headlineMedium),
                                  Text(
                                    AppConstants.formatPrice(total),
                                    style: theme.textTheme.headlineMedium
                                        ?.copyWith(color: colors.error),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // ─── Deliver To ───────────────────────────
                        Text('Pickup From',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _SelectableCard(
                          icon: Icons.location_on_rounded,
                          iconColor: colors.error,
                          title: addr.label,
                          badge: addr.type,
                          subtitle: addr.address,
                          onTap: () {
                            final prov = context.read<AddressProvider>();
                            AddressBottomSheet.show(context,
                                selectedId: prov.selectedId,
                                onSelect: (id) => prov.select(id));
                          },
                        ),
                        const SizedBox(height: 28),

                        // ─── Payment Method ───────────────────────
                        Text('Payment Method',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        _SelectableCard(
                          icon: Icons.account_balance_wallet_rounded,
                          iconColor: colors.error,
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when your order arrives',
                          // No onTap — only one payment method right now,
                          // so the card is informational. Re-enable the
                          // bottom sheet when online payment (Fonepay)
                          // lands.
                          onTap: null,
                        ),
                      ],
                    ),
                  ),

                  // CTA Button
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: PrimaryButton(
                      label: _isPlacing
                          ? 'Placing Order...'
                          : 'Place Order — ${AppConstants.formatPrice(cart.total)}',
                      onTap: _isPlacing
                          ? null
                          : () async {
                              // Guests browse the cart + checkout summary
                              // freely, but placing an actual order needs
                              // a session. Push /login; LoginScreen pops
                              // back here on success so the user can tap
                              // again to place the order.
                              final auth = context.read<AuthProvider>();
                              if (!auth.isAuthenticated) {
                                context.push('/login');
                                return;
                              }

                              setState(() => _isPlacing = true);

                              final liveProducts = context.read<CatalogueProvider>().products;

                              final itemsJson = cart.items.map((i) {
                                String finalProductId = i.product.id;
                                
                                // If the ID is synthetic, try to find a matching live product by name
                                if (finalProductId.startsWith('reorder_')) {
                                  try {
                                    final match = liveProducts.firstWhere(
                                      (p) => p.name.toLowerCase() == i.product.name.toLowerCase(),
                                    );
                                    finalProductId = match.id;
                                    debugPrint('✅ Checkout: resolved reorder ID "${i.product.id}" → live ID "$finalProductId"');
                                  } catch (_) {
                                    debugPrint('⚠️ Checkout: could not resolve reorder ID "${i.product.id}" for "${i.product.name}" — keeping synthetic ID');
                                  }
                                }

                                // Ticket POST schema gotchas (learned by
                                // hitting the validator one field at a
                                // time):
                                //   - `preTaxPrice` → "not allowed"
                                //   - `variantItem`  → "not allowed"
                                //     (the cart endpoint accepts it,
                                //     ticket endpoint doesn't)
                                //   - `variant`      → accepted but
                                //     appears to be silently ignored
                                //     server-side; for variant-only
                                //     products (Brownie has base
                                //     price=0, real prices in
                                //     variantItems[]) the server can't
                                //     reconcile our unitPrice and zeros
                                //     it out anyway. Until the backend
                                //     adds variant-by-id support, we
                                //     send the label as a best-effort
                                //     audit trail and the order parser
                                //     enriches Rs 0 lines from the
                                //     catalogue cache on read.
                                // Ticket POST addon shape: object with
                                // the ObjectId under `_id` (NOT under
                                // `addon` — that gave Mongoose a
                                // "Cast to ObjectId failed at path _id"
                                // error). Backend uses Joi for input
                                // validation and Mongoose for the DB
                                // layer; Joi expects each entry to be
                                // an object, Mongoose maps the object
                                // into an Addon doc keyed off `_id`.
                                return {
                                  'product': finalProductId,
                                  'quantity': i.quantity,
                                  // Try the variant's `_id` under the
                                  // `variant` key now. We learned:
                                  //   • `variantItem` → rejected
                                  //   • `variant` as label → silently
                                  //     ignored before, now hits
                                  //     "Variant unavailable" once
                                  //     addons force a real lookup.
                                  // Best remaining guess: the field
                                  // wants the ObjectId, not the label.
                                  if (i.variantItemId != null)
                                    'variant': i.variantItemId,
                                  'unitPrice': i.unitPrice,
                                  'addons': i.addons
                                      .map((a) => {
                                            '_id': a.addonId,
                                            'quantity': a.quantity,
                                          })
                                      .toList(),
                                  'note': '',
                                  'discounts': const [],
                                };
                              }).toList();

                              // COD-only flow — the repo defaults
                              // [paymentMethod] to 'cod' and [paidStatus]
                              // to 'pending', so we just omit them here.
                              // When Fonepay lands, pass the actual
                              // selection through.
                              final orderProvider =
                                  context.read<OrderProvider>();
                              final success =
                                  await orderProvider.placeLiveOrder(
                                businessId: AppConstants.bakeryBusinessId,
                                items: itemsJson,
                                ticketName: 'App Order',
                                deliveryLocation: addr.address,
                              );

                              if (!mounted) return;
                              setState(() => _isPlacing = false);

                              if (success) {
                                final eta = DateFormat('h:mm a').format(
                                    DateTime.now()
                                        .add(const Duration(minutes: 25)));
                                // Prefer the server-assigned ticket _id;
                                // display the last 4 chars uppercased so
                                // the customer sees a clean "#OD-XXXX"
                                // reference instead of a 24-char hex.
                                final serverId = orderProvider.lastPlacedOrderId;
                                final displayId = (serverId != null &&
                                        serverId.length >= 4)
                                    ? '#OD-${serverId.substring(serverId.length - 4).toUpperCase()}'
                                    : '#OD-${DateTime.now().millisecondsSinceEpoch % 10000}';
                                final order = PlacedOrder(
                                  id: displayId,
                                  eta: eta,
                                  items: cart.items.map((i) {
                                    // Per-unit price the customer
                                    // actually paid: the chosen
                                    // variant's price plus per-unit
                                    // addon totals. Falling back to
                                    // i.product.price here would
                                    // show the cheapest-variant
                                    // teaser (e.g. Simmi Rs 20)
                                    // instead of what they were
                                    // charged (e.g. Medium + Egg +
                                    // Cheese = Rs 200).
                                    final addonPerUnit = i.addons.fold<double>(
                                      0,
                                      (s, a) => s + a.unitPrice * a.quantity,
                                    );
                                    return PlacedOrderItem(
                                      name: i.product.name,
                                      image: i.product.imageUrl ?? i.product.image,
                                      quantity: i.quantity,
                                      price: i.unitPrice + addonPerUnit,
                                      selectedVariants: i.selectedVariants,
                                    );
                                  }).toList(),
                                  total: cart.total,
                                  addressLabel: addr.label,
                                  addressFull: addr.address,
                                );
                                cart.clear();
                                context.go('/checkout/success', extra: order);
                              } else {
                                AppToast.error(
                                  context,
                                  orderProvider.errorMessage ??
                                      'Failed to place order.',
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _dashedLine(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 5.0;
        const dashSpace = 3.0;
        final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(count, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(color: Theme.of(context).dividerColor),
              ),
            );
          }),
        );
      },
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? badge;
  final String subtitle;
  final VoidCallback? onTap;

  const _SelectableCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.badge,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.error, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: theme.textTheme.bodySmall?.color, size: 24),
          ],
        ),
      ),
    );
  }
}

// _PaymentBottomSheet removed — only one payment method (COD) is
// supported right now, so there's nothing to switch between. Re-add when
// online payment lands.
