import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mywishstash/models/wishlist.dart';
import 'package:mywishstash/repositories/page.dart';
import 'package:mywishstash/utils/app_logger.dart';

class WishlistRepository {
  final FirebaseFirestore _firestore;
  WishlistRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
      return r;
    } catch (e, st) {
      logE(
        'WishlistRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}',
        tag: 'DB',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetch a single wishlist by ID. Returns null if not found.
  Future<Wishlist?> fetchById(String id) async => _withLatency(
    'fetchById',
    () async {
      try {
        final doc = await _firestore.collection('wishlists').doc(id).get();
        if (!doc.exists) return null;
        return Wishlist.fromMap({'id': doc.id, ...doc.data()!});
      } catch (e) {
        logE('Wishlist fetchById error', tag: 'DB', error: e, data: {'id': id});
        return null;
      }
    },
  );

  Future<PageResult<Wishlist>> fetchUserWishlists({
    required String ownerId,
    int limit = 20,
    DocumentSnapshot? startAfter,
    String sortField = 'created_at',
    bool descending = true,
    bool? isPrivateFilter,
  }) async => _withLatency('fetchUserWishlists', () async {
    try {
      var query = _firestore
          .collection('wishlists')
          .where('owner_id', isEqualTo: ownerId);

      // Only add orderBy if not total_value or index expected. total_value might be missing initially.
      if (sortField != 'total_value') {
        query = query.orderBy(sortField, descending: descending);
      } else {
        // Fallback: order by created_at for pagination stability, then client sort.
        query = query.orderBy('created_at', descending: true);
      }

      if (isPrivateFilter != null) {
        query = query.where('is_private', isEqualTo: isPrivateFilter);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snap = await query.limit(limit).get();
      final docs = snap.docs;
      var items = docs
          .map((d) => Wishlist.fromMap({'id': d.id, ...d.data()}))
          .toList();

      // If ordering by a field that may not exist (e.g., total_value) fallback to client sort.
      if (sortField == 'total_value') {
        items.sort((a, b) => (a.totalValue ?? 0).compareTo(b.totalValue ?? 0));
        if (descending) items = items.reversed.toList();
      }
      final last = docs.isNotEmpty ? docs.last : null;
      final hasMore = docs.length == limit && last != null;
      logI(
        'Wishlist page loaded',
        tag: 'DB',
        data: {'ownerId': ownerId, 'count': items.length},
      );
      return PageResult(items: items, lastDoc: last, hasMore: hasMore);
    } catch (e) {
      logE(
        'Wishlist page load error',
        tag: 'DB',
        error: e,
        data: {'ownerId': ownerId},
      );
      return const PageResult(items: [], lastDoc: null, hasMore: false);
    }
  });

  Future<List<Wishlist>> fetchAllForOwner(String ownerId) async =>
      _withLatency('fetchAllForOwner', () async {
        try {
          final snapshot = await _firestore
              .collection('wishlists')
              .where('owner_id', isEqualTo: ownerId)
              .orderBy('created_at', descending: false)
              .get();
          return snapshot.docs
              .map((d) => Wishlist.fromMap({'id': d.id, ...d.data()}))
              .toList(growable: false);
        } catch (e, st) {
          logE(
            'Wishlist fetchAllForOwner error',
            tag: 'DB',
            error: e,
            stackTrace: st,
            data: {'ownerId': ownerId},
          );
          return <Wishlist>[];
        }
      });

  Future<String?> create({
    required String name,
    required String ownerId,
    bool isPrivate = false,
    String? imageUrl,
  }) async => _withLatency('create', () async {
    try {
      final doc = _firestore.collection('wishlists').doc();
      await doc.set({
        'name': name,
        'owner_id': ownerId,
        'is_private': isPrivate,
        'image_url': imageUrl,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e) {
      logE(
        'Wishlist create error',
        tag: 'DB',
        error: e,
        data: {'ownerId': ownerId},
      );
      return null;
    }
  });

  Future<String?> createFromBackup({
    required String ownerId,
    required String name,
    required bool isPrivate,
    DateTime? createdAt,
    String? imageUrl,
  }) async => _withLatency('createFromBackup', () async {
    try {
      final doc = _firestore.collection('wishlists').doc();
      await doc.set({
        'name': name,
        'owner_id': ownerId,
        'is_private': isPrivate,
        if (imageUrl != null) 'image_url': imageUrl,
        'created_at': createdAt != null
            ? Timestamp.fromDate(createdAt)
            : FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
      return doc.id;
    } catch (e, st) {
      logE(
        'Wishlist createFromBackup error',
        tag: 'DB',
        error: e,
        stackTrace: st,
        data: {'ownerId': ownerId},
      );
      return null;
    }
  });

  Future<bool> update(
    String id,
    Map<String, dynamic> data, {
    required String currentUserId,
  }) async => _withLatency('update', () async {
    try {
      // SECURITY: Verify ownership before allowing updates
      final wishlistDoc = await _firestore
          .collection('wishlists')
          .doc(id)
          .get();
      if (!wishlistDoc.exists) {
        logW(
          'SECURITY: Update attempt on non-existent wishlist',
          tag: 'SECURITY',
          data: {'id': id, 'userId': currentUserId},
        );
        return false;
      }

      final wishlistData = wishlistDoc.data()!;
      final ownerId = wishlistData['owner_id'] as String?;

      if (ownerId != currentUserId) {
        logW(
          'SECURITY: Unauthorized wishlist update attempt',
          tag: 'SECURITY',
          data: {'id': id, 'userId': currentUserId, 'ownerId': ownerId},
        );
        return false;
      }

      await wishlistDoc.reference.update({
        ...data,
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      logE(
        'Wishlist update error',
        tag: 'DB',
        error: e,
        data: {'id': id, 'userId': currentUserId},
      );
      return false;
    }
  });
}
