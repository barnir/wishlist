import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';

/// Service for managing user favorites system.
/// 
/// Simple unidirectional system where users can mark other users as favorites
/// without approval process. Replaces the complex friendship system.
class FavoritesService {
  final _supabase = Supabase.instance.client;

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Add a user to favorites
  Future<bool> addFavorite(String favoriteUserId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      if (currentUserId == favoriteUserId) {
        throw Exception('Não pode marcar-se a si mesmo como favorito');
      }

      // Check if target user exists and is public
      final targetUser = await _supabase
          .from('users')
          .select('id, is_private')
          .eq('id', favoriteUserId)
          .maybeSingle();

      if (targetUser == null) {
        throw Exception('Utilizador não encontrado');
      }

      if (targetUser['is_private'] == true) {
        throw Exception('Não pode adicionar utilizadores privados aos favoritos');
      }

      // Insert favorite (will fail if already exists due to UNIQUE constraint)
      await _supabase.from('user_favorites').insert({
        'user_id': currentUserId,
        'favorite_user_id': favoriteUserId,
      });

      return true;
    } catch (e) {
      MonitoringService.logErrorStatic('add_favorite', e, stackTrace: StackTrace.current);
      if (e.toString().contains('duplicate key value violates unique constraint')) {
        throw Exception('Utilizador já está nos favoritos');
      }
      throw Exception('Erro ao adicionar favorito: $e');
    }
  }

  /// Remove a user from favorites
  Future<bool> removeFavorite(String favoriteUserId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      await _supabase
          .from('user_favorites')
          .delete()
          .eq('user_id', currentUserId)
          .eq('favorite_user_id', favoriteUserId);

      return true;
    } catch (e) {
      MonitoringService.logErrorStatic('remove_favorite', e, stackTrace: StackTrace.current);
      throw Exception('Erro ao remover favorito: $e');
    }
  }

  /// Check if a user is in favorites
  Future<bool> isFavorite(String userId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return false;

      final result = await _supabase
          .from('user_favorites')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('favorite_user_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      MonitoringService.logErrorStatic('is_favorite', e, stackTrace: StackTrace.current);
      return false;
    }
  }

  // ============================================================================
  // FETCH OPERATIONS
  // ============================================================================

  /// Get all favorites for current user with profile data
  Future<List<Map<String, dynamic>>> getFavorites() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      // Use the view that only shows public profiles
      final result = await _supabase
          .from('user_favorites_with_profile')
          .select('*')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      MonitoringService.logErrorStatic('get_favorites', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Get favorites with pagination
  Future<List<Map<String, dynamic>>> getFavoritesPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      final result = await _supabase
          .from('user_favorites_with_profile')
          .select('*')
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      MonitoringService.logErrorStatic('get_favorites_paginated', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Get public profiles from contacts that have accounts
  /// Used for the "Explore" screen
  Future<List<Map<String, dynamic>>> getContactsWithAccounts(List<String> phoneNumbers) async {
    try {
      // Clean and format phone numbers for matching
      final cleanedNumbers = phoneNumbers
          .map((number) => _cleanPhoneNumber(number))
          .where((number) => number.isNotEmpty)
          .toSet()
          .toList();

      if (cleanedNumbers.isEmpty) return [];

      // Find users by phone numbers (only public profiles)
      final result = await _supabase
          .from('users')
          .select('id, display_name, phone_number')
          .inFilter('phone_number', cleanedNumbers)
          .eq('is_private', false)
          .order('display_name', ascending: true);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      MonitoringService.logErrorStatic('get_contacts_with_accounts', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Search for users by name or phone (only public profiles)
  /// Used for manual search in "Explore" screen
  Future<List<Map<String, dynamic>>> searchPublicUsers(String query) async {
    try {
      if (query.trim().isEmpty) return [];

      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return [];

      // Search by display name or phone (only public profiles)
      final result = await _supabase
          .from('users')
          .select('id, display_name, phone_number')
          .eq('is_private', false)
          .neq('id', currentUserId) // Exclude self
          .or('display_name.ilike.%${query.trim()}%,phone_number.ilike.%${query.trim()}%')
          .order('display_name', ascending: true)
          .limit(20); // Limit results for performance

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      MonitoringService.logErrorStatic('search_public_users', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Get public wishlists for a favorite user
  /// Only returns public wishlists
  Future<List<Map<String, dynamic>>> getFavoriteWishlists(String favoriteUserId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      // Verify the user is actually a favorite
      final isFav = await isFavorite(favoriteUserId);
      if (!isFav) {
        throw Exception('Utilizador não está nos favoritos');
      }

      // Get only public wishlists
      final result = await _supabase
          .from('wishlists')
          .select('id, name, description, is_private, created_at, user_id')
          .eq('user_id', favoriteUserId)
          .eq('is_private', false) // Only public wishlists
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      MonitoringService.logErrorStatic('get_favorite_wishlists', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Clean and normalize phone number for database matching
  String _cleanPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // Basic validation - at least 9 digits
    if (cleaned.length < 9) return '';
    
    // Portuguese mobile: convert to international format if needed
    if (cleaned.length == 9 && cleaned.startsWith('9')) {
      return '351$cleaned'; // Add Portugal country code
    }
    
    return cleaned;
  }

  /// Get count of favorites for current user
  Future<int> getFavoritesCount() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return 0;

      final result = await _supabase
          .from('user_favorites')
          .select('*')
          .eq('user_id', currentUserId);

      return result.length;
    } catch (e) {
      MonitoringService.logErrorStatic('get_favorites_count', e, stackTrace: StackTrace.current);
      return 0;
    }
  }

  /// Bulk add favorites from list of user IDs
  /// Useful for migrating from friendship system
  Future<int> addMultipleFavorites(List<String> userIds) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      final validUserIds = userIds.where((id) => id != currentUserId).toList();
      if (validUserIds.isEmpty) return 0;

      final batch = validUserIds.map((favoriteUserId) => {
        'user_id': currentUserId,
        'favorite_user_id': favoriteUserId,
      }).toList();

      await _supabase.from('user_favorites').insert(batch);
      return validUserIds.length;
    } catch (e) {
      MonitoringService.logErrorStatic('add_multiple_favorites', e, stackTrace: StackTrace.current);
      // Return partial success - some might have been inserted before error
      return 0;
    }
  }
}