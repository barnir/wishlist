import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/utils/app_logger.dart';

class StatsRepository {
  final FirebaseFirestore _firestore;
  StatsRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
      logD('StatsRepository op=$op latency_ms=${sw.elapsedMilliseconds}', tag: 'DB');
      return r;
    } catch (e, st) {
      logE('StatsRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}', tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  Future<({int wishlists, int items, int shared})> loadUserStats(String userId) async => _withLatency('loadUserStats', () async {
    try {
    // Correct field name is owner_id (was user_id in legacy code)
    final wishlistsSnap = await _firestore
      .collection('wishlists')
      .where('owner_id', isEqualTo: userId)
      .get();
      final wishlists = wishlistsSnap.docs;
      int itemsCount = 0;
      int shared = 0;
      if (wishlists.isNotEmpty) {
        // Efficient aggregation: rely on optional item_count field if present to avoid N queries.
        // Fallback: count items with a lightweight aggregate query if item_count missing.
        final List<String> missingItemCount = [];
        for (final w in wishlists) {
          final data = w.data();
          final isPrivate = (data['is_private'] as bool?) ?? false;
          if (!isPrivate) shared++;
          final ic = (data['item_count'] as num?)?.toInt();
          if (ic != null) {
            itemsCount += ic;
          } else {
            missingItemCount.add(w.id);
          }
        }
        // Fallback counting for wishlists without pre-aggregated item_count (batched sequential). Could be optimized later.
        for (final wid in missingItemCount) {
          final cntSnap = await _firestore.collection('wish_items').where('wishlist_id', isEqualTo: wid).count().get();
          final c = (cntSnap.count ?? 0).toInt();
          itemsCount += c;
          // Optionally persist back item_count for future fast loads
          try {
            await _firestore.collection('wishlists').doc(wid).update({'item_count': cntSnap.count});
          } catch (_) {}
        }
      }
      return (wishlists: wishlists.length, items: itemsCount, shared: shared);
    } catch (e) {
      logE('StatsRepository loadUserStats error', tag: 'DB', error: e, data: {'userId': userId});
      return (wishlists: 0, items: 0, shared: 0);
    }
  });

  Stream<double> wishlistTotalStream(String wishlistId) async* {
    // Stream individual wishlist items and map to total price
    yield* _firestore
        .collection('wish_items')
        .where('wishlist_id', isEqualTo: wishlistId)
        .snapshots()
        .map((snap) {
          double total = 0;
          for (final d in snap.docs) {
            final price = (d.data()['price'] as num?)?.toDouble() ?? 0.0;
            total += price;
          }
          return total;
        });
  }
}
