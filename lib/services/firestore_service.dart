import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wish_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _wishlistCollection = 'wishlist';

  // Captura a coleção
  CollectionReference get _collection => _firestore.collection(_wishlistCollection);

  Stream<List<WishItem>> streamWishlist() {
    return _collection.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => WishItem.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList()
    );
  }

  Future<void> addWishItem(WishItem item) => _collection.add(item.toMap());

  Future<void> updateWishItem(WishItem item) => _collection.doc(item.id).update(item.toMap());

  Future<void> deleteWishItem(String id) => _collection.doc(id).delete();
}
