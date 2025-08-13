import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img; // For image manipulation

class SupabaseStorageService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final String _bucketName = 'wishlist-images';
  Future<String?> uploadImage(File imageFile, String path) async {
    try {
      // Optimize image before uploading
      final optimizedImageBytes = await _optimizeImage(imageFile);
      final optimizedImageFile = File(imageFile.path)..writeAsBytesSync(optimizedImageBytes);

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '$path/$fileName';

      final response = await _supabaseClient.storage
          .from(_bucketName)
          .upload(filePath, optimizedImageFile, fileOptions: const FileOptions(upsert: true));

      if (response.isNotEmpty) {
        return _supabaseClient.storage.from(_bucketName).getPublicUrl(filePath);
      }
      return null;
    } on StorageException catch (e) {
      print('Supabase Storage upload error: ${e.message}');
      return null;
    }
  }

  Future<Uint8List> _optimizeImage(File imageFile) async {
    img.Image? image = img.decodeImage(imageFile.readAsBytesSync());

    if (image == null) {
      return imageFile.readAsBytesSync(); // Return original if decoding fails
    }

    // Resize image if it's too large
    if (image.width > 1024 || image.height > 1024) {
      image = img.copyResize(image, width: 1024, height: -1); // Resize to max 1024px width, maintain aspect ratio
    }

    // Compress image (e.g., JPEG quality 80)
    return img.encodeJpg(image, quality: 80);
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      // The path in storage is usually everything after the bucket name
      // e.g., /public/wishlist-images/user_uploads/image.jpg
      // We need 'user_uploads/image.jpg'
      if (pathSegments.length > 2) { // Assuming format like /storage/v1/object/public/bucket_name/path/to/file
        final String pathInBucket = pathSegments.sublist(pathSegments.indexOf(_bucketName) + 1).join('/');
        await _supabaseClient.storage.from(_bucketName).remove([pathInBucket]);
      }
    } on StorageException catch (e) {
      print('Supabase Storage delete error: ${e.message}');
    }
  }
}