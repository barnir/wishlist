import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    hide Category; // Avoid clash with our domain Category
import 'package:mywishstash/models/wish_item.dart';
import 'package:mywishstash/models/category.dart';
import 'package:mywishstash/models/sort_options.dart';
import 'package:mywishstash/repositories/page.dart';
import 'package:mywishstash/utils/app_logger.dart';

/// Repository providing typed access to wish items with cursor pagination.
class WishItemRepository {
  final FirebaseFirestore _firestore;
  WishItemRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Executa até três tentativas hierárquicas capturando FirebaseException code=failed-precondition.
  /// Usado para fallback de índices (composite → single → simple). Testável isoladamente.
  @visibleForTesting
  static Future<T> runWithFirestoreFallback<T>({
    required Future<T> Function() primary,
    required Future<T> Function() firstFallback,
    required Future<T> Function() secondFallback,
    void Function()? onPrimaryFailed,
    void Function()? onFirstFallbackFailed,
  }) async {
    try {
      return await primary();
    } on FirebaseException catch (fe) {
      if (fe.code != 'failed-precondition') rethrow;
      onPrimaryFailed?.call();
      try {
        return await firstFallback();
      } on FirebaseException catch (fe2) {
        if (fe2.code != 'failed-precondition') rethrow;
        onFirstFallbackFailed?.call();
        return await secondFallback();
      }
    }
  }

