import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/models/user_favorite.dart';
import 'package:wishlist_app/repositories/page.dart';
import 'package:wishlist_app/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository for favorites with cursor pagination returning enriched profile data.
class FavoritesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  FavoritesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  Future<PageResult<UserFavoriteWithProfile>> fetchPage({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async {
    if (_currentUserId == null) {
      return const PageResult(items: [], lastDoc: null, hasMore: false);
    }
    try {
      var query = _firestore
          .collection('user_favorites')
          .where('user_id', isEqualTo: _currentUserId)
          .orderBy('created_at', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snap = await query.limit(limit).get();
      final favDocs = snap.docs;
      if (favDocs.isEmpty) {
        return const PageResult(items: [], lastDoc: null, hasMore: false);
      }

      // Collect user IDs and batch fetch profiles (respect whereIn 10 limit)
      final userIds = favDocs.map((d) => d.data()['favorite_user_id'] as String).toList();
      final profileMaps = <String, Map<String, dynamic>>{};
      const batchSize = 10;
      for (int i = 0; i < userIds.length; i += batchSize) {
        final slice = userIds.skip(i).take(batchSize).toList();
        final usersSnap = await _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: slice)
            .where('is_private', isEqualTo: false)
            .get();
        for (final doc in usersSnap.docs) {
          profileMaps[doc.id] = {'id': doc.id, ...doc.data()};
        }
      }

      final enriched = <UserFavoriteWithProfile>[];
      for (final fav in favDocs) {
        final data = fav.data();
        final profile = profileMaps[data['favorite_user_id']];
        if (profile == null) continue; // skip private or missing
        enriched.add(UserFavoriteWithProfile.fromMap({
          'id': fav.id,
          ...data,
          'display_name': profile['display_name'],
          'phone_number': profile['phone_number'],
          'is_private': profile['is_private'],
          'email': profile['email'],
          'bio': profile['bio'],
        }));
      }

      final last = favDocs.isNotEmpty ? favDocs.last : null;
      final hasMore = favDocs.length == limit && last != null;
      logI('Favorites page loaded', tag: 'FAVORITES', data: {'count': enriched.length, 'hasMore': hasMore});
      return PageResult(items: enriched, lastDoc: last, hasMore: hasMore);
    } catch (e) {
      logE('Favorites page load error', tag: 'FAVORITES', error: e, data: {'limit': limit});
      return const PageResult(items: [], lastDoc: null, hasMore: false);
    }
  }
}
