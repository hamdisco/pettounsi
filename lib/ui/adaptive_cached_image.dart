import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AdaptiveCachedImage extends StatelessWidget {
  const AdaptiveCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
    this.httpHeaders,
    this.fadeInDuration = const Duration(milliseconds: 120),
    this.minCacheDimension = 96,
    this.maxCacheDimension = 1600,
    this.fallbackWidth,
    this.fallbackHeight,
  });

  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Map<String, String>? httpHeaders;
  final Duration fadeInDuration;
  final int minCacheDimension;
  final int maxCacheDimension;
  final double? fallbackWidth;
  final double? fallbackHeight;

  @override
  Widget build(BuildContext context) {
    final clean = imageUrl.trim();
    if (clean.isEmpty) return errorWidget ?? const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final media = mediaQuery.size;
        final dpr = mediaQuery.devicePixelRatio;

        double effectiveWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : (fallbackWidth ?? media.width);
        double effectiveHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : (fallbackHeight ?? effectiveWidth);

        if (effectiveWidth <= 0) {
          effectiveWidth = fallbackWidth ?? media.width;
        }
        if (effectiveHeight <= 0) {
          effectiveHeight = fallbackHeight ?? effectiveWidth;
        }

        int clampCache(double logicalPx) {
          final raw = (logicalPx * dpr).round();
          if (raw < minCacheDimension) return minCacheDimension;
          if (raw > maxCacheDimension) return maxCacheDimension;
          return raw;
        }

        final memCacheWidth = clampCache(effectiveWidth);
        final memCacheHeight = clampCache(effectiveHeight);

        return CachedNetworkImage(
          imageUrl: clean,
          fit: fit,
          alignment: alignment,
          memCacheWidth: memCacheWidth,
          memCacheHeight: memCacheHeight,
          httpHeaders: httpHeaders,
          fadeInDuration: fadeInDuration,
          placeholder: (_, __) => placeholder ?? const SizedBox.shrink(),
          errorWidget: (_, __, ___) => errorWidget ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