  Future<T> _withLatency<T>(String op, Future<T> Function() fn) async {
    final sw = Stopwatch()..start();
    try {
      final r = await fn();
      return r;
    } catch (e, st) {
      logE(
        'WishItemRepository op=$op failed latency_ms=${sw.elapsedMilliseconds}',
        tag: 'DB',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Fetch a page of items for a wishlist using cursor pagination.

  Future<List<WishItem>> fetchAllForWishlist(String wishlistId) async =>
      _withLatency('fetchAllForWishlist', () async {
        try {
          final snapshot = await _firestore
              .collection('wish_items')
              .where('wishlist_id', isEqualTo: wishlistId)
              .orderBy('created_at', descending: false)
              .get();
          return snapshot.docs
              .map((d) => WishItem.fromMap({'id': d.id, ...d.data()}))
              .toList(growable: false);
        } catch (e, st) {
          logE(
            'WishItem fetchAllForWishlist error',
            tag: 'DB',
            error: e,
            stackTrace: st,
            data: {'wishlistId': wishlistId},
          );
          return <WishItem>[];
        }
      });

  Future<PageResult<WishItem>> fetchPage({
    required String wishlistId,
    int limit = 20,
    String? category,
    SortOptions? sortOptions,
    DocumentSnapshot? startAfter,
  }) async => _withLatency('fetchPage', () async {
    try {
      var baseQuery = _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId);

      // Legacy support: if first page & no startAfter we will later optionally try 'wishlistId' field name.

      if (category != null && category.isNotEmpty) {
        // Expand to possible legacy stored variants (alias vs new label)
        final candidates = Category.storageCandidates(category);
        if (candidates.length == 1) {
          baseQuery = baseQuery.where('category', isEqualTo: candidates.first);
        } else if (candidates.isNotEmpty) {
          // Firestore whereIn max 10; our list is tiny (<=3)
          baseQuery = baseQuery.where(
            'category',
            whereIn: candidates.take(10).toList(),
          );
        }
      }

      // Determine order field from SortOptions
      String orderField = 'name';
      bool descending = false;
      if (sortOptions != null) {
        switch (sortOptions) {
          case SortOptions.nameAsc:
            orderField = 'name';
            descending = false;
            break;
          case SortOptions.nameDesc:
            orderField = 'name';
            descending = true;
            break;
          case SortOptions.priceAsc:
            orderField = 'price';
            descending = false;
            break;
          case SortOptions.priceDesc:
            orderField = 'price';
            descending = true;
            break;
        }
      }

      Query queryWithOrdering = baseQuery
          .orderBy(orderField, descending: descending)
          .orderBy('created_at', descending: true);
      if (startAfter != null) {
        queryWithOrdering = queryWithOrdering.startAfterDocument(startAfter);
      }

      final QuerySnapshot
      snap = await WishItemRepository.runWithFirestoreFallback<QuerySnapshot>(
        primary: () => queryWithOrdering.limit(limit).get(),
        firstFallback: () async {
          logW(
            'Missing Firestore composite index for wish_items. Falling back to single order.',
            tag: 'DB',
            data: {
              'wishlistId': wishlistId,
              'orderField': orderField,
              'categoryFilter': category,
              'hint':
                  'Add composite index: wishlist_id + category(optional) orderBy $orderField & created_at',
            },
          );
          var fallbackQuery = baseQuery.orderBy(
            orderField,
            descending: descending,
          );
          if (startAfter != null) {
            fallbackQuery = fallbackQuery.startAfterDocument(startAfter);
          }
          return fallbackQuery.limit(limit).get();
        },
        secondFallback: () async {
          logW(
            'Second-level index fallback (no orderBy) engaged',
            tag: 'DB',
            data: {
              'wishlistId': wishlistId,
              'orderField': orderField,
              'categoryFilter': category,
            },
          );
          var simpleFallback = baseQuery;
          if (startAfter != null) {
            logW('Ignoring startAfter due to no-order fallback', tag: 'DB');
          }
          return simpleFallback.limit(limit).get();
        },
        onPrimaryFailed: () {},
        onFirstFallbackFailed: () {},
      );

      var docs = snap.docs;
      var items = docs.map((d) {
        final raw = d.data() as Map<String, dynamic>;
        return WishItem.fromMap({'id': d.id, ...raw});
      }).toList();

      // If we had to remove ordering due to missing composite index, sort client-side for basic UX consistency.
      if (items.isNotEmpty && ((items.length < limit) || true)) {
        // Apply deterministic sort based on requested orderField (if we ended with no-order fallback)
        // We can't know definitively which fallback path we took without extra state; cheap heuristic: if items > 1 and
        // created_at ordering might not be present. We'll still sort to be safe.
        try {
          if (orderField == 'name') {
            items.sort(
              (a, b) => descending
                  ? b.name.compareTo(a.name)
                  : a.name.compareTo(b.name),
            );
          } else if (orderField == 'price') {
            items.sort((a, b) => (a.price ?? 0).compareTo(b.price ?? 0));
            if (descending) items = items.reversed.toList();
          }
        } catch (_) {}
      }

      // Diagnostic fallback: if first page returned empty, attempt simplified / legacy field queries
      if (items.isEmpty && startAfter == null) {
        logW(
          'Primary query returned 0 items. Running diagnostic fallback queries.',
          tag: 'DB',
          data: {
            'wishlistId': wishlistId,
            'categoryFilter': category,
            'orderField': orderField,
            'descending': descending,
          },
        );

        // 1) Simple query without ordering (just to see raw docs)
        try {
          final simple = await _firestore
              .collection('wish_items')
              .where('wishlist_id', isEqualTo: wishlistId)
              .limit(5)
              .get();
          if (simple.docs.isNotEmpty) {
            docs = simple.docs;
            items = docs
                .map(
                  (d) => WishItem.fromMap({
                    'id': d.id,
                    ...d.data() as Map<String, dynamic>,
                  }),
                )
                .toList();
          }
        } catch (e) {
          logE('DIAG simple query error', tag: 'DB', error: e);
        }

        // 2) Legacy field name 'wishlistId'
        if (items.isEmpty) {
          try {
            final legacy = await _firestore
                .collection('wish_items')
                .where('wishlistId', isEqualTo: wishlistId)
                .limit(5)
                .get();
            if (legacy.docs.isNotEmpty) {
              docs = legacy.docs;
              items = docs
                  .map(
                    (d) => WishItem.fromMap({
                      'id': d.id,
                      ...d.data() as Map<String, dynamic>,
                    }),
                  )
                  .toList();
            }
          } catch (e) {
            logE('DIAG legacy query error', tag: 'DB', error: e);
          }
        }
      }
      final last = docs.isNotEmpty ? docs.last : null;
      final hasMore = docs.length == limit && last != null;
      logI(
        'WishItem page loaded',
        tag: 'DB',
        data: {
          'wishlistId': wishlistId,
          'count': items.length,
          'hasMore': hasMore,
        },
      );
      return PageResult(items: items, lastDoc: last, hasMore: hasMore);
    } catch (e) {
      logE(
        'WishItem page load error',
        tag: 'DB',
        error: e,
        data: {'wishlistId': wishlistId},
      );
      return const PageResult(items: [], lastDoc: null, hasMore: false);
    }
  });

  Future<bool> deleteItem(String itemId) async =>
      _withLatency('deleteItem', () async {
        try {
          await _firestore.collection('wish_items').doc(itemId).delete();
          logI('WishItem deleted', tag: 'DB', data: {'itemId': itemId});
          return true;
        } catch (e) {
          logE(
            'WishItem delete error',
            tag: 'DB',
            error: e,
            data: {'itemId': itemId},
          );
          return false;
        }
      });

  Future<String?> create(Map<String, dynamic> data) async =>
      _withLatency('create', () async {
        try {
          final doc = _firestore.collection('wish_items').doc();
          await doc.set({
            ...data,
            if (!data.containsKey('owner_id'))
              'owner_id': data['owner_id'] ?? data['user_id'] ?? 'UNKNOWN',
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          });
          return doc.id;
        } catch (e) {
          logE(
            'WishItem create error',
            tag: 'DB',
            error: e,
            data: {'data': data},
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
      // SECURITY: Verify ownership before allowing updates by checking wishlist ownership
      final itemDoc = await _firestore.collection('wish_items').doc(id).get();
      if (!itemDoc.exists) {
        logW(
          'SECURITY: Update attempt on non-existent item',
          tag: 'SECURITY',
          data: {'id': id, 'userId': currentUserId},
        );
        return false;
      }

      final itemData = itemDoc.data()!;
      final wishlistId = itemData['wishlist_id'] as String?;

      if (wishlistId == null) {
        logW(
          'SECURITY: Item without wishlist_id cannot be updated',
          tag: 'SECURITY',
          data: {'id': id, 'userId': currentUserId},
        );
        return false;
      }

      // Check if user owns the wishlist that contains this item
      final wishlistDoc = await _firestore
          .collection('wishlists')
          .doc(wishlistId)
          .get();
      if (!wishlistDoc.exists) {
        logW(
          'SECURITY: Update attempt on item from non-existent wishlist',
          tag: 'SECURITY',
          data: {'id': id, 'wishlistId': wishlistId, 'userId': currentUserId},
        );
        return false;
      }

      final wishlistData = wishlistDoc.data()!;
      final wishlistOwnerId = wishlistData['owner_id'] as String?;

      if (wishlistOwnerId != currentUserId) {
        logW(
          'SECURITY: Unauthorized item update attempt',
          tag: 'SECURITY',
          data: {
            'id': id,
            'wishlistId': wishlistId,
            'userId': currentUserId,
            'ownerId': wishlistOwnerId,
          },
        );
        return false;
      }

      await itemDoc.reference.update({
        ...data,
        if (!data.containsKey('owner_id'))
          'owner_id': data['owner_id'] ?? data['user_id'] ?? 'UNKNOWN',
        'updated_at': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      logE(
        'WishItem update error',
        tag: 'DB',
        error: e,
        data: {'itemId': id, 'userId': currentUserId},
      );
      return false;
    }
  });

  Future<String?> createFromBackup({
    required String wishlistId,
    required String ownerId,
    required WishItem item,
  }) async => _withLatency('createFromBackup', () async {
    try {
      final doc = _firestore.collection('wish_items').doc();
      final payload = item.toMap();
      payload.remove('id');
      payload.remove('image_url');
      final data = {
        ...payload,
        'wishlist_id': wishlistId,
        'owner_id': ownerId,
        'legacy_id': item.id,
        'image_url': null,
        'created_at': Timestamp.fromDate(item.createdAt),
        'updated_at': FieldValue.serverTimestamp(),
      };
      // If item has a link but no image, mark enrichment as pending for UI feedback
      final hasLink = (item.link != null && item.link!.trim().isNotEmpty);
      final hasImage =
          (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty);
      if (hasLink && !hasImage) {
        data['enrich_status'] = 'pending';
      }
      await doc.set(data);
      return doc.id;
    } catch (e, st) {
      logE(
        'WishItem createFromBackup error',
        tag: 'DB',
        error: e,
        stackTrace: st,
        data: {'wishlistId': wishlistId},
      );
      return null;
    }
  });

  Future<WishItem?> fetchById(String id) async => _withLatency(
    'fetchById',
    () async {
      try {
        final doc = await _firestore.collection('wish_items').doc(id).get();
        if (!doc.exists) return null;
        return WishItem.fromMap({'id': doc.id, ...doc.data()!});
      } catch (e) {
        logE('WishItem fetch error', tag: 'DB', error: e, data: {'itemId': id});
        return null;
      }
    },
  );
}
