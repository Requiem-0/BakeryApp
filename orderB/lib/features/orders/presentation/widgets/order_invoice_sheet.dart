import 'package:flutter/material.dart';
import '../../../../shared/widgets/item_image.dart';
import '../../data/models/order.dart';
import '../../../../core/constants.dart';
import '../../../../core/brandkit/app_theme.dart';

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

    // Status badge palette matches the OrderCard's _StatusBadge logic
    // so the receipt and the card never disagree on what an order's
    // state looks like.
    final (Color badgeBg, Color badgeFg) = _statusColors(order.displayStatus, colors);

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
              Text(order.id, style: theme.textTheme.headlineSmall),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(order.displayStatus,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: badgeFg,
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
                // Header row — Item, Qty, Amount
                Row(
                  children: [
                    Expanded(flex: 5, child: Text('Item', style: headerStyle)),
                    SizedBox(
                        width: 36,
                        child: Text('Qty',
                            style: headerStyle,
                            textAlign: TextAlign.center)),
                    SizedBox(
                        width: 70,
                        child: Text('Amount',
                            style: headerStyle,
                            textAlign: TextAlign.right)),
                  ],
                ),
                const SizedBox(height: 8),
                // Items + variant + addons + line total
                ...order.items.map((item) {
                  final lineTotal = item.unitTotal * item.qty;
                  final subtitleParts = <String>[
                    if (item.selectedVariants.isNotEmpty)
                      item.selectedVariants.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(' · '),
                    for (final a in item.addons)
                      a.quantity > 1 ? '+${a.name} ×${a.quantity}' : '+${a.name}',
                    if (item.note.isNotEmpty) '“${item.note}”',
                  ];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ItemImage(image: item.image, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: Text(item.name,
                                  style: receiptStyle,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text('${item.qty}',
                                  style: receiptStyle,
                                  textAlign: TextAlign.center),
                            ),
                            SizedBox(
                              width: 70,
                              child: Text(
                                AppConstants.formatPrice(lineTotal),
                                style: receiptStyle,
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        if (subtitleParts.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(left: 24, top: 2),
                            child: Text(
                              subtitleParts.join(' · '),
                              style: headerStyle.copyWith(fontSize: 10),
                            ),
                          ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 12),
                // Discount row when an applyEverytime rule fired
                if (order.discount > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Discount',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.error)),
                      Text('− ${AppConstants.formatPrice(order.discount)}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.error)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                // Total
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
                if (order.paymentMethod.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Payment',
                          style: theme.textTheme.bodySmall),
                      Text(
                        '${_capitalize(order.paymentMethod)} · ${_capitalize(order.paidStatus)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _statusColors(String status, ColorScheme colors) {
    switch (status) {
      case 'Delivered':
      case 'Picked Up':
      case 'Paid':
      case 'Completed':
        return (colors.primary.withValues(alpha: 0.12), colors.primary);
      case 'Cancelled':
        return (colors.error.withValues(alpha: 0.12), colors.error);
      default:
        return (colors.secondary.withValues(alpha: 0.15), colors.secondary);
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
