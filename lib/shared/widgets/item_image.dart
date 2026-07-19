import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Renders either an emoji/symbol or a network image for an item.
class ItemImage extends StatelessWidget {
  final String image;
  final double size;

  const ItemImage({
    super.key,
    required this.image,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = image.trim();
    if (trimmed.startsWith('http') || trimmed.contains('/') || trimmed.contains('\\')) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: trimmed,
          width: size,
          height: size,
          fit: BoxFit.cover,
          // Fade-in on first decode keeps the swap from feeling jarring
          // when an image hits disk-cache during scroll.
          fadeInDuration: const Duration(milliseconds: 120),
          errorWidget: (_, __, ___) => Center(
            child: Text(
              '🍴',
              style: TextStyle(fontSize: size * 0.75),
            ),
          ),
        ),
      );
    }
    return Text(
      trimmed.isEmpty ? '🍴' : trimmed,
      style: TextStyle(fontSize: size),
    );
  }
}
