import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme_extensions.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'dart:math';
import 'package:wishlist_app/services/analytics/analytics_service.dart';
import 'dart:io';

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
  final bool blurPlaceholder;
  /// Optional local preview file path (e.g. freshly picked image) shown immediately
  /// while the remote (possibly newly uploaded) Cloudinary image is loading.
  /// When provided, a quick fade transition will occur once the network image
  /// finishes loading successfully.
  final String? localPreviewPath;

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
    this.blurPlaceholder = false,
    this.localPreviewPath,
  });

  @override
  State<OptimizedCloudinaryImage> createState() => _OptimizedCloudinaryImageState();
}

class _OptimizedCloudinaryImageState extends State<OptimizedCloudinaryImage> {
  late String? _currentUrl; // can switch to original on failure
  bool _triedOriginal = false;
  CloudinaryService? _cloudinary;
  String? _lowResUrl;
  DateTime? _loadStart;
  bool _reportedSuccess = false;
  bool _reportedFailure = false;
  bool _networkLoaded = false;
  ImageProvider? _localPreviewProvider;

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
  _loadStart = DateTime.now();
    try {
      _cloudinary = CloudinaryService();
      _currentUrl = _cloudinary!.optimizeExistingUrl(original, widget.transformationType);
      if (widget.blurPlaceholder) {
        _lowResUrl = _cloudinary!.optimizeLowResPlaceholderUrl(original);
      } else {
        _lowResUrl = null;
      }
    } catch (_) {
      // Cloudinary config missing -> fallback to original
  _currentUrl = original;
  _lowResUrl = null;
    }
  _networkLoaded = false;
  _setupLocalPreview();
  }

  @override
  void didUpdateWidget(covariant OptimizedCloudinaryImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalUrl != widget.originalUrl || oldWidget.transformationType != widget.transformationType) {
      _triedOriginal = false;
      _init();
    }
    if (oldWidget.localPreviewPath != widget.localPreviewPath) {
      _setupLocalPreview();
    }
  }

  void _setupLocalPreview() {
    final path = widget.localPreviewPath;
    if (path != null && path.isNotEmpty) {
      try {
        _localPreviewProvider = FileImage(File(path));
      } catch (_) {
        _localPreviewProvider = null;
      }
    } else {
      _localPreviewProvider = null;
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
      placeholder: (c, _) => _buildPlaceholder(context),
      imageBuilder: (c, imageProvider) {
        if (!_reportedSuccess && _loadStart != null) {
          _reportedSuccess = true;
          final dur = DateTime.now().difference(_loadStart!).inMilliseconds;
          Future.microtask(() => AnalyticsService().log('image_render_success', properties: {
                'url_hash': url.hashCode.toString(),
                'duration_ms': dur,
                'type': widget.transformationType.name,
                'orig_diff': (url == widget.originalUrl) ? 'original' : 'optimized',
              }));
        }
        _networkLoaded = true;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: Image(
            key: const ValueKey('networkImage'),
            image: imageProvider,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            filterQuality: FilterQuality.high,
          ),
        );
      },
      errorWidget: (c, _, err) {
        if (widget.originalUrl != null) {
          MonitoringService.logImageRenderError(widget.originalUrl!, err);
        }
        if (!_triedOriginal && url != widget.originalUrl && widget.originalUrl != null) {
          // Try original once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _currentUrl = widget.originalUrl;
                  _triedOriginal = true;
                  _loadStart = DateTime.now();
                  _reportedSuccess = false;
                });
              }
            });
        }
        if (!_reportedFailure && !_reportedSuccess) {
          _reportedFailure = true;
          final start = _loadStart;
          final dur = start == null ? null : DateTime.now().difference(start).inMilliseconds;
          Future.microtask(() => AnalyticsService().log('image_render_failure', properties: {
                'url_hash': url.hashCode.toString(),
                if (dur != null) 'duration_ms': dur,
                'type': widget.transformationType.name,
              }));
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

  Widget _buildPlaceholder(BuildContext context) {
    // If a local preview is provided, show it immediately beneath a subtle shimmer overlay
    if (_localPreviewProvider != null) {
      final preview = Image(
        image: _localPreviewProvider!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.high,
      );
      return Stack(
        fit: StackFit.passthrough,
        children: [
          preview,
          // Overlay shimmer only until network loads
          if (!_networkLoaded) Positioned.fill(child: _buildShimmer(context)),
        ],
      );
    }
    return _buildShimmer(context);
  }

  Widget _buildShimmer(BuildContext context) {
    final shimmer = Shimmer.fromColors(
      baseColor: widget.shimmerBase ?? context.semanticColors.skeletonBase,
      highlightColor: widget.shimmerHighlight ?? context.semanticColors.skeletonHighlight,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: (widget.shimmerBase ?? context.semanticColors.skeletonBase).withAlpha(160),
          borderRadius: widget.circle ? null : (widget.borderRadius ?? BorderRadius.circular(8)),
          shape: widget.circle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );

    if (widget.blurPlaceholder && _lowResUrl != null) {
      final lowRes = Image.network(
        _lowResUrl!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        filterQuality: FilterQuality.low,
      );
      return Stack(
        fit: StackFit.passthrough,
        children: [
          if (widget.circle)
            ClipOval(child: lowRes)
          else
            ClipRRect(borderRadius: widget.borderRadius ?? BorderRadius.circular(8), child: lowRes),
          Positioned.fill(child: shimmer),
        ],
      );
    }
    return shimmer;
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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

  int? _cacheDim(double? value) {
    if (value == null) return null;
    if (value.isInfinite || value.isNaN) return null;
  // Scale by device pixel ratio (capped) instead of constant 2x
  final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? MediaQuery.of(context).devicePixelRatio;
  final scale = dpr.clamp(1.5, 3.0);
  return (value * scale).round();
  }
}
