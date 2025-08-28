import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
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
  Future<String?> uploadProfileImage(File imageFile, String userId) async {
    try {
      debugPrint('=== Uploading Profile Image ===');
      debugPrint('User ID: $userId');
      debugPrint('File path: ${imageFile.path}');

      // Security validation
      final validationResult = await _securityService.validateImage(imageFile);
      if (!validationResult.isValid) {
        MonitoringService.logWarningStatic(
          'CloudinaryService',
          'Image validation failed: ${validationResult.error}',
        );
        throw Exception('Image validation failed: ${validationResult.error}');
      }

      final result = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'wishlist/profiles',
          publicId: 'profile_$userId',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      debugPrint('Profile image uploaded successfully');
      debugPrint('Public ID: ${result.publicId}');
      debugPrint('Secure URL: ${result.secureUrl}');

      return result.secureUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  /// Upload product/wishlist item image
  Future<String?> uploadProductImage(File imageFile, String itemId) async {
    try {
      debugPrint('=== Uploading Product Image ===');
      debugPrint('Item ID: $itemId');
      debugPrint('File path: ${imageFile.path}');

      final result = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'wishlist/products',
          publicId: 'product_$itemId',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      debugPrint('Product image uploaded successfully');
      debugPrint('Public ID: ${result.publicId}');
      debugPrint('Secure URL: ${result.secureUrl}');

      return result.secureUrl;
    } catch (e) {
      debugPrint('Error uploading product image: $e');
      rethrow;
    }
  }

  /// Upload wishlist icon/cover image
  Future<String?> uploadWishlistImage(File imageFile, String wishlistId) async {
    try {
      debugPrint('=== Uploading Wishlist Image ===');
      debugPrint('Wishlist ID: $wishlistId');
      debugPrint('File path: ${imageFile.path}');

      final result = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          folder: 'wishlist/wishlists',
          publicId: 'wishlist_$wishlistId',
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      debugPrint('Wishlist image uploaded successfully');
      debugPrint('Public ID: ${result.publicId}');
      debugPrint('Secure URL: ${result.secureUrl}');

      return result.secureUrl;
    } catch (e) {
      debugPrint('Error uploading wishlist image: $e');
      rethrow;
    }
  }

  /// Generate optimized URLs for different use cases
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
      
      final imagesToDelete = <String>[];
      
      // Profile image
      final profileImageId = 'profile_$userId';
      imagesToDelete.add(profileImageId);
      debugPrint('Should delete profile image: $profileImageId');
      
      // NOTE: Product and wishlist images would need to be fetched from database for complete cleanup
      // These have dynamic IDs and would need to be retrieved from wish_items table
      debugPrint('Additional cleanup needed:');
      debugPrint('- Product images from wish_items where wishlist owner = $userId');
      debugPrint('- Wishlist cover images where owner = $userId');
      
      return {
        'success': true,
        'message': 'Image cleanup logged - requires server-side deletion',
        'profile_images': [profileImageId],
        'note': 'Use Firebase Cloud Functions or Cloudinary Admin API for actual deletion'
      };
    } catch (e) {
      debugPrint('Error preparing image cleanup: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
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