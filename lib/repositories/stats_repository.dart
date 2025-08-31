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
      final wishlistsSnap = await _firestore
          .collection('wishlists')
          .where('user_id', isEqualTo: userId)
          .get();
      final wishlists = wishlistsSnap.docs;
      int itemsCount = 0;
      int shared = 0;
      if (wishlists.isNotEmpty) {
  // Iterate wishlists and aggregate counts
        for (final w in wishlists) {
          if ((w.data()['is_public'] as bool?) == true) shared++;
          final itemsSnap = await _firestore
              .collection('wish_items')
              .where('wishlist_id', isEqualTo: w.id)
              .get();
          itemsCount += itemsSnap.size;
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
