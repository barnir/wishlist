// One-off migration utility to upload legacy local image paths to Cloudinary.
// Run with: flutter run -t tool/migrate_images.dart --dart-define=ADMIN_MODE=1 \
//   --dart-define=CLOUDINARY_CLOUD_NAME=xxx --dart-define=CLOUDINARY_UPLOAD_PRESET=yyy
// Dry run (no uploads): add --dart-define=DRY_RUN=1
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

Future<void> main() async {
  const isAdmin = String.fromEnvironment('ADMIN_MODE') == '1';
  if (!isAdmin) {
    stderr.writeln('ADMIN_MODE=1 required');
    exit(1);
  }
  await Firebase.initializeApp();
  final fs = FirebaseFirestore.instance;
  const dryRun = String.fromEnvironment('DRY_RUN') == '1';
  const cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  const preset = String.fromEnvironment('CLOUDINARY_UPLOAD_PRESET');
  if (cloudName.isEmpty || preset.isEmpty) {
    stderr.writeln('Cloudinary vars missing');
    exit(1);
  }
  final cloudinary = CloudinaryPublic(cloudName, preset);

  bool isLocal(String? v) {
    if (v == null || v.isEmpty) return false;
    final low = v.toLowerCase();
    if (low.startsWith('http://') || low.startsWith('https://')) return false;
    return low.contains(':') || low.contains('/data/');
  }

  Future<int> processCollection(String name, String folder, String prefix) async {
    final snap = await fs.collection(name).get();
  var migrated = 0;
    for (final d in snap.docs) {
      final local = d.data()['image_url'];
      if (!isLocal(local)) continue;
      if (!File(local).existsSync()) {
        stdout.writeln('[MISS] $name/${d.id} file not found');
        continue;
      }
  stdout.writeln('[MIGRATE] $name/${d.id} -> $local');
      if (dryRun) continue;
      try {
        final res = await cloudinary.uploadFile(CloudinaryFile.fromFile(local, folder: folder, publicId: '${prefix}_${d.id}'));
        await d.reference.update({'image_url': res.secureUrl});
        migrated++;
  stdout.writeln('  -> ${res.secureUrl}');
      } catch (e) {
        stderr.writeln('  !! error uploading $local: $e');
      }
    }
    return migrated;
  }

  final w = await processCollection('wishlists', 'wishlist/wishlists', 'wishlist');
  final i = await processCollection('wish_items', 'wishlist/products', 'product');
  stdout.writeln('Done. Migrated wishlists: $w items: $i dryRun=$dryRun');
}