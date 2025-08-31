import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishlist_app/models/user_profile.dart';
import 'package:wishlist_app/utils/app_logger.dart';

/// Repository encapsulating CRUD for user profiles.
class UserProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  UserProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<UserProfile?> fetchById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserProfile.fromMap({'id': doc.id, ...doc.data()!});
    } catch (e) {
      logE('UserProfile fetch error', tag: 'DB', error: e, data: {'userId': userId});
      return null;
    }
  }

  Future<UserProfile?> fetchCurrent() async {
    final id = currentUserId;
    if (id == null) return null;
    return fetchById(id);
  }

  Future<UserProfile?> create(String userId, Map<String, dynamic> profileData) async {
    try {
      final ref = _firestore.collection('users').doc(userId);
      final data = {
        ...profileData,
        'id': userId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      await ref.set(data);
      final snap = await ref.get();
      logI('UserProfile created', tag: 'DB', data: {'userId': userId});
      return UserProfile.fromMap({'id': snap.id, ...snap.data()!});
    } catch (e) {
      logE('UserProfile create error', tag: 'DB', error: e, data: {'userId': userId});
      return null;
    }
  }

  Future<bool> update(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      });
      logI('UserProfile updated', tag: 'DB', data: {'userId': userId});
      return true;
    } catch (e) {
      logE('UserProfile update error', tag: 'DB', error: e, data: {'userId': userId});
      return false;
    }
  }

  Future<bool> delete(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      logI('UserProfile deleted', tag: 'DB', data: {'userId': userId});
      return true;
    } catch (e) {
      logE('UserProfile delete error', tag: 'DB', error: e, data: {'userId': userId});
      return false;
    }
  }
}
