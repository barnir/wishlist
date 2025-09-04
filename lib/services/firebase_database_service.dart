import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mywishstash/services/cloudinary_service.dart';
import 'package:mywishstash/utils/app_logger.dart';

/// Firebase Firestore Database Service
/// Firebase Firestore database service - complete NoSQL integration
class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Simple in-memory cache for first page of wish_items queries to reduce reads on quick back/forth
  final Map<String, (List<Map<String, dynamic>> items, DocumentSnapshot? lastDoc)> _firstPageCache = {};
  final Map<String, DateTime> _firstPageCacheTime = {};
  static const Duration _firstPageTtl = Duration(seconds: 30);

  String _firstPageKey(String wishlistId, String? category, dynamic sortOption, int limit) =>
      [wishlistId, category ?? '_ALL_', sortOption.toString(), limit].join('|');

  /// Generate a temporary client-side ID (not yet persisted) –
  /// format: tmp_epochMillis_random4
  String generateTempId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final rand = (ms % 10000).toString().padLeft(4, '0');
    return 'tmp_${ms}_$rand';
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ============== USER METHODS ==============

  // Legacy user profile CRUD removed (migrated to UserProfileRepository)

  // ============== WISHLIST METHODS ==============

  /// Get user's wishlists
  Future<List<Map<String, dynamic>>> getUserWishlists(String userId) async {
    try {
      
      final querySnapshot = await _firestore
          .collection('wishlists')
          .where('owner_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      final wishlists = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      logI('Wishlists retrieved', tag: 'DB', data: {'userId': userId, 'count': wishlists.length});
      return wishlists;
    } catch (e) {
  logE('Error getting user wishlists', tag: 'DB', error: e, data: {'userId': userId});
      rethrow;
    }
  }

  /// Create wishlist
  Future<Map<String, dynamic>> createWishlist(Map<String, dynamic> wishlistData) async {
    try {
      logI('Creating wishlist', tag: 'DB');
      
      final docRef = _firestore.collection('wishlists').doc();
      
      final data = {
        ...wishlistData,
        'id': docRef.id,
        'owner_id': currentUserId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(data);
      
      // Return the created data
      final createdDoc = await docRef.get();
      final result = createdDoc.data()!;
      
  logI('Wishlist created', tag: 'DB', data: {'wishlistId': docRef.id});
      return result;
    } catch (e) {
  logE('Error creating wishlist', tag: 'DB', error: e);
      rethrow;
    }
  }

  /// Update wishlist
  Future<void> updateWishlist(String wishlistId, Map<String, dynamic> updates) async {
    try {
      logI('Updating wishlist', tag: 'DB', data: {'wishlistId': wishlistId});
      
      final data = {
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('wishlists').doc(wishlistId).update(data);
      
  logI('Wishlist updated', tag: 'DB', data: {'wishlistId': wishlistId});
    } catch (e) {
  logE('Error updating wishlist', tag: 'DB', error: e, data: {'wishlistId': wishlistId});
      rethrow;
    }
  }

  /// Delete wishlist
  Future<void> deleteWishlist(String wishlistId) async {
    try {
      logI('Deleting wishlist', tag: 'DB', data: {'wishlistId': wishlistId});
      
      // Get wishlist data for image cleanup
      final wishlistDoc = await _firestore.collection('wishlists').doc(wishlistId).get();
      final wishlistData = wishlistDoc.data();
      final wishlistImageUrl = wishlistData?['image_url'] as String?;
      
      // Get all wish items in this wishlist for image cleanup
      final itemsSnapshot = await _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId)
          .get();
      
      // Collect product image URLs for cleanup
      final productImageUrls = <String>[];
      final batch = _firestore.batch();
      
      for (final doc in itemsSnapshot.docs) {
        final itemData = doc.data();
        final imageUrl = itemData['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          productImageUrls.add(imageUrl);
        }
        batch.delete(doc.reference);
      }
      
      // Delete the wishlist itself
      batch.delete(_firestore.collection('wishlists').doc(wishlistId));
      
      await batch.commit();
      
      // Schedule cleanup of all images associated with this wishlist
      await _cloudinaryService.scheduleWishlistCleanup(wishlistId, productImageUrls);
      
      // If wishlist had a cover image, schedule its cleanup too
      if (wishlistImageUrl != null) {
        await _cloudinaryService.scheduleProductCleanup(wishlistImageUrl);
      }
      
  logI('Wishlist deleted', tag: 'DB', data: {'wishlistId': wishlistId, 'itemsImages': productImageUrls.length});
    } catch (e) {
  logE('Error deleting wishlist', tag: 'DB', error: e, data: {'wishlistId': wishlistId});
      rethrow;
    }
  }

  /// Get wishlist by ID
  Future<Map<String, dynamic>?> getWishlist(String wishlistId) async {
    try {
      
      final doc = await _firestore.collection('wishlists').doc(wishlistId).get();
      
      if (doc.exists) {
        final data = {
          'id': doc.id,
          ...doc.data()!,
        };
        logI('Wishlist retrieved', tag: 'DB', data: {'wishlistId': wishlistId});
        return data;
      } else {
        logW('Wishlist not found', tag: 'DB', data: {'wishlistId': wishlistId});
        return null;
      }
    } catch (e) {
      logE('Error getting wishlist', tag: 'DB', error: e, data: {'wishlistId': wishlistId});
      rethrow;
    }
  }

  // ============== WISH ITEM METHODS ==============

  /// Get wishlist items
  Future<List<Map<String, dynamic>>> getWishlistItems(String wishlistId) async {
    try {
      
      final querySnapshot = await _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId)
          .orderBy('created_at', descending: true)
          .get();
      
      final items = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
  logI('Wishlist items retrieved', tag: 'DB', data: {'wishlistId': wishlistId, 'count': items.length});
      return items;
    } catch (e) {
  logE('Error getting wishlist items', tag: 'DB', error: e, data: {'wishlistId': wishlistId});
      rethrow;
    }
  }

  /// Create wish item
  Future<Map<String, dynamic>> createWishItem(Map<String, dynamic> itemData) async {
    try {
      logI('Creating wish item', tag: 'DB');
      
      final docRef = _firestore.collection('wish_items').doc();
      
      final data = {
        ...itemData,
        'id': docRef.id,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(data);
      
      // Return the created data
      final createdDoc = await docRef.get();
      final result = createdDoc.data()!;
      
  logI('Wish item created', tag: 'DB', data: {'itemId': docRef.id});
      return result;
    } catch (e) {
  logE('Error creating wish item', tag: 'DB', error: e);
      rethrow;
    }
  }

  /// Update wish item
  Future<void> updateWishItem(String itemId, Map<String, dynamic> updates) async {
    try {
      logI('Updating wish item', tag: 'DB', data: {'itemId': itemId});
      
      final data = {
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('wish_items').doc(itemId).update(data);
      
  logI('Wish item updated', tag: 'DB', data: {'itemId': itemId});
    } catch (e) {
  logE('Error updating wish item', tag: 'DB', error: e, data: {'itemId': itemId});
      rethrow;
    }
  }

  /// Delete wish item
  Future<void> deleteWishItem(String itemId) async {
    try {
      logI('Deleting wish item', tag: 'DB', data: {'itemId': itemId});
      
      // Get item data for image cleanup before deleting
      final itemDoc = await _firestore.collection('wish_items').doc(itemId).get();
      if (itemDoc.exists) {
        final itemData = itemDoc.data()!;
        final imageUrl = itemData['image_url'] as String?;
        
        // Delete from Firestore
        await _firestore.collection('wish_items').doc(itemId).delete();
        
        // Schedule image cleanup if item had an image
        if (imageUrl != null && imageUrl.isNotEmpty) {
          await _cloudinaryService.scheduleProductCleanup(imageUrl);
        }
      } else {
        // Item doesn't exist
        logW('Wish item not found', tag: 'DB', data: {'itemId': itemId});
      }
      
      logI('Wish item deleted', tag: 'DB', data: {'itemId': itemId});
    } catch (e) {
      logE('Error deleting wish item', tag: 'DB', error: e, data: {'itemId': itemId});
      rethrow;
    }
  }

  // ============== WISH ITEM STATUS METHODS ==============

  /// Get wish item status
  Future<Map<String, dynamic>?> getWishItemStatus(String itemId, String userId) async {
    try {
      
      final querySnapshot = await _firestore
          .collection('wish_item_statuses')
          .where('wish_item_id', isEqualTo: itemId)
          .where('user_id', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = {
          'id': doc.id,
          ...doc.data(),
        };
        logI('Wish item status retrieved', tag: 'DB', data: {'itemId': itemId, 'userId': userId});
        return data;
      } else {
        logW('Wish item status not found', tag: 'DB', data: {'itemId': itemId, 'userId': userId});
        return null;
      }
    } catch (e) {
      logE('Error getting wish item status', tag: 'DB', error: e, data: {'itemId': itemId, 'userId': userId});
      rethrow;
    }
  }

  /// Set wish item status
  Future<void> setWishItemStatus(String itemId, String userId, Map<String, dynamic> statusData) async {
    try {
      logI('Setting wish item status', tag: 'DB', data: {'itemId': itemId, 'userId': userId});
      
      // Check if status already exists
      final existingStatus = await getWishItemStatus(itemId, userId);
      
      if (existingStatus != null) {
        // Update existing status
        await _firestore
            .collection('wish_item_statuses')
            .doc(existingStatus['id'])
            .update({
              ...statusData,
              'updated_at': FieldValue.serverTimestamp(),
            });
      } else {
        // Create new status
        final docRef = _firestore.collection('wish_item_statuses').doc();
        await docRef.set({
          'id': docRef.id,
          'wish_item_id': itemId,
          'user_id': userId,
          ...statusData,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }
      
  logI('Wish item status set', tag: 'DB', data: {'itemId': itemId, 'userId': userId});
    } catch (e) {
  logE('Error setting wish item status', tag: 'DB', error: e, data: {'itemId': itemId, 'userId': userId});
      rethrow;
    }
  }

  // ============== FRIENDS METHODS ==============

  /// Get user's friends
  Future<List<Map<String, dynamic>>> getUserFriends(String userId) async {
    try {
      
      final querySnapshot = await _firestore
          .collection('friendships')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      final friendIds = querySnapshot.docs.map((doc) => doc.data()['friend_id'] as String).toList();
      
      if (friendIds.isEmpty) {
  logI('No friends found', tag: 'DB', data: {'userId': userId});
        return [];
      }
      
      // Get friend profiles
      final friendsSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: friendIds)
          .get();
      
      final friends = friendsSnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
  logI('Friends retrieved', tag: 'DB', data: {'userId': userId, 'count': friends.length});
      return friends;
    } catch (e) {
  logE('Error getting user friends', tag: 'DB', error: e, data: {'userId': userId});
      rethrow;
    }
  }

  // ============== FAVORITES MANAGEMENT ==============

  /// Add a user to favorites
  Future<void> addFavorite(String favoriteUserId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');
      if (currentUserId == favoriteUserId) {
        throw Exception('Cannot favorite yourself');
      }

      // Check if target user exists and is public (direct doc fetch since legacy method removed)
      final targetSnap = await _firestore.collection('users').doc(favoriteUserId).get();
      if (!targetSnap.exists) {
        throw Exception('User not found');
      }
      final targetUser = targetSnap.data() ?? {};
      if (targetUser['is_private'] == true) {
        throw Exception('Cannot favorite private users');
      }

      // Add favorite
      await _firestore.collection('user_favorites').add({
        'user_id': currentUserId,
        'favorite_user_id': favoriteUserId,
        'created_at': FieldValue.serverTimestamp(),
      });

  logI('Added favorite', tag: 'FAVORITES', data: {'userId': currentUserId, 'favoriteUserId': favoriteUserId});
    } catch (e) {
  logE('Error adding favorite', tag: 'FAVORITES', error: e, data: {'favoriteUserId': favoriteUserId});
      rethrow;
    }
  }

  /// Remove a user from favorites
  Future<void> removeFavorite(String favoriteUserId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final query = await _firestore
          .collection('user_favorites')
          .where('user_id', isEqualTo: currentUserId)
          .where('favorite_user_id', isEqualTo: favoriteUserId)
          .get();

      for (final doc in query.docs) {
        await doc.reference.delete();
      }

  logI('Removed favorite', tag: 'FAVORITES', data: {'userId': currentUserId, 'favoriteUserId': favoriteUserId});
    } catch (e) {
  logE('Error removing favorite', tag: 'FAVORITES', error: e, data: {'favoriteUserId': favoriteUserId});
      rethrow;
    }
  }

  /// Check if a user is in favorites
  Future<bool> isFavorite(String userId) async {
    try {
      if (currentUserId == null) return false;

      final query = await _firestore
          .collection('user_favorites')
          .where('user_id', isEqualTo: currentUserId)
          .where('favorite_user_id', isEqualTo: userId)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      logE('Error checking favorite', tag: 'FAVORITES', error: e, data: {'userId': userId});
      return false;
    }
  }

  /// Get all favorites for current user with profile data
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      if (currentUserId == null) return [];

      final favoritesQuery = await _firestore
          .collection('user_favorites')
          .where('user_id', isEqualTo: currentUserId)
          .orderBy('created_at', descending: true)
          .get();

      final favoriteUserIds = favoritesQuery.docs
          .map((doc) => doc.data()['favorite_user_id'] as String)
          .toList();

      if (favoriteUserIds.isEmpty) return [];

      // Get user profiles for favorites
      final usersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: favoriteUserIds)
          .where('is_private', isEqualTo: false) // Only public profiles
          .get();

      final favorites = usersQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

  logI('Favorites retrieved', tag: 'FAVORITES', data: {'count': favorites.length});
      return favorites;
    } catch (e) {
  logE('Error getting favorites', tag: 'FAVORITES', error: e);
      return [];
    }
  }

  /// Get favorites with pagination
  Future<List<Map<String, dynamic>>> getFavoritesPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      if (currentUserId == null) return [];

      // Note: Firestore doesn't have direct offset, so we'll use a workaround
      final favoritesQuery = await _firestore
          .collection('user_favorites')
          .where('user_id', isEqualTo: currentUserId)
          .orderBy('created_at', descending: true)
          .limit(limit + offset)
          .get();

      final allFavorites = favoritesQuery.docs.skip(offset).take(limit);
      final favoriteUserIds = allFavorites
          .map((doc) => doc.data()['favorite_user_id'] as String)
          .toList();

      if (favoriteUserIds.isEmpty) return [];

      // Get user profiles for favorites
      final usersQuery = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: favoriteUserIds)
          .where('is_private', isEqualTo: false)
          .get();

      final favorites = usersQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

      return favorites;
    } catch (e) {
      logE('Error getting paginated favorites', tag: 'FAVORITES', error: e, data: {'limit': limit, 'offset': offset});
      return [];
    }
  }


  /// Find users by phone numbers (for contacts discovery)
  Future<List<Map<String, dynamic>>> findUsersByPhoneNumbers(List<String> phoneNumbers) async {
    try {
      if (phoneNumbers.isEmpty || currentUserId == null) return [];


      // Firestore 'in' queries are limited to 10 items, so we need to batch
      const batchSize = 10;
      final results = <Map<String, dynamic>>[];

      for (int i = 0; i < phoneNumbers.length; i += batchSize) {
        final batch = phoneNumbers.skip(i).take(batchSize).toList();
        
        final query = await _firestore
            .collection('users')
            .where('phone', whereIn: batch)
            .get();

        final batchResults = query.docs
            .where((doc) => doc.id != currentUserId) // Exclude current user
            .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
            .toList();

        results.addAll(batchResults);
      }

  logI('Users found by phone numbers', tag: 'SEARCH', data: {'count': results.length});
      return results;
    } catch (e) {
  logE('Error finding users by phone numbers', tag: 'SEARCH', error: e, data: {'phones': phoneNumbers.length});
      return [];
    }
  }

  /// Get public wishlists for a specific user
  Future<List<Map<String, dynamic>>> getPublicWishlistsForUser(String userId) async {
    try {
      final wishlistsQuery = await _firestore
          .collection('wishlists')
          .where('user_id', isEqualTo: userId)
          .where('is_public', isEqualTo: true)
          .orderBy('created_at', descending: true)
          .get();

      final wishlists = wishlistsQuery.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();

  logI('Public wishlists retrieved', tag: 'DB', data: {'userId': userId, 'count': wishlists.length});
      return wishlists;
    } catch (e) {
  logE('Error getting public wishlists', tag: 'DB', error: e, data: {'userId': userId});
      return [];
    }
  }

  // ============== METHOD ALIASES FOR COMPATIBILITY ==============

  /// Get wishlists for current user (alias for getUserWishlists)
  Future<List<Map<String, dynamic>>> getWishlistsForCurrentUser() async {
    if (currentUserId == null) return [];
    return await getUserWishlists(currentUserId!);
  }

  // Legacy stream alias methods (getWishlists/getWishItems) removed after full migration
  // to repository layer (WishlistRepository & WishItemRepository). This service now
  // retains only direct data operations still referenced elsewhere. New UI code
  // must use repositories for typed models and pagination.

  /// Get single wish item
  Future<Map<String, dynamic>?> getWishItem(String itemId) async {
    try {
      final doc = await _firestore.collection('wish_items').doc(itemId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error getting wish item: $e');
      return null;
    }
  }

  /// Save wishlist (create or update based on presence of id)
  Future<Map<String, dynamic>> saveWishlist(Map<String, dynamic> wishlistData) async {
    if (wishlistData.containsKey('id') && wishlistData['id'] != null) {
      // Update existing wishlist
      final id = wishlistData['id'] as String;
      final updates = Map<String, dynamic>.from(wishlistData)..remove('id');
      await updateWishlist(id, updates);
      return {'id': id, ...updates};
    } else {
      // Create new wishlist
      return await createWishlist(wishlistData);
    }
  }

  /// Save wish item (create or update based on presence of id)
  Future<Map<String, dynamic>> saveWishItem(Map<String, dynamic> itemData) async {
    if (itemData.containsKey('id') && itemData['id'] != null) {
      // Update existing item
      final id = itemData['id'] as String;
      final updates = Map<String, dynamic>.from(itemData)..remove('id');
      await updateWishItem(id, updates);
      return {'id': id, ...updates};
    } else {
      // Create new item
      return await createWishItem(itemData);
    }
  }

  /// Get wishlist items with pagination (Future version)
  Future<List<Map<String, dynamic>>> getWishItemsPaginatedFuture(
    String wishlistId, {
    int limit = 20,
    int offset = 0,
    String? category,
    dynamic sortOption,
  }) async {
    try {
      var query = _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId);

      // Apply category filter if provided
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      // Apply sorting based on SortOptions (fallback to created_at desc)
      // NOTE: Previously always ordered by created_at causing filter/sort UI mismatch.
      try {
        // Defensive: sortOption may come in as enum or something else.
        String orderField = 'name';
        bool descending = false;

        if (sortOption != null) {
          final optionName = sortOption.toString();
          if (optionName.contains('nameDesc')) {
            orderField = 'name';
            descending = true;
          } else if (optionName.contains('nameAsc')) {
            orderField = 'name';
            descending = false;
          } else if (optionName.contains('priceDesc')) {
            orderField = 'price';
            descending = true;
          } else if (optionName.contains('priceAsc')) {
            orderField = 'price';
            descending = false;
          }
        }

        query = query.orderBy(orderField, descending: descending);
      } catch (e) {
        // Fallback if any issue with dynamic ordering
        query = query.orderBy('created_at', descending: true);
      }

      // Apply pagination (note: Firestore doesn't have direct offset)
      query = query.limit(limit + offset);

      final snapshot = await query.get();
      
      final items = snapshot.docs
          .skip(offset)
          .take(limit)
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

  logI('Paginated wish items retrieved', tag: 'DB', data: {'wishlistId': wishlistId, 'count': items.length, 'limit': limit, 'offset': offset});
      return items;
    } catch (e) {
  logE('Error getting paginated wish items', tag: 'DB', error: e, data: {'wishlistId': wishlistId});
      return [];
    }
  }

  /// Optimized cursor-based pagination (preferred over offset workaround)
  Future<(List<Map<String, dynamic>> items, DocumentSnapshot? lastDoc)> getWishItemsPageCursor(
    String wishlistId, {
    int limit = 20,
    String? category,
    dynamic sortOption,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Serve from cache only for first page (no startAfter) if still fresh
      final cacheKey = _firstPageKey(wishlistId, category, sortOption, limit);
      if (startAfter == null && _firstPageCache.containsKey(cacheKey)) {
        final ts = _firstPageCacheTime[cacheKey];
        if (ts != null && DateTime.now().difference(ts) < _firstPageTtl) {
          return _firstPageCache[cacheKey]!;
        }
      }
      var query = _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId);

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      // Sorting (reuse logic)
      try {
        String orderField = 'name';
        bool descending = false;
        if (sortOption != null) {
          final optionName = sortOption.toString();
            if (optionName.contains('nameDesc')) {
              orderField = 'name'; descending = true; }
            else if (optionName.contains('nameAsc')) { orderField = 'name'; }
            else if (optionName.contains('priceDesc')) { orderField = 'price'; descending = true; }
            else if (optionName.contains('priceAsc')) { orderField = 'price'; }
        }
        query = query.orderBy(orderField, descending: descending).orderBy('created_at', descending: true);
      } catch (_) {
        query = query.orderBy('created_at', descending: true);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snap = await query.limit(limit).get();
      final docs = snap.docs;
      final items = docs.map((d) => {'id': d.id, ...d.data()}).toList();
      final last = docs.isNotEmpty ? docs.last : null;
      if (startAfter == null) {
        _firstPageCache[cacheKey] = (items, last);
        _firstPageCacheTime[cacheKey] = DateTime.now();
      }
      logI('Cursor page retrieved', tag: 'DB', data: {'wishlistId': wishlistId, 'count': items.length, 'cached': startAfter == null});
      return (items, last);
    } catch (e) {
      logE('Cursor pagination error', tag: 'DB', error: e, data: {'wishlistId': wishlistId});
      return (<Map<String, dynamic>>[], null);
    }
  }

  /// Get wishlists with pagination  
  Future<List<Map<String, dynamic>>> getWishlistsPaginated(
    String userId, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      // Note: Firestore doesn't have direct offset, using limit + offset workaround
    // Corrigido: usar 'owner_id' para filtrar wishlists do utilizador
    // Isto garante que o campo usado no fetch corresponde ao campo usado na criação
    final query = await _firestore
      .collection('wishlists')
      .where('owner_id', isEqualTo: userId) // <--- CORREÇÃO: era 'user_id', agora 'owner_id'
      .orderBy('created_at', descending: true)
      .limit(limit + offset)
      .get();

      final wishlists = query.docs
          .skip(offset)
          .take(limit)
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

  logI('Paginated wishlists retrieved', tag: 'DB', data: {'userId': userId, 'count': wishlists.length, 'limit': limit, 'offset': offset});
      return wishlists;
    } catch (e) {
  logE('Error getting paginated wishlists', tag: 'DB', error: e, data: {'userId': userId});
      return [];
    }
  }

  /// Delete wish item with wishlist ID (compatibility method)
  Future<void> deleteWishItemFromWishlist(String wishlistId, String itemId) async {
    // For compatibility, we ignore wishlistId and just delete by itemId
    try {
      await _firestore.collection('wish_items').doc(itemId).delete();
      logI('Deleted wish item (compat)', tag: 'DB', data: {'itemId': itemId});
    } catch (e) {
      logE('Error deleting wish item (compat)', tag: 'DB', error: e, data: {'itemId': itemId});
      rethrow;
    }
  }

  // ============== MONITORING AND ANALYTICS ==============

  /// Log analytics event
  Future<void> logAnalyticsEvent(String eventType, Map<String, dynamic> eventData) async {
    try {
      if (currentUserId == null) return;
      
      await _firestore.collection('analytics_events').add({
        'user_id': currentUserId,
        'event_type': eventType,
        'event_data': eventData,
        'created_at': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      logE('Error logging analytics event', tag: 'ANALYTICS', error: e, data: {'eventType': eventType});
      // Don't rethrow - analytics shouldn't break app functionality
    }
  }

  /// Get usage statistics
  Future<Map<String, dynamic>?> getUsageStats() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final doc = await _firestore.collection('_usage').doc(today).get();
      
      if (doc.exists) {
        return doc.data()!;
      } else {
        return {
          'reads': 0,
          'writes': 0,
          'functions': 0,
          'date': today,
        };
      }
    } catch (e) {
      logE('Error getting usage stats', tag: 'ANALYTICS', error: e);
      return null;
    }
  }
  
  /// Procura utilizadores registados na app usando números de telefone
  /// 
  /// Este método é essencial para a integração com contactos, permitindo identificar
  /// quais contactos do utilizador já estão a usar a aplicação.
  /// 
  /// Limitações e considerações:
  /// - Só retorna utilizadores com perfis públicos (is_private: false)
  /// - Retorna apenas dados essenciais e não sensíveis para proteger privacidade
  /// - Implementa batching para lidar com a limitação do Firestore (max 10 itens em whereIn)
  /// 
  /// Campos retornados:
  /// - id: ID do utilizador no Firebase
  /// - display_name: Nome público do utilizador
  /// - photo_url: URL da foto de perfil (já optimizada pelo Cloudinary)
  /// - phone_number: Número de telefone (apenas o que foi consultado)
  /// 
  /// @param phoneNumbers Lista de números de telefone formatados para pesquisa
  /// @return Lista de mapas com os dados básicos de cada utilizador encontrado
  Future<List<Map<String, dynamic>>> getUsersByPhoneNumbers(List<String> phoneNumbers) async {
    try {
      if (phoneNumbers.isEmpty) {
        return [];
      }
      
      
      // Firestore não suporta consultas IN com mais de 10 valores
      // Por isso, dividimos em batches de 10
      final results = <Map<String, dynamic>>[];
      const batchSize = 10;
      
      for (int i = 0; i < phoneNumbers.length; i += batchSize) {
        final batch = phoneNumbers.skip(i).take(batchSize).toList();
        
        final query = await _firestore
          .collection('users')
          .where('phone_number', whereIn: batch)
          .where('is_private', isEqualTo: false)
          .get();
          
        for (final doc in query.docs) {
          final data = doc.data();
          // Retornar apenas dados públicos essenciais
          results.add({
            'id': doc.id,
            'display_name': data['display_name'],
            'photo_url': data['photo_url'],
            'phone_number': data['phone_number'],
          });
        }
      }
      
  logI('Users found (phone lookup)', tag: 'SEARCH', data: {'count': results.length});
      return results;
    } catch (e) {
  logE('Error looking up users by phone numbers', tag: 'SEARCH', error: e, data: {'phones': phoneNumbers.length});
      return [];
    }
  }
}
