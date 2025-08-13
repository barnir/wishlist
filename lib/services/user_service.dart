import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final String _collectionName = 'users'; // Corresponds to the 'users' table in Supabase

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

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _supabaseClient.from(_collectionName).update(data).eq('id', userId);
  }

  Future<void> createUserProfile(String userId, Map<String, dynamic> data) async {
    await _supabaseClient.from(_collectionName).insert({'id': userId, ...data});
  }

  // --- Methods to be refactored or re-evaluated for Supabase --- 

  Future<List<Map<String, dynamic>>> searchFriendsByContacts(List<String> phoneNumbers) async {
    // This will require the 'phone_number' column in the 'users' table.
    // Also, consider performance for large lists of phone numbers.
    throw UnimplementedError('Search friends by contacts not yet implemented for Supabase.');
  }

  Future<void> addFriend(String userId, String friendId, String friendName) async {
    // This requires a 'friends' table in Supabase.
    throw UnimplementedError('Add friend not yet implemented for Supabase.');
  }

  Future<void> deleteUserData(String userId) async {
    // Deleting user data in Supabase is typically handled by RLS and cascading deletes
    // when the user is deleted from auth.users, or via a server-side function.
    // This method's implementation depends on the overall account deletion strategy.
    throw UnimplementedError('Delete user data not yet implemented for Supabase.');
  }
}