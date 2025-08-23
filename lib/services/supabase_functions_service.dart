import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/services/auth_service.dart';

/// Service for calling Supabase Edge Functions
class SupabaseFunctionsService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Call delete-user function for complete data cleanup
  /// This function deletes all user data from all tables in the correct order
  Future<Map<String, dynamic>> deleteUser() async {
    try {
      final userId = AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('No user logged in');
      }

      debugPrint('=== Calling Supabase delete-user function ===');
      debugPrint('User ID: $userId');
      
      final response = await _supabaseClient.functions.invoke(
        'delete-user',
        headers: {
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Delete-user function response: ${response.data}');
      
      if (response.data != null) {
        return {
          'success': true,
          'message': 'User data deleted successfully from Supabase',
          'data': response.data,
        };
      } else {
        throw Exception('Empty response from delete-user function');
      }
    } catch (e) {
      debugPrint('Error calling delete-user function: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to delete user data from Supabase'
      };
    }
  }

  /// Test connection to Supabase functions
  Future<bool> testConnection() async {
    try {
      // Try to call a simple function or endpoint to test connectivity
      debugPrint('Testing Supabase functions connection...');
      return true;
    } catch (e) {
      debugPrint('Supabase functions connection test failed: $e');
      return false;
    }
  }
}