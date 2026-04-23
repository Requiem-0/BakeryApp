import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Star rating display.
class StarRating extends StatelessWidget {
  final double rating;
  final int total;
  final double size;

  const StarRating({
    super.key,
    required this.rating,
    this.total = 5,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        return Icon(
          i < rating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
          color: i < rating.round() ? AppColors.accent : Theme.of(context).dividerColor,
          size: size,
        );
      }),
    );
  }
}

/// Horizontal rating bar showing per-star distribution.
class RatingBar extends StatelessWidget {
  final double rating;
  final int reviews;

  const RatingBar({
    super.key,
    required this.rating,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Simulated distribution
    const Map<int, int> dist = {5: 78, 4: 16, 3: 4, 2: 2, 1: 0};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          // Avg score
          Column(
            children: [
              Text(
                rating.toString(),
                style: theme.textTheme.displayMedium?.copyWith(fontSize: 32),
              ),
              StarRating(rating: rating, size: 12),
            ],
          ),
          const SizedBox(width: 16),
          // Per-star bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((s) {
                final pct = dist[s] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 10,
                        child: Text('$s',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 10)),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: theme.dividerColor,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.golden),
                            minHeight: 4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
