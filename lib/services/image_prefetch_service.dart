import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mywishstash/repositories/wishlist_repository.dart';
import 'package:mywishstash/repositories/wish_item_repository.dart';
import 'package:mywishstash/services/auth_service.dart';
import 'package:mywishstash/services/monitoring_service.dart';
import 'package:mywishstash/services/cloudinary_service.dart';

/// Simple prefetch of initial wishlist + item images to warm cache.
class ImagePrefetchService {
  static final ImagePrefetchService _instance = ImagePrefetchService._internal();
  factory ImagePrefetchService() => _instance;
  ImagePrefetchService._internal();

  final WishlistRepository _wishlistRepo = WishlistRepository();
  final WishItemRepository _wishItemRepo = WishItemRepository();
  bool _running = false;
  bool _cancelled = false;

  /// Cancel any in-flight warmUp (best-effort).
  void cancel() {
    _cancelled = true;
  }

  Future<void> warmUp({int wishlists = 5, int itemsPerWishlist = 3, int concurrency = 4}) async {
    if (_running) return;
    _running = true;
    _cancelled = false;
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
      final wishlistUrls = <String>[];
      for (final w in wlPage.items) {
        if (_cancelled) return;
        final url = w.imageUrl;
        if (url != null && _isNetworkUrl(url)) {
          wishlistUrls.add(cloudinary != null
              ? cloudinary.optimizeExistingUrl(url, ImageType.wishlistIcon)
              : url);
        }
      }
      await _prefetchBatch(wishlistUrls, concurrency: concurrency);

      // For each wishlist, fetch a few items (optimize to thumbnail size)
      final itemUrls = <String>[];
      for (final w in wlPage.items) {
        if (_cancelled) return;
        final itemPage = await _wishItemRepo.fetchPage(wishlistId: w.id, limit: itemsPerWishlist);
        for (final it in itemPage.items) {
          if (_cancelled) return;
          final url = it.imageUrl;
            if (url != null && _isNetworkUrl(url)) {
              itemUrls.add(cloudinary != null
                  ? cloudinary.optimizeExistingUrl(url, ImageType.productThumbnail)
                  : url);
            }
        }
      }
      await _prefetchBatch(itemUrls, concurrency: concurrency);
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

  Future<void> _prefetchBatch(List<String> urls, {required int concurrency}) async {
    if (urls.isEmpty) return;
    concurrency = concurrency.clamp(1, 8);
    var index = 0;
    final total = urls.length;
    while (index < total) {
      if (_cancelled) return;
      final slice = urls.sublist(index, (index + concurrency).clamp(0, total));
      await Future.wait(slice.map((u) async {
        if (_cancelled) return;
        _prefetch(u);
      }));
      index += slice.length;
    }
  }
}
