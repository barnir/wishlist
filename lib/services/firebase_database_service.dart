import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firebase Firestore Database Service
/// Replaces SupabaseDatabaseService with Firebase Firestore
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
}