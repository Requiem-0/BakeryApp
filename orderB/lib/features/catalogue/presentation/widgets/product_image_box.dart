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

    // The image is wrapped in SizedBox.expand so it fills whatever bounds
    // the Container ends up with — this avoids passing `double.infinity`
    // to the underlying RenderImage, which would trip a
    // "size must be finite" assertion.
    final imageChild = hasUrl
        ? SizedBox.expand(
            child: CachedNetworkImage(
              imageUrl: imageUrl!,
              fit: BoxFit.cover,
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
