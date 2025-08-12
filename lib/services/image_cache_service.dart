import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  static final DefaultCacheManager _cacheManager = DefaultCacheManager();

  static Future<File> getFile(String url) async {
    return await _cacheManager.getSingleFile(url);
  }

  static Future<File> putFile(String url, Uint8List bytes) async {
    return await _cacheManager.putFile(url, bytes);
  }
}