import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/brandkit/app_decorations.dart';

/// Renders the product image area used by [ProductCard], [GridProductCard],
/// and the [ProductDetailScreen] hero.
///
/// Tries to load the network image at [imageUrl]; if the URL is null, fails
/// to load, or is still loading, shows [emojiFallback] instead. Container
/// dimensions and decoration stay the same in either case so the layout
/// never shifts.
class ProductImageBox extends StatelessWidget {
  final String? imageUrl;
  final String emojiFallback;
  final double width;
  final double height;
  final double emojiFontSize;

  const ProductImageBox({
    super.key,
    required this.imageUrl,
    required this.emojiFallback,
    required this.emojiFontSize,
    this.width = 90,
    this.height = 90,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Text(
      emojiFallback,
      style: TextStyle(fontSize: emojiFontSize),
    );

    final hasUrl = imageUrl != null && imageUrl!.isNotEmpty;

    // Cap the decode size at ~3x the render dimensions. Product photos
    // arrive at 1200-1800px from the CDN but the card only shows
    // them at 90-200px, so decoding at source resolution burns
    // memory and misses the "bitmap downsampling" recommendation
    // in Play Console. `double.infinity` (rare — only when the parent
    // hasn't laid us out yet) falls back to null so the image loads
    // at its natural size instead of a bogus dimension.
    int? capDecode(double dim) => dim.isFinite ? (dim * 3).round() : null;
    final imageChild = hasUrl
        ? SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
              memCacheWidth: capDecode(width),
              memCacheHeight: capDecode(height),
              fadeInDuration: const Duration(milliseconds: 120),
              placeholder: (_, __) => Center(child: fallback),
              errorWidget: (_, __, ___) => Center(child: fallback),
            ),
          )
        : Center(child: fallback);

    return Container(
      width: width,
      height: height,
      decoration: AppDecorations.productImage,
      clipBehavior: Clip.hardEdge,
      child: imageChild,
    );
  }
}
