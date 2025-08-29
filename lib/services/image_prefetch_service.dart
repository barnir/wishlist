import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';

/// Simple prefetch of initial wishlist + item images to warm cache.
class ImagePrefetchService {
  static final ImagePrefetchService _instance = ImagePrefetchService._internal();
  factory ImagePrefetchService() => _instance;
  ImagePrefetchService._internal();

  final _db = FirebaseDatabaseService();
  bool _running = false;

  Future<void> warmUp({int wishlists = 5, int itemsPerWishlist = 3}) async {
    if (_running) return;
    _running = true;
    try {
      final userId = _db.currentUserId;
      if (userId == null) return;
      final wl = await _db.getUserWishlists(userId);
      final subset = wl.take(wishlists);
      for (final w in subset) {
        final url = w['image_url'];
        if (_isNetworkUrl(url)) _prefetch(url);
      }
      // Prefetch a few items per wishlist (simple approach)
      for (final w in subset) {
        final allItems = await _db.getWishItemsPaginatedFuture(w['id'], limit: itemsPerWishlist);
        for (final it in allItems) {
          final url = it['image_url'];
            if (_isNetworkUrl(url)) _prefetch(url);
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
