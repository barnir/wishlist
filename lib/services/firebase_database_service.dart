import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firebase Firestore Database Service
/// Firebase Firestore database service - complete NoSQL integration
class FirebaseDatabaseService {
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._internal();
  factory FirebaseDatabaseService() => _instance;
  FirebaseDatabaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // ============== USER METHODS ==============

  /// Create user profile
  Future<Map<String, dynamic>> createUserProfile(String userId, Map<String, dynamic> profileData) async {
    try {
      debugPrint('🔥 Creating user profile in Firestore: $userId');
      
      final docRef = _firestore.collection('users').doc(userId);
      
      final data = {
        ...profileData,
        'id': userId,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(data);
      
      // Return the created data with server timestamp
      final createdDoc = await docRef.get();
      final result = createdDoc.data()!;
      
      debugPrint('✅ User profile created successfully');
      return result;
    } catch (e) {
      debugPrint('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      debugPrint('🔥 Getting user profile from Firestore: $userId');
      
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        debugPrint('✅ User profile retrieved successfully');
        return data;
      } else {
        debugPrint('⚠️ User profile not found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔥 Updating user profile in Firestore: $userId');
      
      final data = {
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('users').doc(userId).update(data);
      
      debugPrint('✅ User profile updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete user profile
  Future<void> deleteUserProfile(String userId) async {
    try {
      debugPrint('🔥 Deleting user profile from Firestore: $userId');
      
      await _firestore.collection('users').doc(userId).delete();
      
      debugPrint('✅ User profile deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting user profile: $e');
      rethrow;
    }
  }

  // ============== WISHLIST METHODS ==============

  /// Get user's wishlists
  Future<List<Map<String, dynamic>>> getUserWishlists(String userId) async {
    try {
      debugPrint('🔥 Getting user wishlists from Firestore: $userId');
      
      final querySnapshot = await _firestore
          .collection('wishlists')
          .where('owner_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();
      
      final wishlists = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('✅ Retrieved ${wishlists.length} wishlists');
      return wishlists;
    } catch (e) {
      debugPrint('❌ Error getting user wishlists: $e');
      rethrow;
    }
  }

  /// Create wishlist
  Future<Map<String, dynamic>> createWishlist(Map<String, dynamic> wishlistData) async {
    try {
      debugPrint('🔥 Creating wishlist in Firestore');
      
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
      
      debugPrint('✅ Wishlist created successfully: ${docRef.id}');
      return result;
    } catch (e) {
      debugPrint('❌ Error creating wishlist: $e');
      rethrow;
    }
  }

  /// Update wishlist
  Future<void> updateWishlist(String wishlistId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔥 Updating wishlist in Firestore: $wishlistId');
      
      final data = {
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('wishlists').doc(wishlistId).update(data);
      
      debugPrint('✅ Wishlist updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating wishlist: $e');
      rethrow;
    }
  }

  /// Delete wishlist
  Future<void> deleteWishlist(String wishlistId) async {
    try {
      debugPrint('🔥 Deleting wishlist from Firestore: $wishlistId');
      
      // First delete all wish items in this wishlist
      final itemsSnapshot = await _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId)
          .get();
      
      final batch = _firestore.batch();
      
      for (final doc in itemsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      
      // Delete the wishlist itself
      batch.delete(_firestore.collection('wishlists').doc(wishlistId));
      
      await batch.commit();
      
      debugPrint('✅ Wishlist and all items deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting wishlist: $e');
      rethrow;
    }
  }

  /// Get wishlist by ID
  Future<Map<String, dynamic>?> getWishlist(String wishlistId) async {
    try {
      debugPrint('🔥 Getting wishlist from Firestore: $wishlistId');
      
      final doc = await _firestore.collection('wishlists').doc(wishlistId).get();
      
      if (doc.exists) {
        final data = {
          'id': doc.id,
          ...doc.data()!,
        };
        debugPrint('✅ Wishlist retrieved successfully');
        return data;
      } else {
        debugPrint('⚠️ Wishlist not found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting wishlist: $e');
      rethrow;
    }
  }

  // ============== WISH ITEM METHODS ==============

  /// Get wishlist items
  Future<List<Map<String, dynamic>>> getWishlistItems(String wishlistId) async {
    try {
      debugPrint('🔥 Getting wishlist items from Firestore: $wishlistId');
      
      final querySnapshot = await _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId)
          .orderBy('created_at', descending: true)
          .get();
      
      final items = querySnapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('✅ Retrieved ${items.length} wishlist items');
      return items;
    } catch (e) {
      debugPrint('❌ Error getting wishlist items: $e');
      rethrow;
    }
  }

  /// Create wish item
  Future<Map<String, dynamic>> createWishItem(Map<String, dynamic> itemData) async {
    try {
      debugPrint('🔥 Creating wish item in Firestore');
      
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
      
      debugPrint('✅ Wish item created successfully: ${docRef.id}');
      return result;
    } catch (e) {
      debugPrint('❌ Error creating wish item: $e');
      rethrow;
    }
  }

  /// Update wish item
  Future<void> updateWishItem(String itemId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔥 Updating wish item in Firestore: $itemId');
      
      final data = {
        ...updates,
        'updated_at': FieldValue.serverTimestamp(),
      };
      
      await _firestore.collection('wish_items').doc(itemId).update(data);
      
      debugPrint('✅ Wish item updated successfully');
    } catch (e) {
      debugPrint('❌ Error updating wish item: $e');
      rethrow;
    }
  }

  /// Delete wish item
  Future<void> deleteWishItem(String itemId) async {
    try {
      debugPrint('🔥 Deleting wish item from Firestore: $itemId');
      
      await _firestore.collection('wish_items').doc(itemId).delete();
      
      debugPrint('✅ Wish item deleted successfully');
    } catch (e) {
      debugPrint('❌ Error deleting wish item: $e');
      rethrow;
    }
  }

  // ============== WISH ITEM STATUS METHODS ==============

  /// Get wish item status
  Future<Map<String, dynamic>?> getWishItemStatus(String itemId, String userId) async {
    try {
      debugPrint('🔥 Getting wish item status from Firestore: $itemId for user $userId');
      
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
        debugPrint('✅ Wish item status retrieved successfully');
        return data;
      } else {
        debugPrint('⚠️ Wish item status not found');
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting wish item status: $e');
      rethrow;
    }
  }

  /// Set wish item status
  Future<void> setWishItemStatus(String itemId, String userId, Map<String, dynamic> statusData) async {
    try {
      debugPrint('🔥 Setting wish item status in Firestore: $itemId for user $userId');
      
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
      
      debugPrint('✅ Wish item status set successfully');
    } catch (e) {
      debugPrint('❌ Error setting wish item status: $e');
      rethrow;
    }
  }

  // ============== FRIENDS METHODS ==============

  /// Get user's friends
  Future<List<Map<String, dynamic>>> getUserFriends(String userId) async {
    try {
      debugPrint('🔥 Getting user friends from Firestore: $userId');
      
      final querySnapshot = await _firestore
          .collection('friendships')
          .where('user_id', isEqualTo: userId)
          .where('status', isEqualTo: 'accepted')
          .get();
      
      final friendIds = querySnapshot.docs.map((doc) => doc.data()['friend_id'] as String).toList();
      
      if (friendIds.isEmpty) {
        debugPrint('✅ No friends found');
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
      
      debugPrint('✅ Retrieved ${friends.length} friends');
      return friends;
    } catch (e) {
      debugPrint('❌ Error getting user friends: $e');
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

      // Check if target user exists and is public
      final targetUser = await getUserProfile(favoriteUserId);
      if (targetUser == null) {
        throw Exception('User not found');
      }

      if (targetUser['is_private'] == true) {
        throw Exception('Cannot favorite private users');
      }

      // Add favorite
      await _firestore.collection('user_favorites').add({
        'user_id': currentUserId,
        'favorite_user_id': favoriteUserId,
        'created_at': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Added user $favoriteUserId to favorites');
    } catch (e) {
      debugPrint('❌ Error adding favorite: $e');
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

      debugPrint('✅ Removed user $favoriteUserId from favorites');
    } catch (e) {
      debugPrint('❌ Error removing favorite: $e');
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
      debugPrint('❌ Error checking favorite: $e');
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

      debugPrint('✅ Retrieved ${favorites.length} favorites');
      return favorites;
    } catch (e) {
      debugPrint('❌ Error getting favorites: $e');
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
      debugPrint('❌ Error getting paginated favorites: $e');
      return [];
    }
  }

  /// Search for users by name or email (only public profiles)
  Future<List<Map<String, dynamic>>> searchUsersPaginated(
    String query, {
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      if (query.trim().isEmpty || currentUserId == null) return [];

      // Firestore text search is limited, so we'll search by display_name and email
      // Note: This is a simplified search. For better search, consider using Algolia
      final searchQuery = query.trim().toLowerCase();

      final usersQuery = await _firestore
          .collection('users')
          .where('is_private', isEqualTo: false)
          .limit(limit + offset)
          .get();

      final filteredUsers = usersQuery.docs
          .where((doc) {
            final data = doc.data();
            final displayName = (data['display_name'] as String?)?.toLowerCase() ?? '';
            final email = (data['email'] as String?)?.toLowerCase() ?? '';
            return doc.id != currentUserId && 
                   (displayName.contains(searchQuery) || email.contains(searchQuery));
          })
          .skip(offset)
          .take(limit)
          .map((doc) => {
            'id': doc.id,
            ...doc.data(),
          })
          .toList();

      debugPrint('✅ Found ${filteredUsers.length} users matching "$query"');
      return filteredUsers;
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
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

      debugPrint('✅ Retrieved ${wishlists.length} public wishlists for user $userId');
      return wishlists;
    } catch (e) {
      debugPrint('❌ Error getting public wishlists: $e');
      return [];
    }
  }

  // ============== METHOD ALIASES FOR COMPATIBILITY ==============

  /// Get wishlists for current user (alias for getUserWishlists)
  Future<List<Map<String, dynamic>>> getWishlistsForCurrentUser() async {
    if (currentUserId == null) return [];
    return await getUserWishlists(currentUserId!);
  }

  /// Get wishlists (alias for getUserWishlists) 
  Stream<List<Map<String, dynamic>>> getWishlists(String userId) {
    return _firestore
        .collection('wishlists')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

  /// Get wish items as Stream (alias for getWishlistItems)
  Stream<List<Map<String, dynamic>>> getWishItems(String wishlistId) {
    return _firestore
        .collection('wish_items')
        .where('wishlist_id', isEqualTo: wishlistId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {
              'id': doc.id,
              ...doc.data(),
            }).toList());
  }

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

      // Apply sorting (simplified - just use created_at for now)
      query = query.orderBy('created_at', descending: true);

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

      debugPrint('✅ Retrieved ${items.length} wish items (paginated)');
      return items;
    } catch (e) {
      debugPrint('❌ Error getting paginated wish items: $e');
      return [];
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

      debugPrint('✅ Retrieved ${wishlists.length} wishlists (paginated)');
      return wishlists;
    } catch (e) {
      debugPrint('❌ Error getting paginated wishlists: $e');
      return [];
    }
  }

  /// Delete wish item with wishlist ID (compatibility method)
  Future<void> deleteWishItemFromWishlist(String wishlistId, String itemId) async {
    // For compatibility, we ignore wishlistId and just delete by itemId
    try {
      await _firestore.collection('wish_items').doc(itemId).delete();
      debugPrint('✅ Deleted wish item $itemId');
    } catch (e) {
      debugPrint('❌ Error deleting wish item: $e');
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
      
      debugPrint('📊 Analytics event logged: $eventType');
    } catch (e) {
      debugPrint('❌ Error logging analytics event: $e');
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
      debugPrint('❌ Error getting usage stats: $e');
      return null;
    }
  }
  
  /// Procura utilizadores registados na app usando números de telefone
  /// 
  /// Este método é essencial para a integração com contactos, permitindo identificar
  /// quais contactos do utilizador já estão a usar a aplicação.
  /// 
  /// Limitações e considerações:
  /// - Só retorna utilizadores com perfis públicos (profile_visibility: 'public')
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
      
      debugPrint('🔍 Looking up users by phone numbers (${phoneNumbers.length})');
      
      // Firestore não suporta consultas IN com mais de 10 valores
      // Por isso, dividimos em batches de 10
      final results = <Map<String, dynamic>>[];
      const batchSize = 10;
      
      for (int i = 0; i < phoneNumbers.length; i += batchSize) {
        final batch = phoneNumbers.skip(i).take(batchSize).toList();
        
        final query = await _firestore
          .collection('users')
          .where('phone_number', whereIn: batch)
          .where('profile_visibility', isEqualTo: 'public')
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
      
      debugPrint('✅ Found ${results.length} users from phone numbers');
      return results;
    } catch (e) {
      debugPrint('❌ Error looking up users by phone numbers: $e');
      return [];
    }
  }
}