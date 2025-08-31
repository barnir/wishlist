import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wishlist_app/repositories/wishlist_repository.dart';
import 'package:wishlist_app/repositories/wish_item_repository.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:wishlist_app/services/cloudinary_service.dart';

/// Simple prefetch of initial wishlist + item images to warm cache.
class ImagePrefetchService {
  static final ImagePrefetchService _instance = ImagePrefetchService._internal();
  factory ImagePrefetchService() => _instance;
  ImagePrefetchService._internal();

  final WishlistRepository _wishlistRepo = WishlistRepository();
  final WishItemRepository _wishItemRepo = WishItemRepository();
  bool _running = false;

  Future<void> warmUp({int wishlists = 5, int itemsPerWishlist = 3}) async {
    if (_running) return;
    _running = true;
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) return;

      CloudinaryService? cloudinary;
      try {
        cloudinary = CloudinaryService();
      } catch (_) {
        cloudinary = null; // Cloudinary config missing -> fallback to raw URLs
      }

      // Fetch first page of wishlists (optimize to icon size if cloudinary available)
      final wlPage = await _wishlistRepo.fetchUserWishlists(ownerId: userId, limit: wishlists);
      for (final w in wlPage.items) {
        final url = w.imageUrl;
        if (url != null && _isNetworkUrl(url)) {
          final effective = cloudinary != null
              ? cloudinary.optimizeExistingUrl(url, ImageType.wishlistIcon)
              : url;
          _prefetch(effective);
        }
      }

      // For each wishlist, fetch a few items (optimize to thumbnail size)
      for (final w in wlPage.items) {
        final itemPage = await _wishItemRepo.fetchPage(wishlistId: w.id, limit: itemsPerWishlist);
        for (final it in itemPage.items) {
          final url = it.imageUrl;
          if (url != null && _isNetworkUrl(url)) {
            final effective = cloudinary != null
                ? cloudinary.optimizeExistingUrl(url, ImageType.productThumbnail)
                : url;
            _prefetch(effective);
          }
        }
      }
      MonitoringService.logInfoStatic('ImagePrefetch', 'Warm-up concluído');
    } catch (e, st) {
      MonitoringService.logErrorStatic('image_prefetch', e, stackTrace: st);
    } finally {
      _running = false;
    }
  }

  bool _isNetworkUrl(dynamic v) => v is String && v.startsWith('http');
  void _prefetch(String url) {
    // Trigger download into cache
    CachedNetworkImageProvider(url).resolve(const ImageConfiguration());
    if (kDebugMode) {
      MonitoringService.logInfoStatic('ImagePrefetch', 'Prefetch $url');
    }
  }
}
