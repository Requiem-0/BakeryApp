import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_back_button.dart';
import '../../../../shared/widgets/service_icon.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 12),
                  Text('Payment Methods',
                      style: Theme.of(context).textTheme.headlineLarge),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                children: [
                  // Decorative until the backend exposes saved cards —
                  // checkout itself is cash-only right now, so there's
                  // nothing to manage. Swap these tiles for API-backed
                  // entries when online payment (Fonepay) lands.
                  const _PaymentCard(
                    icon: '💳',
                    label: 'Visa ending in 4289',
                    sub: 'Expires 09/27',
                    isDefault: true,
                  ),
                  const SizedBox(height: 10),
                  const _PaymentCard(
                    icon: '🍎',
                    label: 'Apple Pay',
                    sub: 'Express checkout',
                  ),
                  const SizedBox(height: 10),
                  const _PaymentCard(
                    icon: '🅿️',
                    label: 'PayPal',
                    sub: 'sophie@email.com',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      side: BorderSide(
                          color: Theme.of(context).dividerColor, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text('Add Payment Method',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final String icon;
  final String label;
  final String sub;
  final bool isDefault;

  const _PaymentCard({
    required this.icon,
    required this.label,
    required this.sub,
    this.isDefault = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: theme.dividerColor, width: 1.5),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: ServiceIcon(
          icon: icon,
          size: 48,
          iconSize: 22,
          borderRadius: 16,
        ),
        title: Row(
          children: [
            Text(label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            if (isDefault) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text('Default',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(sub,
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
        ),
        trailing: Icon(Icons.more_vert_rounded,
            color: theme.colorScheme.outline, size: 20),
      ),
    );
  }
}
