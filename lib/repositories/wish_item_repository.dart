import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/models/wish_item.dart';
import 'package:wishlist_app/models/sort_options.dart';
import 'package:wishlist_app/repositories/page.dart';
import 'package:wishlist_app/utils/app_logger.dart';

/// Repository providing typed access to wish items with cursor pagination.
class WishItemRepository {
  final FirebaseFirestore _firestore;
  WishItemRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
  logD('WishItemRepository op=$op latency_ms=${sw.elapsedMilliseconds}', tag: 'DB');
      return r;
    } catch (e, st) {
  logE('WishItemRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}', tag: 'DB', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Fetch a page of items for a wishlist using cursor pagination.
  Future<PageResult<WishItem>> fetchPage({
    required String wishlistId,
    int limit = 20,
    String? category,
    SortOptions? sortOptions,
    DocumentSnapshot? startAfter,
  }) async => _withLatency('fetchPage', () async {
    try {
      var query = _firestore.collection('wish_items').where('wishlist_id', isEqualTo: wishlistId);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Determine order field from SortOptions
      String orderField = 'name';
      bool descending = false;
      if (sortOptions != null) {
        switch (sortOptions) {
          case SortOptions.nameAsc:
            orderField = 'name'; descending = false; break;
          case SortOptions.nameDesc:
            orderField = 'name'; descending = true; break;
          case SortOptions.priceAsc:
            orderField = 'price'; descending = false; break;
          case SortOptions.priceDesc:
            orderField = 'price'; descending = true; break;
        }
      }

      // Primary sort then tie-breaker by created_at for deterministic order.
      query = query.orderBy(orderField, descending: descending).orderBy('created_at', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snap = await query.limit(limit).get();
      final docs = snap.docs;
      final items = docs.map((d) => WishItem.fromMap({'id': d.id, ...d.data()})).toList();
      final last = docs.isNotEmpty ? docs.last : null;
      final hasMore = docs.length == limit && last != null;
      logI('WishItem page loaded', tag: 'DB', data: {'wishlistId': wishlistId, 'count': items.length, 'hasMore': hasMore});
      return PageResult(items: items, lastDoc: last, hasMore: hasMore);
    } catch (e) {
      logE('WishItem page load error', tag: 'DB', error: e, data: {'wishlistId': wishlistId});
      return const PageResult(items: [], lastDoc: null, hasMore: false);
    }
  });

  Future<bool> deleteItem(String itemId) async => _withLatency('deleteItem', () async {
        try {
          await _firestore.collection('wish_items').doc(itemId).delete();
          logI('WishItem deleted', tag: 'DB', data: {'itemId': itemId});
          return true;
        } catch (e) {
          logE('WishItem delete error', tag: 'DB', error: e, data: {'itemId': itemId});
          return false;
        }
      });

  Future<String?> create(Map<String, dynamic> data) async => _withLatency('create', () async {
        try {
          final doc = _firestore.collection('wish_items').doc();
          await doc.set({
            ...data,
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          return doc.id;
        } catch (e) {
          logE('WishItem create error', tag: 'DB', error: e, data: {'data': data});
          return null;
        }
      });

  Future<bool> update(String id, Map<String, dynamic> data) async => _withLatency('update', () async {
        try {
          await _firestore.collection('wish_items').doc(id).update({
            ...data,
            'updated_at': FieldValue.serverTimestamp(),
          });
          return true;
        } catch (e) {
          logE('WishItem update error', tag: 'DB', error: e, data: {'itemId': id});
          return false;
        }
      });

  Future<WishItem?> fetchById(String id) async => _withLatency('fetchById', () async {
        try {
          final doc = await _firestore.collection('wish_items').doc(id).get();
          if (!doc.exists) return null;
            return WishItem.fromMap({'id': doc.id, ...doc.data()!});
        } catch (e) {
          logE('WishItem fetch error', tag: 'DB', error: e, data: {'itemId': id});
          return null;
        }
      });
}
