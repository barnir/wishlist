import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user data.
///
/// This service provides methods for creating, reading, and updating user profiles,
/// as well as searching for friends and managing friend relationships.
class UserService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final String _collectionName =
      'users'; // Corresponds to the 'users' table in Supabase

  /// Retrieves a user's profile by their ID.
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _supabaseClient
          .from(_collectionName)
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      // Handle case where user profile might not exist
      return null;
    }
  }

  /// Updates a user's profile.
  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _supabaseClient.from(_collectionName).update(data).eq('id', userId);
  }

  /// Creates a new user profile.
  Future<void> createUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _supabaseClient.from(_collectionName).insert({'id': userId, ...data});
  }

  /// Deletes a user profile.
  Future<void> deleteUserProfile(String userId) async {
    try {
      await _supabaseClient
          .from(_collectionName)
          .delete()
          .eq('id', userId);
    } catch (e) {
      // Log error but don't fail the operation
      print('Warning: Could not delete user profile from database: $e');
      rethrow;
    }
  }

  // --- Methods to be refactored or re-evaluated for Supabase ---

  /// Searches for friends by their phone numbers.
  Future<List<Map<String, dynamic>>> searchFriendsByContacts(
    List<String> phoneNumbers,
  ) async {
    if (phoneNumbers.isEmpty) {
      return [];
    }
    try {
      // Supabase allows `in_` operator for lists
      final response = await _supabaseClient
          .from(_collectionName)
          .select()
          .filter('phone_number', 'in', phoneNumbers.join(','));
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Adds a friend to the current user's friend list.
  Future<void> addFriend(
    String userId,
    String friendId,
    String friendName,
  ) async {
    try {
      await _supabaseClient.from('friends').insert({
        'user_id': userId,
        'friend_id': friendId,
        'friend_name':
            friendName, // Assuming you want to store friend's name in the friends table
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a user's data.
  ///
  /// **Note:** This is a placeholder and is not fully implemented.
  Future<void> deleteUserData(String userId) async {
    // Deleting user data in Supabase is typically handled by RLS and cascading deletes
    // when the user is deleted from auth.users, or via a server-side function.
    // This method's implementation depends on the overall account deletion strategy.
    throw UnimplementedError(
      'Delete user data not yet implemented for Supabase.',
    );
  }
}
