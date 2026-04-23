import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../../../core/constants.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet showing a receipt-style invoice for a past order.
class OrderInvoiceSheet extends StatelessWidget {
  final Order order;

  const OrderInvoiceSheet({super.key, required this.order});

  static void show(BuildContext context, Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => OrderInvoiceSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final receiptStyle = theme.extension<AppThemeExtension>()?.receiptStyle ??
        theme.textTheme.bodyMedium ??
        const TextStyle();
    final headerStyle =
        receiptStyle.copyWith(color: theme.textTheme.bodySmall?.color);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(order.id,
                  style: theme.textTheme.headlineSmall),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(order.status,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(order.date, style: theme.textTheme.bodySmall),
          ),
          const SizedBox(height: 20),

          // Receipt table
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              children: [
                // Header row
                Row(
                  children: [
                    Expanded(
                        flex: 5,
                        child: Text('Item', style: headerStyle)),
                    SizedBox(
                        width: 40,
                        child: Text('Qty',
                            style: headerStyle,
                            textAlign: TextAlign.center)),
                  ],
                ),
                const SizedBox(height: 8),
                // Items
                ...order.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(item.image,
                                  style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 5,
                                child: Text(item.name,
                                    style: receiptStyle,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text('${item.qty}',
                                    style: receiptStyle,
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          ),
                          if (item.selectedVariants.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 24, top: 2),
                              child: Text(
                                item.selectedVariants.entries
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join(' · '),
                                style: headerStyle.copyWith(fontSize: 10),
                              ),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 12),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(AppConstants.formatPrice(order.total),
                        style: theme.textTheme.headlineSmall),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
