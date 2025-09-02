import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mywishstash/services/security_service.dart';
import 'package:mywishstash/services/monitoring_service.dart';
import 'package:mywishstash/utils/app_logger.dart';
import 'package:mywishstash/services/analytics/analytics_service.dart';

class CloudinaryService {
  // Singleton instance
  static final CloudinaryService _instance = CloudinaryService._internal();
  static bool _configured = false;

  late final CloudinaryPublic _cloudinary;
  final _securityService = SecurityService();

  /// Factory returns the shared instance (prevents multiple init + log spam)
  factory CloudinaryService() => _instance;

  CloudinaryService._internal() {
    if (_configured) return; // Already configured

    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];

    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary configuration missing in .env');
    }

    _cloudinary = CloudinaryPublic(cloudName, uploadPreset);
    _configured = true;
    logD('Cloudinary configured', tag: 'IMG', data: {'cloudName': cloudName});
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(File imageFile, String userId, {String? oldImageUrl}) async {
    try {
  final started = DateTime.now();
  final fileSize = await imageFile.length();
      logD('Upload profile image start', tag: 'IMG', data: {'userId': userId, 'hasOld': oldImageUrl != null});

      // Security validation
      final validationResult = await _securityService.validateImage(imageFile);
      if (!validationResult.isValid) {
        MonitoringService.logWarningStatic(
          'CloudinaryService',
          'Image validation failed: ${validationResult.error}',
        );
        throw Exception('Image validation failed: ${validationResult.error}');
      }

      // Extract old image public ID for cleanup if exists
      String? oldPublicId;
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        oldPublicId = _extractPublicIdFromUrl(oldImageUrl);
  logD('Old profile image detected', tag: 'IMG', data: {'oldPublicId': oldPublicId});
      }

      // Use timestamp to ensure unique URLs and avoid cache issues
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final result = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'wishlist/profiles',
          publicId: 'profile_${userId}_$timestamp',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

  logI('Profile image uploaded', tag: 'IMG', data: {'publicId': result.publicId});

      // Schedule cleanup of old image (log for now since we can't delete directly)
      if (oldPublicId != null) {
        await _scheduleImageCleanup(oldPublicId, 'profile');
      }

  // Analytics
  final durationMs = DateTime.now().difference(started).inMilliseconds;
  Future.microtask(() => AnalyticsService().log('image_upload_success', properties: {
    'type': 'profile',
    'bytes': fileSize,
    'duration_ms': durationMs,
    'public_id_suffix': result.publicId.split('/').last,
      }));

      return result.secureUrl;
    } catch (e) {
  logE('Error uploading profile image', tag: 'IMG', error: e, data: {'userId': userId});
  Future.microtask(() => AnalyticsService().log('image_upload_failure', properties: {
    'type': 'profile',
    'error': e.toString().substring(0, e.toString().length.clamp(0, 180)),
      }));
  throw Exception(_mapCloudinaryError(e));
    }
  }

  /// Upload product/wishlist item image
  Future<String?> uploadProductImage(File imageFile, String itemId, {String? oldImageUrl}) async {
    try {
  final started = DateTime.now();
  final fileSize = await imageFile.length();
      logD('Upload product image start', tag: 'IMG', data: {'itemId': itemId, 'hasOld': oldImageUrl != null});

      // Security validation
      final validationResult = await _securityService.validateImage(imageFile);
      if (!validationResult.isValid) {
        MonitoringService.logWarningStatic(
          'CloudinaryService',
          'Product image validation failed: ${validationResult.error}',
        );
        throw Exception('Image validation failed: ${validationResult.error}');
      }

      // Extract old image public ID for cleanup if exists
      String? oldPublicId;
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        oldPublicId = _extractPublicIdFromUrl(oldImageUrl);
  logD('Old product image detected', tag: 'IMG', data: {'oldPublicId': oldPublicId});
      }

      // Use timestamp to ensure unique URLs
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final result = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'wishlist/products',
          publicId: 'product_${itemId}_$timestamp',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

  logI('Product image uploaded', tag: 'IMG', data: {'publicId': result.publicId});

      // Schedule cleanup of old image
      if (oldPublicId != null) {
        await _scheduleImageCleanup(oldPublicId, 'product');
      }

  final durationMs = DateTime.now().difference(started).inMilliseconds;
  Future.microtask(() => AnalyticsService().log('image_upload_success', properties: {
    'type': 'product',
    'bytes': fileSize,
    'duration_ms': durationMs,
    'public_id_suffix': result.publicId.split('/').last,
      }));

      return result.secureUrl;
    } catch (e) {
      logE('Error uploading product image', tag: 'IMG', error: e, data: {'itemId': itemId});
  Future.microtask(() => AnalyticsService().log('image_upload_failure', properties: {
    'type': 'product',
    'error': e.toString().substring(0, e.toString().length.clamp(0, 180)),
      }));
  throw Exception(_mapCloudinaryError(e));
    }
  }

  /// Upload wishlist icon/cover image
  Future<String?> uploadWishlistImage(File imageFile, String wishlistId, {String? oldImageUrl}) async {
    try {
  final started = DateTime.now();
  final fileSize = await imageFile.length();
      logD('Upload wishlist image start', tag: 'IMG', data: {'wishlistId': wishlistId, 'hasOld': oldImageUrl != null});

      // Security validation
      final validationResult = await _securityService.validateImage(imageFile);
      if (!validationResult.isValid) {
        MonitoringService.logWarningStatic(
          'CloudinaryService',
          'Wishlist image validation failed: ${validationResult.error}',
        );
        throw Exception('Image validation failed: ${validationResult.error}');
      }

      // Extract old image public ID for cleanup if exists
      String? oldPublicId;
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        oldPublicId = _extractPublicIdFromUrl(oldImageUrl);
  logD('Old wishlist image detected', tag: 'IMG', data: {'oldPublicId': oldPublicId});
      }

      // Use timestamp to ensure unique URLs
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final result = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'wishlist/wishlists',
          publicId: 'wishlist_${wishlistId}_$timestamp',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

  logI('Wishlist image uploaded', tag: 'IMG', data: {'publicId': result.publicId});

      // Schedule cleanup of old image
      if (oldPublicId != null) {
        await _scheduleImageCleanup(oldPublicId, 'wishlist');
      }

  final durationMs = DateTime.now().difference(started).inMilliseconds;
  Future.microtask(() => AnalyticsService().log('image_upload_success', properties: {
    'type': 'wishlist',
    'bytes': fileSize,
    'duration_ms': durationMs,
    'public_id_suffix': result.publicId.split('/').last,
      }));

      return result.secureUrl;
    } catch (e) {
      logE('Error uploading wishlist image', tag: 'IMG', error: e, data: {'wishlistId': wishlistId});
  Future.microtask(() => AnalyticsService().log('image_upload_failure', properties: {
    'type': 'wishlist',
    'error': e.toString().substring(0, e.toString().length.clamp(0, 180)),
      }));
  throw Exception(_mapCloudinaryError(e));
    }
  }

  /// Extract public ID from Cloudinary URL
  String? _extractPublicIdFromUrl(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the upload segment and extract everything after it
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return null;
      }
      
      // Get public ID (everything after upload, excluding transformations)
      String publicId = pathSegments.sublist(uploadIndex + 1).join('/');
      
      // Remove file extension if present
      if (publicId.contains('.')) {
        publicId = publicId.substring(0, publicId.lastIndexOf('.'));
      }
      
      return publicId;
    } catch (e) {
      logE('Extract publicId error', tag: 'IMG', error: e);
      return null;
    }
  }

  /// Schedule image cleanup (logs cleanup info since client-side deletion isn't supported)
  Future<void> _scheduleImageCleanup(String publicId, String imageType) async {
    try {
      logD('Schedule image cleanup', tag: 'IMG', data: {'publicId': publicId, 'type': imageType});
      
      // Store cleanup request in Firestore for future processing
      await _storeCleanupRequest(publicId, imageType);
      
  // Cleanup flow:
  // 1. Request stored (queue) ✅
  // 2. Cloud Function scheduledImageCleanup (server) consome e chama Admin API ✅
  // 3. Status atualizado (processed / failed) com retries ✅
      
      MonitoringService.logInfoStatic(
        'CloudinaryService',
        'Image cleanup scheduled: $publicId ($imageType)',
      );
    } catch (e) {
      logE('Schedule image cleanup error', tag: 'IMG', error: e, data: {'publicId': publicId});
    }
  }

  /// Store cleanup request in Firestore for future batch processing
  Future<void> _storeCleanupRequest(String publicId, String imageType) async {
    try {
      // Import here to avoid circular dependencies
      final firestore = FirebaseFirestore.instance;
      
      await firestore.collection('image_cleanup_queue').add({
        'public_id': publicId,
        'image_type': imageType,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
        'cloud_name': dotenv.env['CLOUDINARY_CLOUD_NAME'],
      });
      
  logD('Cleanup request stored', tag: 'IMG', data: {'publicId': publicId});
    } catch (e) {
  logW('Failed to store cleanup request', tag: 'IMG', data: {'publicId': publicId, 'err': e.toString()});
      // Don't throw error - cleanup storage is not critical for main functionality
    }
  }

  String _mapCloudinaryError(Object e) {
    final raw = e.toString();
    if (raw.contains('401')) {
      return 'Erro Cloudinary 401 (autenticação/credenciais). Verifica CLOUDINARY_CLOUD_NAME e CLOUDINARY_UPLOAD_PRESET (unsigned preset).';
    }
    if (raw.contains('upload_preset')) {
      return 'Upload preset inválido ou não existe. Confirma CLOUDINARY_UPLOAD_PRESET e se está marcado como unsigned.';
    }
    if (raw.contains('ENOTFOUND')) {
      return 'Não foi possível resolver o host Cloudinary (verifica ligação e nome do cloud).';
    }
    if (raw.contains('413') || raw.contains('Payload Too Large')) {
      return 'Imagem demasiado grande. Reduz resolução/tamanho.';
    }
    return 'Falha no upload de imagem: $raw';
  }

  /// Get optimization transformation
  String getOptimizedImageUrl(String publicId, ImageType type) {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    if (cloudName == null) return publicId;

    final baseUrl = 'https://res.cloudinary.com/$cloudName/image/upload';
    
    String transformation;
    switch (type) {
      case ImageType.profileSmall:
        transformation = 'w_150,h_150,c_fill,f_auto,q_auto';
        break;
      case ImageType.profileLarge:
        transformation = 'w_400,h_400,c_fill,f_auto,q_auto';
        break;
      case ImageType.productThumbnail:
        transformation = 'w_200,h_150,c_fit,f_auto,q_auto';
        break;
      case ImageType.productLarge:
        transformation = 'w_800,h_600,c_fit,f_auto,q_auto';
        break;
      case ImageType.wishlistIcon:
        transformation = 'w_100,h_100,c_fill,f_auto,q_auto';
        break;
      case ImageType.original:
        transformation = 'f_auto,q_auto';
        break;
    }

    return '$baseUrl/$transformation/$publicId';
  }

  /// Convert Cloudinary URL to optimized version
  String optimizeExistingUrl(String cloudinaryUrl, ImageType type) {
    try {
      // Extract public ID from URL
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      
      // Find the upload segment and extract everything after it
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return cloudinaryUrl; // Return original if can't parse
      }
      
      final publicId = pathSegments.sublist(uploadIndex + 1).join('/');
      return getOptimizedImageUrl(publicId, type);
    } catch (e) {
      logE('Optimize URL error', tag: 'IMG', error: e);
      return cloudinaryUrl; // Return original on error
    }
  }

  /// Generate a very low-res heavily blurred placeholder variant for progressive loading.
  String optimizeLowResPlaceholderUrl(String cloudinaryUrl) {
    try {
      final uri = Uri.parse(cloudinaryUrl);
      final pathSegments = uri.pathSegments;
      final uploadIndex = pathSegments.indexOf('upload');
      if (uploadIndex == -1 || uploadIndex >= pathSegments.length - 1) {
        return cloudinaryUrl; // can't parse structure
      }
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
      if (cloudName == null) return cloudinaryUrl;
      final publicId = pathSegments.sublist(uploadIndex + 1).join('/');
      return 'https://res.cloudinary.com/'
          '$cloudName/image/upload/w_40,q_10,e_blur:200,f_auto/'
          '$publicId';
    } catch (_) {
      return cloudinaryUrl;
    }
  }

  /// Delete image from Cloudinary
  /// Note: Image deletion requires the Admin API which is not available in the public SDK
  /// Images can be deleted from the Cloudinary dashboard or using server-side API calls
  Future<bool> deleteImage(String publicId) async {
    try {
      logW('Image deletion not supported client-side', tag: 'IMG', data: {'publicId': publicId});
      
      // Return false to indicate deletion is not supported in client-side
      return false;
    } catch (e) {
      logE('Image deletion error', tag: 'IMG', error: e, data: {'publicId': publicId});
      return false;
    }
  }

  /// Get list of user images that should be deleted (for server-side cleanup)
  List<String> getUserImagePublicIds(String userId) {
    return [
      'profile_$userId', // Profile image
      // Note: Product and wishlist images would need to be fetched from database
      // as they have dynamic IDs
    ];
  }

  /// Delete all user images (logs what should be deleted for server-side cleanup)
  Future<Map<String, dynamic>> deleteUserImages(String userId) async {
    try {
      debugPrint('=== User Image Cleanup Required ===');
      debugPrint('User ID: $userId');
      
      // Schedule cleanup for profile images (multiple versions with timestamps)
      await _scheduleUserProfileCleanup(userId);
      
      // NOTE: Product and wishlist images would need to be fetched from database for complete cleanup
      // These have dynamic IDs and would need to be retrieved from wish_items and wishlists tables
      debugPrint('Additional cleanup needed:');
      debugPrint('- Product images from wish_items where wishlist owner = $userId');
      debugPrint('- Wishlist cover images where owner = $userId');
      
      // Schedule a bulk cleanup job for this user
      await _scheduleBulkUserCleanup(userId);
      
      return {
        'success': true,
        'message': 'User image cleanup scheduled - requires server-side deletion',
        'user_id': userId,
        'cleanup_scheduled_at': DateTime.now().toIso8601String(),
        'note': 'Use Firebase Cloud Functions or Cloudinary Admin API for actual deletion'
      };
    } catch (e) {
      debugPrint('Error preparing user image cleanup: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Schedule cleanup for all profile images of a user
  Future<void> _scheduleUserProfileCleanup(String userId) async {
    try {
      await _storeCleanupRequest('profile_$userId*', 'user_profile_bulk');
      logD('Scheduled profile images cleanup', tag: 'IMG', data: {'userId': userId});
    } catch (e) {
  logW('Failed scheduling profile images cleanup', tag: 'IMG', data: {'userId': userId, 'err': e.toString()});
    }
  }

  /// Schedule bulk cleanup for all user images
  Future<void> _scheduleBulkUserCleanup(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('bulk_cleanup_queue').add({
        'user_id': userId,
        'cleanup_type': 'user_deletion',
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
        'folders_to_clean': [
          'wishlist/profiles',
          'wishlist/products', 
          'wishlist/wishlists'
        ],
        'pattern': '*$userId*',
        'cloud_name': dotenv.env['CLOUDINARY_CLOUD_NAME'],
      });
      logD('Bulk cleanup scheduled', tag: 'IMG', data: {'userId': userId});
    } catch (e) {
  logW('Failed scheduling bulk cleanup', tag: 'IMG', data: {'userId': userId, 'err': e.toString()});
    }
  }

  /// Schedule cleanup when a wishlist is deleted
  Future<void> scheduleWishlistCleanup(String wishlistId, List<String> productImageUrls) async {
    try {
      logD('Wishlist deletion cleanup', tag: 'IMG', data: {'wishlistId': wishlistId, 'productImages': productImageUrls.length});

      // Schedule wishlist cover image cleanup
      await _scheduleImageCleanup('wishlist_$wishlistId*', 'wishlist_bulk');

      // Schedule all product images cleanup
      for (final imageUrl in productImageUrls) {
        final publicId = _extractPublicIdFromUrl(imageUrl);
        if (publicId != null) {
          await _scheduleImageCleanup(publicId, 'product');
        }
      }

  logD('Scheduled wishlist cleanup', tag: 'IMG', data: {'wishlistId': wishlistId, 'products': productImageUrls.length});
    } catch (e) {
  logE('Error scheduling wishlist cleanup', tag: 'IMG', error: e, data: {'wishlistId': wishlistId});
    }
  }

  /// Schedule cleanup when a product is deleted
  Future<void> scheduleProductCleanup(String productImageUrl) async {
    try {
      final publicId = _extractPublicIdFromUrl(productImageUrl);
      if (publicId != null) {
        await _scheduleImageCleanup(publicId, 'product');
        logD('Scheduled product image cleanup', tag: 'IMG', data: {'publicId': publicId});
      }
    } catch (e) {
      logE('Error scheduling product cleanup', tag: 'IMG', error: e);
    }
  }

  /// Get image info
  Future<Map<String, dynamic>?> getImageInfo(String publicId) async {
    try {
      // Note: This requires the Cloudinary Admin API
      // For now, just return basic info
      return {
        'public_id': publicId,
        'secure_url': getOptimizedImageUrl(publicId, ImageType.original),
      };
    } catch (e) {
      logE('Get image info error', tag: 'IMG', error: e, data: {'publicId': publicId});
      return null;
    }
  }
}

enum ImageType {
  profileSmall,    // 150x150 for small profile pics
  profileLarge,    // 400x400 for large profile pics
  productThumbnail, // 200x150 for product thumbnails
  productLarge,    // 800x600 for product detail view
  wishlistIcon,    // 100x100 for wishlist icons
  original,        // Original size with auto format/quality
}