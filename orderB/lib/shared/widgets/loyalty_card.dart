import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Loyalty points card widget (dark gradient card).
class LoyaltyCard extends StatefulWidget {
  final int points;
  final int nextRewardAt;
  final String nextRewardName;

  const LoyaltyCard({
    super.key,
    this.points = 340,
    this.nextRewardAt = 500,
    this.nextRewardName = 'Free Croissant',
  });

  @override
  State<LoyaltyCard> createState() => _LoyaltyCardState();
}

class _LoyaltyCardState extends State<LoyaltyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _progress = Tween<double>(
      begin: 0,
      end: widget.points / widget.nextRewardAt,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
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
    final remaining = widget.nextRewardAt - widget.points;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: theme.extension<AppThemeExtension>()?.primaryGradient,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LOYALTY POINTS',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.secondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.points} pts',
                    style: theme.textTheme.displayMedium?.copyWith(
                      color: colors.onPrimary,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              const Text('🏅', style: TextStyle(fontSize: 36)),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 6,
              color: colors.onPrimary.withValues(alpha: 0.12),
              alignment: Alignment.centerLeft,
              child: AnimatedBuilder(
                animation: _progress,
                builder: (_, __) => FractionallySizedBox(
                  widthFactor: _progress.value.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colors.secondary, colors.secondary],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$remaining pts to next reward',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.5),
                    fontSize: 12),
              ),
              Text(
                '${widget.nextRewardAt} pts',
                style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.secondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🥐', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Next: ${widget.nextRewardName}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Then 🎂 Free Slice at 750 · 👑 VIP at 1000',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onPrimary.withValues(alpha: 0.4),
                            fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
