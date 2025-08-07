import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wish_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _wishlistCollection = 'wishlist';

  // Captura a coleção
  CollectionReference get _collection => _firestore.collection(_wishlistCollection);

  Stream<List<WishItem>> streamWishlist() {
    return _collection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => WishItem.fromFirestore(doc)).toList()
    );
  }

  Future<void> addWishItem(WishItem item) => _collection.add(item.toFirestore());

  Future<void> updateWishItem(WishItem item) => _collection.doc(item.id).update(item.toFirestore());

  Future<void> deleteWishItem(String id) => _collection.doc(id).delete();
}
