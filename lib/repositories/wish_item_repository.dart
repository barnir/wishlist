import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishlist_app/models/wish_item.dart';
import 'package:wishlist_app/models/sort_options.dart';
import 'package:wishlist_app/repositories/page.dart';
import 'package:wishlist_app/utils/app_logger.dart';

/// Repository providing typed access to wish items with cursor pagination.
class WishItemRepository {
  final FirebaseFirestore _firestore;
  WishItemRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Fetch a page of items for a wishlist using cursor pagination.
  Future<PageResult<WishItem>> fetchPage({
    required String wishlistId,
    int limit = 20,
    String? category,
    SortOptions? sortOptions,
    DocumentSnapshot? startAfter,
  }) async {
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
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _firestore.collection('wish_items').doc(itemId).delete();
      logI('WishItem deleted', tag: 'DB', data: {'itemId': itemId});
      return true;
    } catch (e) {
      logE('WishItem delete error', tag: 'DB', error: e, data: {'itemId': itemId});
      return false;
    }
  }
}
