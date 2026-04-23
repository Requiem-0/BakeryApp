import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/cart/presentation/providers/cart_provider.dart';
import '../../../../features/address/presentation/providers/address_provider.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../features/cart/presentation/widgets/empty_cart_view.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants.dart';
import '../../../../features/address/presentation/widgets/address_selector.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../features/orders/data/models/placed_order.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPayment = 0;

  static const _paymentMethods = [
    (icon: '💵', label: 'Cash on Delivery', sub: 'Pay when your order arrives'),
    (icon: '💳', label: '•••• 4289', sub: 'Visa ending in 4289'),
    (icon: '🍎', label: 'Apple Pay', sub: 'Express checkout'),
  ];

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
                          title: _paymentMethods[_selectedPayment].label,
                          subtitle: _paymentMethods[_selectedPayment].sub,
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (_) => _PaymentBottomSheet(
                                methods: _paymentMethods,
                                selectedIndex: _selectedPayment,
                                onSelect: (i) {
                                  setState(() => _selectedPayment = i);
                                },
                              ),
                            );
                          },
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
                      label:
                          'Place Order — ${AppConstants.formatPrice(cart.total)}',
                      onTap: () {
                        final eta = DateFormat('h:mm a').format(
                            DateTime.now()
                                .add(const Duration(minutes: 25)));
                        final order = PlacedOrder(
                          id: '#OD-${DateTime.now().millisecondsSinceEpoch % 10000}',
                          eta: eta,
                          items: cart.items
                              .map((i) => PlacedOrderItem(
                                    name: i.product.name,
                                    image: i.product.image,
                                    quantity: i.quantity,
                                    price: i.product.price,
                                    selectedVariants: i.selectedVariants,
                                  ))
                              .toList(),
                          total: cart.total,
                          addressLabel: addr.label,
                          addressFull: addr.address,
                        );
                        cart.clear();
                        context.go('/cart/checkout/success', extra: order);
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

class _PaymentBottomSheet extends StatelessWidget {
  final List<({String icon, String label, String sub})> methods;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _PaymentBottomSheet({
    required this.methods,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Select Payment Method',
              style: theme.textTheme.headlineLarge?.copyWith(fontSize: 18)),
          const SizedBox(height: 16),
          ...methods.asMap().entries.map((e) {
            final i = e.key;
            final m = e.value;
            final isSelected = i == selectedIndex;
            return GestureDetector(
              onTap: () {
                onSelect(i);
                Navigator.pop(context);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.dividerColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? colors.primary : theme.dividerColor,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colors.primary.withValues(alpha: 0.1)
                            : theme.dividerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(m.icon,
                          style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.label,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          Text(m.sub,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_rounded,
                          color: colors.primary, size: 20),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
