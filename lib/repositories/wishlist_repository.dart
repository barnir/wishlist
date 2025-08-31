import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/models/wishlist.dart';
import 'package:wishlist_app/repositories/page.dart';
import 'package:wishlist_app/utils/app_logger.dart';

class WishlistRepository {
  final FirebaseFirestore _firestore;
  WishlistRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
  logD('WishlistRepository op=$op latency_ms=${sw.elapsedMilliseconds}', tag: 'DB');
      return r;
    } catch (e, st) {
  logE('WishlistRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}', tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetch a single wishlist by ID. Returns null if not found.
  Future<Wishlist?> fetchById(String id) async => _withLatency('fetchById', () async {
        try {
          final doc = await _firestore.collection('wishlists').doc(id).get();
          if (!doc.exists) return null;
          return Wishlist.fromMap({'id': doc.id, ...doc.data()!});
        } catch (e) {
          logE('Wishlist fetchById error', tag: 'DB', error: e, data: {'id': id});
          return null;
        }
      });

  Future<PageResult<Wishlist>> fetchUserWishlists({
    required String ownerId,
    int limit = 20,
    DocumentSnapshot? startAfter,
  }) async => _withLatency('fetchUserWishlists', () async {
    try {
      var query = _firestore
          .collection('wishlists')
          .where('owner_id', isEqualTo: ownerId)
          .orderBy('created_at', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snap = await query.limit(limit).get();
      final docs = snap.docs;
      final items = docs.map((d) => Wishlist.fromMap({'id': d.id, ...d.data()})).toList();
      final last = docs.isNotEmpty ? docs.last : null;
      final hasMore = docs.length == limit && last != null;
      logI('Wishlist page loaded', tag: 'DB', data: {'ownerId': ownerId, 'count': items.length});
      return PageResult(items: items, lastDoc: last, hasMore: hasMore);
    } catch (e) {
      logE('Wishlist page load error', tag: 'DB', error: e, data: {'ownerId': ownerId});
      return const PageResult(items: [], lastDoc: null, hasMore: false);
    }
  });
}
