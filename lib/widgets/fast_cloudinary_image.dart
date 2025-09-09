import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mywishstash/services/cloudinary_service.dart' as cloudinary_service;
import 'package:mywishstash/generated/l10n/app_localizations.dart';
import 'package:mywishstash/utils/performance_utils.dart';
import '../theme_extensions.dart';

/// Versão otimizada do OptimizedCloudinaryImage com foco em performance
class FastCloudinaryImage extends StatelessWidget {
  final String? originalUrl;
  final cloudinary_service.ImageType transformationType;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final bool circle;
  final Widget? fallbackIcon;
  final Duration fadeIn;
  final Duration fadeOut;
  
  /// Constructor otimizado com valores padrão para performance
  const FastCloudinaryImage({
    super.key,
    required this.originalUrl,
    required this.transformationType,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.circle = false,
    this.fallbackIcon,
    this.fadeIn = PerformanceUtils.fastAnimation,
    this.fadeOut = PerformanceUtils.fastAnimation,
  });

  @override
  Widget build(BuildContext context) {
    // Early return para URLs inválidas
    if (originalUrl == null || originalUrl!.isEmpty) {
      return _buildFallback(context);
    }

    // Memoização da URL transformada
    final transformedUrl = _getTransformedUrl();
    
    return _buildImageWidget(context, transformedUrl);
  }

  String _getTransformedUrl() {
    try {
      final cloudinary = cloudinary_service.CloudinaryService();
      return cloudinary.optimizeExistingUrl(originalUrl!, transformationType);
    } catch (e) {
      // Fallback para URL original em caso de erro
      return originalUrl!;
    }
  }

  Widget _buildImageWidget(BuildContext context, String url) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeIn,
      fadeOutDuration: fadeOut,
      placeholder: (context, url) => _buildShimmerPlaceholder(context),
      errorWidget: (context, url, error) => _buildFallback(context),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: (width?.toInt() ?? 400) * 2, // 2x for high DPI
      maxHeightDiskCache: (height?.toInt() ?? 400) * 2,
    );

    // Apply semantics for accessibility using localized string
  final semanticsLabel = AppLocalizations.of(context)?.cloudinary_optimized_image ?? 'Image optimized';

    Widget wrapped = Semantics(
      label: semanticsLabel,
      image: true,
      child: imageWidget,
    );

    // Aplicar forma circular ou bordas arredondadas
    if (circle) {
      return ClipOval(child: wrapped);
    } else if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: wrapped,
      );
    }

    return wrapped;
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    final semanticColors = context.semanticColors;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: semanticColors.skeletonBase,
        borderRadius: circle ? null : borderRadius,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: _buildShimmerEffect(context),
    );
  }

  Widget _buildShimmerEffect(BuildContext context) {
    final semanticColors = context.semanticColors;
    
    return AnimatedContainer(
      duration: PerformanceUtils.slowAnimation,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            semanticColors.skeletonBase,
            semanticColors.skeletonHighlight,
            semanticColors.skeletonBase,
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: circle ? null : borderRadius,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
      child: fallbackIcon ?? Icon(
        Icons.image_not_supported,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        size: (width != null && height != null) 
          ? (width! < height! ? width! : height!) * 0.5
          : 24,
      ),
    );
  }
}

/// Performance-optimized image list for grid views
class OptimizedImageGrid extends StatelessWidget {
  final List<String> imageUrls;
  final int crossAxisCount;
  final double aspectRatio;
  final EdgeInsets padding;
  final double mainAxisSpacing;
  final double crossAxisSpacing;

  const OptimizedImageGrid({
    super.key,
    required this.imageUrls,
    this.crossAxisCount = 2,
    this.aspectRatio = 1.0,
    this.padding = const EdgeInsets.all(8.0),
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: padding,
      itemCount: imageUrls.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      itemBuilder: (context, index) {
        // Usar RepaintBoundary para isolar rebuilds
        return RepaintBoundary(
          child: FastCloudinaryImage(
            key: ValueKey('grid_image_$index'),
            originalUrl: imageUrls[index],
            transformationType: cloudinary_service.ImageType.productThumbnail,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
