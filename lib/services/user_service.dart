import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  Future<DocumentSnapshot> getUserProfile(String userId) {
    return _firestore.collection(_collectionName).doc(userId).get();
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) {
    return _firestore.collection(_collectionName).doc(userId).update(data);
  }

  Future<List<QueryDocumentSnapshot>> searchFriendsByContacts(List<String> phoneNumbers) async {
    final List<QueryDocumentSnapshot> friends = [];
    const batchSize = 10;

    for (var i = 0; i < phoneNumbers.length; i += batchSize) {
      final batch = phoneNumbers.skip(i).take(batchSize).toList();
      final query = await _firestore
          .collection(_collectionName)
          .where('phoneNumber', whereIn: batch)
          .get();
      friends.addAll(query.docs);
    }
    return friends;
  }

  Future<void> addFriend(String userId, String friendId, String friendName) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .set({
      'name': friendName,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteUserData(String userId) async {
    await _firestore.collection(_collectionName).doc(userId).delete();
    final userWishlists = await _firestore
        .collection('wishlists')
        .where('ownerId', isEqualTo: userId)
        .get();
    for (final wishlistDoc in userWishlists.docs) {
      final items = await wishlistDoc.reference.collection('items').get();
      for (final itemDoc in items.docs) {
        await itemDoc.reference.delete();
      }
      await wishlistDoc.reference.delete();
    }
  }
}
