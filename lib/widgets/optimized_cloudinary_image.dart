import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'dart:math';

/// Unified image widget applying Cloudinary transformation + shimmer + fallback to original URL on error.
class OptimizedCloudinaryImage extends StatefulWidget {
  final String? originalUrl;
  final ImageType transformationType;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool circle;
  final Widget? fallbackIcon;
  final Duration fadeIn;
  final Duration fadeOut;
  final Color? shimmerBase;
  final Color? shimmerHighlight;

  const OptimizedCloudinaryImage({
    super.key,
    required this.originalUrl,
    required this.transformationType,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.circle = false,
    this.fallbackIcon,
    this.fadeIn = const Duration(milliseconds: 280),
    this.fadeOut = const Duration(milliseconds: 280),
    this.shimmerBase,
    this.shimmerHighlight,
  });

  @override
  State<OptimizedCloudinaryImage> createState() => _OptimizedCloudinaryImageState();
}

class _OptimizedCloudinaryImageState extends State<OptimizedCloudinaryImage> {
  late String? _currentUrl; // can switch to original on failure
  bool _triedOriginal = false;
  CloudinaryService? _cloudinary;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    final original = widget.originalUrl;
    if (original == null || original.isEmpty) {
      _currentUrl = null;
      return;
    }
    try {
      _cloudinary = CloudinaryService();
      _currentUrl = _cloudinary!.optimizeExistingUrl(original, widget.transformationType);
    } catch (_) {
      // Cloudinary config missing -> fallback to original
      _currentUrl = original;
    }
  }

  @override
  void didUpdateWidget(covariant OptimizedCloudinaryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalUrl != widget.originalUrl || oldWidget.transformationType != widget.transformationType) {
      _triedOriginal = false;
      _init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _currentUrl;
    final radius = widget.borderRadius ?? BorderRadius.circular(widget.circle ? (min(widget.width ?? 80, widget.height ?? 80) / 2) : 0);

    if (url == null || url.isEmpty) {
      return _buildFallback(context);
    }

    final image = CachedNetworkImage(
      imageUrl: url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      fadeInDuration: widget.fadeIn,
      fadeOutDuration: widget.fadeOut,
      placeholder: (c, _) => _buildShimmer(context),
      errorWidget: (c, _, __) {
        if (!_triedOriginal && url != widget.originalUrl && widget.originalUrl != null) {
          // Try original once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentUrl = widget.originalUrl;
                  _triedOriginal = true;
                });
              }
            });
        }
        return _buildFallback(context);
      },
      memCacheWidth: _cacheDim(widget.width),
      memCacheHeight: _cacheDim(widget.height),
    );

    final clipped = widget.circle
        ? ClipOval(child: image)
        : ClipRRect(borderRadius: radius, child: image);

    return clipped;
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: widget.shimmerBase ?? Colors.grey[300]!,
      highlightColor: widget.shimmerHighlight ?? Colors.grey[100]!,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: (widget.shimmerBase ?? Colors.grey[300]!).withAlpha(180),
          borderRadius: widget.circle ? null : (widget.borderRadius ?? BorderRadius.circular(8)),
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: widget.circle ? null : (widget.borderRadius ?? BorderRadius.circular(8)),
        shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      alignment: Alignment.center,
      child: widget.fallbackIcon ?? Icon(
        Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: (widget.width ?? 64) * 0.5,
      ),
    );
  }

  int? _cacheDim(double? value) => value == null ? null : (value * 2).round();
}
