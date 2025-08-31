import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:wishlist_app/repositories/favorites_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing user favorites system.
/// 
/// Simple unidirectional system where users can mark other users as favorites
/// without approval process. Replaces the complex friendship system.
class FavoritesService {
  final FavoritesRepository _favoritesRepo = FavoritesRepository();

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  /// Add a user to favorites
  Future<bool> addFavorite(String favoriteUserId) async {
    try {
  final currentUserId = AuthService.getCurrentUserId();
  if (currentUserId == null) throw Exception('User not authenticated');
  await _favoritesRepo.add(currentUserId, favoriteUserId);
      return true;
    } catch (e) {
      MonitoringService.logErrorStatic('add_favorite', e, stackTrace: StackTrace.current);
      
      // Handle specific error messages
      final errorMessage = e.toString();
      if (errorMessage.contains('Cannot favorite yourself')) {
        throw Exception('Não pode marcar-se a si mesmo como favorito');
      } else if (errorMessage.contains('User not found')) {
        throw Exception('Utilizador não encontrado');
      } else if (errorMessage.contains('Cannot favorite private users')) {
        throw Exception('Não pode adicionar utilizadores privados aos favoritos');
      } else if (errorMessage.contains('User not authenticated')) {
        throw Exception('Utilizador não autenticado');
      } else {
        throw Exception('Erro ao adicionar favorito: $e');
      }
    }
  }

  /// Remove a user from favorites
  Future<bool> removeFavorite(String favoriteUserId) async {
    try {
  final currentUserId = AuthService.getCurrentUserId();
  if (currentUserId == null) throw Exception('User not authenticated');
  await _favoritesRepo.remove(currentUserId, favoriteUserId);
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
  return await _favoritesRepo.isFavorite(currentUserId, userId);
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
      if (currentUserId == null) return [];
      final ids = await _favoritesRepo.listIds(currentUserId);
      // Batch fetch profiles (respect whereIn 10 limit)
      final profiles = <Map<String, dynamic>>[];
      const batch = 10;
      for (int i = 0; i < ids.length; i += batch) {
        final slice = ids.skip(i).take(batch).toList();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: slice)
            .get();
        for (final doc in snap.docs) {
          profiles.add({'id': doc.id, ...doc.data()});
        }
      }
      return profiles;
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
  // Offset-based pagination replaced by cursor in repos; emulate simple slicing
  final all = await getFavorites();
  final start = offset;
  final end = (offset + limit).clamp(0, all.length);
  if (start >= all.length) return [];
  return all.sublist(start, end);
    } catch (e) {
      MonitoringService.logErrorStatic('get_favorites_paginated', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Get public profiles from contacts that have accounts
  /// Used for the "Explore" screen
  /// Identifica contatos que já possuem contas na aplicação
  /// 
  /// Este método é fundamental para a descoberta social, permitindo que 
  /// utilizadores encontrem amigos que já usam a aplicação, a partir dos seus contactos.
  /// 
  /// Fluxo completo do Firebase:
  /// 1. Limpa e formata os números de telefone para consistência
  /// 2. Remove duplicados com toSet() para otimizar a consulta
  /// 3. Consulta o Firebase para encontrar perfis públicos com estes números
  /// 
  /// Privacidade e segurança:
  /// - Apenas perfis públicos são retornados
  /// - Apenas informações básicas não sensíveis são fornecidas
  /// 
  /// @param phoneNumbers Lista bruta de números de telefone dos contactos
  /// @returns Lista de perfis encontrados no Firebase com os números fornecidos
  Future<List<Map<String, dynamic>>> getContactsWithAccounts(List<String> phoneNumbers) async {
    try {
      // Clean and format phone numbers for matching
      final cleanedNumbers = phoneNumbers
          .map((number) => _cleanPhoneNumber(number))
          .where((number) => number.isNotEmpty)
          .toSet()
          .toList();

      if (cleanedNumbers.isEmpty) return [];

      // Usar o novo método do FirebaseDatabaseService para buscar utilizadores por números de telefone
      // Query users by phone numbers (batched whereIn)
      final results = <Map<String, dynamic>>[];
      const batchSize = 10;
      for (int i = 0; i < cleanedNumbers.length; i += batchSize) {
        final slice = cleanedNumbers.skip(i).take(batchSize).toList();
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('phone_number', whereIn: slice)
            .where('is_private', isEqualTo: false)
            .get();
        for (final doc in snap.docs) {
          results.add({'id': doc.id, ...doc.data()});
        }
      }
      return results;
    } catch (e) {
      MonitoringService.logErrorStatic('get_contacts_with_accounts', e, stackTrace: StackTrace.current);
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

      // Get only public wishlists using the method from FirebaseDatabaseService
    // Fetch public wishlists for given user
    final snap = await FirebaseFirestore.instance
      .collection('wishlists')
      .where('owner_id', isEqualTo: favoriteUserId)
      .where('is_private', isEqualTo: false)
      .get();
    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
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
  final ids = await _favoritesRepo.listIds(currentUserId);
  return ids.length;
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

      int successCount = 0;
      for (final userId in validUserIds) {
        try {
          await addFavorite(userId); // uses repository internally
          successCount++;
        } catch (e) {
          // Continue with next user if one fails
          MonitoringService.logErrorStatic('add_multiple_favorites_single', e);
        }
      }
      
      return successCount;
    } catch (e) {
      MonitoringService.logErrorStatic('add_multiple_favorites', e, stackTrace: StackTrace.current);
      return 0;
    }
  }
}