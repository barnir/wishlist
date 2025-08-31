// One-off script to backfill owner_id on wish_items based on wishlist.owner_id
// Run with: flutter run -d none tool/backfill_wish_item_owner.dart (or dart run)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  await Firebase.initializeApp();
  final fs = FirebaseFirestore.instance;
  final wishItems = await fs.collection('wish_items').get();
  int updated = 0; int total = wishItems.docs.length;
  for (final d in wishItems.docs) {
    final data = d.data();
    if (data['owner_id'] == null) {
      final wid = data['wishlist_id'];
      if (wid != null) {
        final wl = await fs.collection('wishlists').doc(wid).get();
        final ownerId = wl.data()?['owner_id'];
        if (ownerId != null) {
          await d.reference.update({'owner_id': ownerId});
          updated++;
        }
      }
    }
  }
  // ignore: avoid_print
  print('Backfill complete: $updated / $total wish_items updated with owner_id');
}