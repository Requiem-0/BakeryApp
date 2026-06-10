import 'package:flutter/material.dart';
import '../../data/models/order.dart';
import '../../../../core/constants.dart';

/// Compact order history card widget.
///
/// Renders in two visual states:
/// - default: light card surface, dark text
/// - featured: primary-colored dark background, light text
///
/// `featured` is forced by the caller (e.g. mark the first card in a row
/// as the visual anchor) OR by mouse hover on web/desktop — whichever
/// triggers it wins. On touch platforms hover never fires, so the look
/// stays static.
class OrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onReorder;
  final VoidCallback? onTap;
  final bool featured;

  const OrderCard({
    super.key,
    required this.order,
    this.onReorder,
    this.onTap,
    this.featured = false,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final featured = widget.featured || _hovered;
    final fg = featured ? colors.onPrimary : null;
    final fgMuted = featured
        ? colors.onPrimary.withValues(alpha: 0.7)
        : theme.textTheme.bodySmall?.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      // Slightly heavier top, lighter bottom — the previous symmetric
      // padding left an awkward gap below the price row.
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
      decoration: BoxDecoration(
        color: featured ? colors.primary : theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: featured ? null : Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: ID, date, status badge
          Row(
            children: [
              Text(
                order.id,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg ?? colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '· ${order.date.isEmpty ? '' : order.date.split(',').first}',
                  style: theme.textTheme.bodySmall?.copyWith(color: fgMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _StatusBadge(status: order.status, featured: featured),
            ],
          ),
          const SizedBox(height: 10),
          // Items
          ...order.items.take(3).map((item) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.name} × ${item.qty}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: featured
                          ? colors.onPrimary.withValues(alpha: 0.9)
                          : theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                    ),
                  ),
                  if (item.selectedVariants.isNotEmpty)
                    Text(
                      item.selectedVariants.entries
                          .map((e) => '${e.key}: ${e.value}')
                          .join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: featured
                            ? colors.onPrimary.withValues(alpha: 0.5)
                            : colors.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                ],
              )),
          if (order.items.length > 3)
            Text(
              '+${order.items.length - 3} more',
              style: theme.textTheme.bodySmall?.copyWith(
                color: featured
                    ? colors.onPrimary.withValues(alpha: 0.6)
                    : colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 10),
          // Price & reorder
          Row(
            children: [
              Text(
                AppConstants.formatPrice(order.total),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: fg ?? colors.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.onReorder != null) ...[
                const Spacer(),
                TextButton(
                    onPressed: widget.onReorder,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Reorder',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: fg ?? colors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: (fg ?? colors.primary)
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ],
      ),
      ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final bool featured;

  const _StatusBadge({required this.status, required this.featured});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final Color bg;
    final Color fg;
    if (featured) {
      bg = colors.onPrimary.withValues(alpha: 0.15);
      fg = colors.onPrimary;
    } else {
      switch (status) {
        case 'Delivered':
        case 'Picked Up':
          bg = colors.primary.withValues(alpha: 0.1);
          fg = colors.primary;
        case 'Cancelled':
          bg = colors.error.withValues(alpha: 0.1);
          fg = colors.error;
        default:
          bg = colors.secondary.withValues(alpha: 0.15);
          fg = colors.secondary;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }
}
