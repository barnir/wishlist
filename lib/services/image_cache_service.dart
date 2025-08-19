import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// A service for caching images.
///
/// This service uses the `flutter_cache_manager` package to cache images.
class ImageCacheService {
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();

  /// Retrieves a file from the cache.
  ///
  /// If the file is not in the cache, it will be downloaded from the given [url].
  static Future<File> getFile(String url) async {
    return await _cacheManager.getSingleFile(url);
  }

  /// Puts a file into the cache.
  ///
  /// The file will be stored at the given [url].
  static Future<File> putFile(String url, Uint8List bytes) async {
    return await _cacheManager.putFile(url, bytes);
  }
}
