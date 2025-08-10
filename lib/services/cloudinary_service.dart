import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:wishlist_app/config.dart';

class CloudinaryService {
  final CloudinaryPublic _cloudinary;

  CloudinaryService() : _cloudinary = CloudinaryPublic(
    Config.cloudinaryCloudName,
    Config.cloudinaryUploadPreset,
    cache: false
  );

  Future<String?> uploadImage(File imageFile) async {
    try {
      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(imageFile.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print(e.message);
      return null;
    }
  }
}
