import 'package:flutter/material.dart';
import '../../../../shared/widgets/app_back_button.dart';
import '../../../../core/constants.dart';
import '../../data/models/placed_order.dart';

class OrderTrackingScreen extends StatelessWidget {
  final PlacedOrder order;

  const OrderTrackingScreen({super.key, required this.order});

  static const _steps = [
    (icon: '✅', label: 'Order Confirmed', desc: 'We have received your order'),
    (icon: '👩‍🍳', label: 'Preparing', desc: 'Our team is working on it'),
    (icon: '📦', label: 'Ready', desc: 'Your order is ready'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: const Text('Track Order'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            // Order ID & ETA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.id,
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text('Est. ready by ${order.eta}',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('In Progress',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress steps
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Progress',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    ...List.generate(_steps.length, (i) {
                      final s = _steps[i];
                      final isActive = i == 0;
                      final isLast = i == _steps.length - 1;
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Timeline column
                          Column(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? colors.primaryContainer
                                      : theme.dividerColor
                                          .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                alignment: Alignment.center,
                                child: Text(s.icon,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                              if (!isLast)
                                Container(
                                  width: 2,
                                  height: 30,
                                  color: isActive
                                      ? colors.primary
                                      : theme.dividerColor,
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Text
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(s.label,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: isActive
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isActive
                                                ? colors.onSurface
                                                : colors.onSurfaceVariant,
                                          )),
                                  Text(s.desc,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(fontSize: 12)),
                                  SizedBox(height: isLast ? 0 : 16),
                                ],
                              ),
                            ),
                          ),
                          if (isActive)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: colors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Items summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Items',
                        style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 14),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Text(item.image,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${item.name} × ${item.quantity}',
                                        style: theme.textTheme.bodyMedium),
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
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                          fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )),
                    Divider(height: 20, color: theme.dividerColor),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text(AppConstants.formatPrice(order.total),
                            style: theme.textTheme.headlineSmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Pickup location
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: colors.error, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.addressLabel,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                          Text(order.addressFull,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
