import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wishlist_app/services/security_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';

class CloudinaryService {
  late final CloudinaryPublic _cloudinary;
  final _securityService = SecurityService();
  
  CloudinaryService() {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'];
    
    if (cloudName == null || uploadPreset == null) {
      throw Exception('Cloudinary configuration missing in .env');
    }
    
    _cloudinary = CloudinaryPublic(cloudName, uploadPreset);
    debugPrint('=== Cloudinary Service Initialized ===');
    debugPrint('Cloud Name: $cloudName');
    debugPrint('Upload Preset: $uploadPreset');
  }

  /// Upload profile image
  Future<String?> uploadProfileImage(File imageFile, String userId, {String? oldImageUrl}) async {
    try {
      debugPrint('=== Uploading Profile Image ===');
      debugPrint('User ID: $userId');
      debugPrint('File path: ${imageFile.path}');
      debugPrint('Old image URL: $oldImageUrl');

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
        debugPrint('Old image public ID to cleanup: $oldPublicId');
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

      debugPrint('Profile image uploaded successfully');
      debugPrint('Public ID: ${result.publicId}');
      debugPrint('Secure URL: ${result.secureUrl}');

      // Schedule cleanup of old image (log for now since we can't delete directly)
      if (oldPublicId != null) {
        await _scheduleImageCleanup(oldPublicId, 'profile');
      }

      return result.secureUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Upload product/wishlist item image
  Future<String?> uploadProductImage(File imageFile, String itemId, {String? oldImageUrl}) async {
    try {
      debugPrint('=== Uploading Product Image ===');
      debugPrint('Item ID: $itemId');
      debugPrint('File path: ${imageFile.path}');
      debugPrint('Old image URL: $oldImageUrl');

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
        debugPrint('Old product image public ID to cleanup: $oldPublicId');
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

      debugPrint('Product image uploaded successfully');
      debugPrint('Public ID: ${result.publicId}');
      debugPrint('Secure URL: ${result.secureUrl}');

      // Schedule cleanup of old image
      if (oldPublicId != null) {
        await _scheduleImageCleanup(oldPublicId, 'product');
      }

      return result.secureUrl;
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      rethrow;
    }
  }

  /// Upload wishlist icon/cover image
  Future<String?> uploadWishlistImage(File imageFile, String wishlistId, {String? oldImageUrl}) async {
    try {
      debugPrint('=== Uploading Wishlist Image ===');
      debugPrint('Wishlist ID: $wishlistId');
      debugPrint('File path: ${imageFile.path}');
      debugPrint('Old image URL: $oldImageUrl');

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
        debugPrint('Old wishlist image public ID to cleanup: $oldPublicId');
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

      debugPrint('Wishlist image uploaded successfully');
      debugPrint('Public ID: ${result.publicId}');
      debugPrint('Secure URL: ${result.secureUrl}');

      // Schedule cleanup of old image
      if (oldPublicId != null) {
        await _scheduleImageCleanup(oldPublicId, 'wishlist');
      }

      return result.secureUrl;
    } catch (e) {
      debugPrint('Error uploading wishlist image: $e');
      rethrow;
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
      debugPrint('Error extracting public ID from URL: $e');
      return null;
    }
  }

  /// Schedule image cleanup (logs cleanup info since client-side deletion isn't supported)
  Future<void> _scheduleImageCleanup(String publicId, String imageType) async {
    try {
      debugPrint('=== IMAGE CLEANUP SCHEDULED ===');
      debugPrint('Public ID: $publicId');
      debugPrint('Image Type: $imageType');
      debugPrint('Timestamp: ${DateTime.now().toIso8601String()}');
      debugPrint('Action Required: Delete from Cloudinary dashboard or use server-side API');
      
      // Store cleanup request in Firestore for future processing
      await _storeCleanupRequest(publicId, imageType);
      
      // TODO: In a production app, you would:
      // 1. ✅ Store this cleanup request in a database (implemented above)
      // 2. Have a server-side job/function that processes cleanup requests
      // 3. Use Cloudinary Admin API to actually delete the image
      
      MonitoringService.logInfoStatic(
        'CloudinaryService',
        'Image cleanup scheduled: $publicId ($imageType)',
      );
    } catch (e) {
      debugPrint('Error scheduling image cleanup: $e');
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
      
      debugPrint('✅ Cleanup request stored in Firestore: $publicId');
    } catch (e) {
      debugPrint('⚠️ Failed to store cleanup request: $e');
      // Don't throw error - cleanup storage is not critical for main functionality
    }
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
      debugPrint('Error optimizing URL: $e');
      return cloudinaryUrl; // Return original on error
    }
  }

  /// Delete image from Cloudinary
  /// Note: Image deletion requires the Admin API which is not available in the public SDK
  /// Images can be deleted from the Cloudinary dashboard or using server-side API calls
  Future<bool> deleteImage(String publicId) async {
    try {
      debugPrint('=== Image Deletion Not Supported in Public SDK ===');
      debugPrint('Public ID: $publicId');
      debugPrint('Use Cloudinary dashboard or server-side API to delete images');
      
      // Return false to indicate deletion is not supported in client-side
      return false;
    } catch (e) {
      debugPrint('Error with image deletion: $e');
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
      debugPrint('✅ Scheduled cleanup for all profile images of user: $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule user profile cleanup: $e');
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
      
      debugPrint('✅ Bulk cleanup scheduled for user: $userId');
    } catch (e) {
      debugPrint('⚠️ Failed to schedule bulk cleanup: $e');
    }
  }

  /// Schedule cleanup when a wishlist is deleted
  Future<void> scheduleWishlistCleanup(String wishlistId, List<String> productImageUrls) async {
    try {
      debugPrint('=== Wishlist Deletion Cleanup ===');
      debugPrint('Wishlist ID: $wishlistId');
      debugPrint('Product images to clean: ${productImageUrls.length}');

      // Schedule wishlist cover image cleanup
      await _scheduleImageCleanup('wishlist_$wishlistId*', 'wishlist_bulk');

      // Schedule all product images cleanup
      for (final imageUrl in productImageUrls) {
        final publicId = _extractPublicIdFromUrl(imageUrl);
        if (publicId != null) {
          await _scheduleImageCleanup(publicId, 'product');
        }
      }

      debugPrint('✅ Scheduled cleanup for wishlist and ${productImageUrls.length} products');
    } catch (e) {
      debugPrint('⚠️ Error scheduling wishlist cleanup: $e');
    }
  }

  /// Schedule cleanup when a product is deleted
  Future<void> scheduleProductCleanup(String productImageUrl) async {
    try {
      final publicId = _extractPublicIdFromUrl(productImageUrl);
      if (publicId != null) {
        await _scheduleImageCleanup(publicId, 'product');
        debugPrint('✅ Scheduled cleanup for product image: $publicId');
      }
    } catch (e) {
      debugPrint('⚠️ Error scheduling product cleanup: $e');
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
      debugPrint('Error getting image info: $e');
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