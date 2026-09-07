import 'package:flutter/material.dart';

import '../../core/brandkit/app_decorations.dart';

/// A pulsing placeholder box. Drop-in for anywhere we'd otherwise render
/// a [CircularProgressIndicator] while waiting on data — makes the load
/// feel faster because the eye locks onto the shape it's about to see.
///
/// Pulses opacity on the theme's `onSurfaceVariant` colour so it reads
/// as a ghost of real content in both light and dark modes. No shimmer
/// package — one AnimationController per box is cheap enough for the
/// 8-16 boxes a typical screen renders while loading.
class Skeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(AppDecorations.radiusXS)),
  });

  /// Convenience for a fully-round pill (avatars, dot indicators).
  const Skeleton.circle({super.key, required double size})
      : width = size,
        height = size,
        borderRadius = const BorderRadius.all(Radius.circular(999));

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    // 0.35 → 0.7 keeps the box visible without ever looking solid; the
    // reverse-repeat gives a natural in/out breathing rhythm.
    _pulse = Tween(begin: 0.35, end: 0.7)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurfaceVariant;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withValues(alpha: _pulse.value * 0.25),
          borderRadius: widget.borderRadius,
        ),
      ),
    );
  }
}

/// Ghost of a [ProductCard] (list variant). Used by home when products
/// are loading — matches the real card's rough height + layout so the
/// list doesn't jump when data lands.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: const Row(
        children: [
          Skeleton(
            width: 90,
            height: 90,
            borderRadius:
                BorderRadius.all(Radius.circular(AppDecorations.radiusM)),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Skeleton(width: 140, height: 14),
                SizedBox(height: 8),
                Skeleton(width: 90, height: 10),
                SizedBox(height: 20),
                Skeleton(width: 70, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghost of a [GridProductCard]. Same story as [ProductCardSkeleton]
/// but shaped for the 2-column grid layout.
class GridProductCardSkeleton extends StatelessWidget {
  const GridProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.zero,
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(width: 110, height: 12),
                SizedBox(height: 6),
                Skeleton(width: 70, height: 10),
                SizedBox(height: 12),
                Skeleton(width: 60, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen skeleton grid — six cards in the 2-column layout. Sized
/// to sit inside a non-scrolling parent (shrinkWrap-style usage is fine
/// because it's a fixed count).
class ProductGridSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: itemCount,
      itemBuilder: (_, __) => const GridProductCardSkeleton(),
    );
  }
}

/// Full-screen skeleton list — five rows matching the [ProductCard] shape.
class ProductListSkeleton extends StatelessWidget {
  final int itemCount;

  const ProductListSkeleton({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => const ProductCardSkeleton(),
    );
  }
}

/// Ghost of an [OrderCard] used on the recent-orders screen. Same
/// primitives as the product skeletons, just laid out for the invoice
/// card shape.
class OrderCardSkeleton extends StatelessWidget {
  const OrderCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(AppDecorations.radiusCard),
        border: Border.all(color: theme.dividerColor),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeleton(width: 100, height: 14),
              Skeleton(width: 60, height: 20),
            ],
          ),
          SizedBox(height: 12),
          Skeleton(width: 200, height: 10),
          SizedBox(height: 8),
          Skeleton(width: 150, height: 10),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeleton(width: 80, height: 12),
              Skeleton(width: 90, height: 16),
            ],
          ),
        ],
      ),
    );
  }
}
