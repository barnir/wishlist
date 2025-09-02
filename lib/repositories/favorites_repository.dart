import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mywishstash/models/user_favorite.dart';
import 'package:mywishstash/repositories/page.dart';
import 'package:mywishstash/utils/app_logger.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Repository for favorites with cursor pagination returning enriched profile data.
class FavoritesRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  FavoritesRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
  logD('FavoritesRepository op=$op latency_ms=${sw.elapsedMilliseconds}', tag: 'DB');
      return r;
    } catch (e, st) {
  logE('FavoritesRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}', tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  String? get _currentUserId => _auth.currentUser?.uid;

  // ---------------------------------------------------------------------------
  // Basic operations (add, remove, check, list)
  // ---------------------------------------------------------------------------

  Future<void> add(String userId, String favoriteUserId) async => _withLatency('add', () async {
        if (userId == favoriteUserId) {
          throw Exception('Cannot favorite yourself');
        }

        // Ensure target user exists and is not private
        final targetDoc = await _firestore.collection('users').doc(favoriteUserId).get();
        if (!targetDoc.exists) {
          throw Exception('User not found');
        }
        final data = targetDoc.data();
        if (data == null || (data['is_private'] as bool? ?? false)) {
          throw Exception('Cannot favorite private users');
        }

        // Check if already favorited
        final existing = await _firestore
            .collection('user_favorites')
            .where('user_id', isEqualTo: userId)
            .where('favorite_user_id', isEqualTo: favoriteUserId)
            .limit(1)
            .get();
        if (existing.docs.isNotEmpty) {
          return; // idempotent
        }

        await _firestore.collection('user_favorites').add({
          'user_id': userId,
          'favorite_user_id': favoriteUserId,
          'created_at': FieldValue.serverTimestamp(),
        });
      });

  Future<void> remove(String userId, String favoriteUserId) async => _withLatency('remove', () async {
        final existing = await _firestore
            .collection('user_favorites')
            .where('user_id', isEqualTo: userId)
            .where('favorite_user_id', isEqualTo: favoriteUserId)
            .limit(1)
            .get();
        if (existing.docs.isEmpty) return; // nothing to remove
        await _firestore.collection('user_favorites').doc(existing.docs.first.id).delete();
      });

  Future<bool> isFavorite(String userId, String favoriteUserId) async => _withLatency('isFavorite', () async {
        final snap = await _firestore
            .collection('user_favorites')
            .where('user_id', isEqualTo: userId)
            .where('favorite_user_id', isEqualTo: favoriteUserId)
            .limit(1)
            .get();
        return snap.docs.isNotEmpty;
      });

  Future<List<String>> listIds(String userId) async => _withLatency('listIds', () async {
        final snap = await _firestore
            .collection('user_favorites')
            .where('user_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .get();
        return snap.docs
            .map((d) => d.data()['favorite_user_id'] as String?)
            .whereType<String>()
            .toList();
      });

  Future<PageResult<UserFavoriteWithProfile>> fetchPage({
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async => _withLatency('fetchPage', () async {
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
  });
}
