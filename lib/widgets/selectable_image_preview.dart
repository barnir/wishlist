import 'package:flutter/material.dart';
import 'optimized_cloudinary_image.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';

/// Reusable image picker/display widget integrating OptimizedCloudinaryImage
/// with optional local preview path and upload progress overlay.
class SelectableImagePreview extends StatelessWidget {
  final String? existingUrl;
  final String? localPreviewPath;
  final VoidCallback? onTap;
  final bool isUploading;
  final ImageType transformationType;
  final double size;
  final bool circle;
  final Icon fallbackIcon;
  final double borderRadius;
  final bool blurPlaceholder;

  const SelectableImagePreview({
    super.key,
    required this.existingUrl,
    required this.localPreviewPath,
    required this.onTap,
    required this.isUploading,
    required this.transformationType,
    required this.size,
    required this.circle,
    required this.fallbackIcon,
    this.borderRadius = 16,
    this.blurPlaceholder = true,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = OptimizedCloudinaryImage(
      originalUrl: existingUrl,
      localPreviewPath: localPreviewPath,
      transformationType: transformationType,
      width: size,
      height: size,
      circle: circle,
      borderRadius: circle ? null : BorderRadius.circular(borderRadius),
      fit: BoxFit.cover,
      blurPlaceholder: blurPlaceholder,
      fallbackIcon: fallbackIcon,
    );

    final child = Stack(
      alignment: Alignment.center,
      children: [
        ClipOvalOrRect(
          circle: circle,
          borderRadius: borderRadius,
          child: imageWidget,
        ),
        if (!isUploading && existingUrl == null && localPreviewPath == null)
          Positioned(
            bottom: 8,
            right: 8,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(200),
              child: Icon(Icons.add, size: 16, color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
        if (isUploading)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
              shape: circle ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: circle ? null : BorderRadius.circular(borderRadius),
            ),
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          ),
      ],
    );

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: child,
      ),
    );
  }
}

class ClipOvalOrRect extends StatelessWidget {
  final bool circle;
  final double borderRadius;
  final Widget child;
  const ClipOvalOrRect({super.key, required this.circle, required this.borderRadius, required this.child});

  @override
  Widget build(BuildContext context) => circle
      ? ClipOval(child: child)
      : ClipRRect(borderRadius: BorderRadius.circular(borderRadius), child: child);
}