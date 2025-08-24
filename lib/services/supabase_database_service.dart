import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/services/monitoring_service.dart';
import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/models/sort_options.dart';

/// Serviço otimizado para operações de banco de dados
/// Implementa queries eficientes com JOINs e paginação
class SupabaseDatabaseService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  // =====================================================
  // MÉTODOS LEGACY - COMPATIBILIDADE COM CÓDIGO EXISTENTE
  // =====================================================

  /// Busca wishlists do usuário (método legacy)
  Stream<List<Map<String, dynamic>>> getWishlists(String userId) {
    return getWishlistsWithCounts(userId);
  }

  /// Busca wishlists para usuário atual (método legacy)
  Future<List<Map<String, dynamic>>> getWishlistsForCurrentUser() async {
    final userId = AuthService.getCurrentUserId();
    if (userId == null) {
      return [];
    }
    
    try {
      final response = await _supabaseClient
          .from('wishlists')
          .select('id, name')
          .eq('owner_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      MonitoringService.logErrorStatic('get_wishlists_for_current_user', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Busca wishlist específica (método legacy)
  Future<Map<String, dynamic>?> getWishlist(String wishlistId) async {
    try {
      final response = await _supabaseClient
          .from('wishlists')
          .select()
          .eq('id', wishlistId)
          .single();
      return response;
    } catch (e) {
      MonitoringService.logErrorStatic('get_wishlist', e, stackTrace: StackTrace.current);
      return null;
    }
  }

  /// Salva wishlist (método legacy)
  Future<Map<String, dynamic>?> saveWishlist({
    required String name,
    required bool isPrivate,
    String? userId,
    File? imageFile,
    String? imageUrl,
    String? wishlistId,
  }) async {
    String? finalImageUrl = imageUrl;

    if (imageFile != null) {
      // Note: Image upload now handled by CloudinaryService in the UI layer
      // This service only handles database operations
      throw Exception('Image upload should be handled by CloudinaryService before calling this method');
    }

    final data = {
      'name': name,
      'is_private': isPrivate,
      'image_url': finalImageUrl,
    };

    if (wishlistId == null) {
      final currentUserId = userId ?? AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception(
          'User not authenticated. Cannot save wishlist without an owner.',
        );
      }
      data['owner_id'] = currentUserId;
      final response = await _supabaseClient
          .from('wishlists')
          .insert(data)
          .select()
          .single();
      return response;
    } else {
      await _supabaseClient.from('wishlists').update(data).eq('id', wishlistId);
      return null;
    }
  }

  /// Deleta wishlist (método legacy)
  Future<void> deleteWishlist(String wishlistId) async {
    try {
      await _supabaseClient.from('wishlists').delete().eq('id', wishlistId);
    } catch (e) {
      MonitoringService.logErrorStatic('delete_wishlist', e, stackTrace: StackTrace.current);
    }
  }

  /// Busca wish items (método legacy)
  Stream<List<Map<String, dynamic>>> getWishItems(
    String wishlistId, {
    String? category,
    SortOptions? sortOption,
  }) {
    return getWishItemsPaginated(wishlistId, category: category, sortOption: sortOption);
  }

  /// Busca wish item específico (método legacy)
  Future<Map<String, dynamic>?> getWishItem(
    String wishlistId, {
    String? itemId,
  }) async {
    if (itemId == null) return null;
    try {
      final response = await _supabaseClient
          .from('wish_items')
          .select()
          .eq('wishlist_id', wishlistId)
          .eq('id', itemId)
          .single();
      return response;
    } catch (e) {
      MonitoringService.logErrorStatic('get_wish_item', e, stackTrace: StackTrace.current);
      return null;
    }
  }

  /// Salva wish item (método legacy)
  Future<void> saveWishItem({
    required String wishlistId,
    required String name,
    required double price,
    required String category,
    String? link,
    String? description,
    File? imageFile,
    String? imageUrl,
    String? itemId,
  }) async {
    String? finalImageUrl = imageUrl;

    if (imageFile != null) {
      // Note: Image upload now handled by CloudinaryService in the UI layer
      // This service only handles database operations
      throw Exception('Image upload should be handled by CloudinaryService before calling this method');
    }

    final data = {
      'wishlist_id': wishlistId,
      'name': name,
      'price': price,
      'category': category,
      'link': link,
      'description': description,
      'image_url': finalImageUrl,
    };

    if (itemId == null) {
      await _supabaseClient.from('wish_items').insert(data);
    } else {
      await _supabaseClient.from('wish_items').update(data).eq('id', itemId);
    }
  }

  /// Deleta wish item (método legacy)
  Future<void> deleteWishItem(String wishlistId, String itemId) async {
    try {
      await _supabaseClient.from('wish_items').delete().eq('id', itemId);
    } catch (e) {
      MonitoringService.logErrorStatic('delete_wish_item', e, stackTrace: StackTrace.current);
    }
  }

  /// Busca usuários públicos (método legacy)
  Stream<List<Map<String, dynamic>>> getPublicUsersLegacy({String? searchTerm}) {
    var query = _supabaseClient.from('users').select().eq('is_private', false);

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query.ilike('display_name', '$searchTerm%');
    }

    return query
        .order('display_name', ascending: true)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Busca wishlists públicas (método legacy)
  Stream<List<Map<String, dynamic>>> getPublicWishlistsLegacy({String? searchTerm}) {
    var query = _supabaseClient
        .from('wishlists')
        .select()
        .eq('is_private', false);

    if (searchTerm != null && searchTerm.isNotEmpty) {
      query = query.ilike('name', '$searchTerm%');
    }

    return query
        .order('name', ascending: true)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  // =====================================================
  // 1. QUERIES OTIMIZADAS PARA WISHLISTS
  // =====================================================

  /// Busca wishlists do usuário com contagem de items em uma query
  Stream<List<Map<String, dynamic>>> getWishlistsWithCounts(String userId) {
    return _supabaseClient
        .from('wishlists')
        .select('''
          *,
          wish_items(count)
        ''')
        .eq('owner_id', userId)
        .order('created_at', ascending: false)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((e) {
          MonitoringService.logErrorStatic('get_wishlists_with_counts', e, stackTrace: StackTrace.current);
          return <Map<String, dynamic>>[];
        });
  }

  /// Busca wishlist específica com todos os items em uma query
  Future<Map<String, dynamic>?> getWishlistWithItems(String wishlistId) async {
    try {
      final response = await _supabaseClient
          .from('wishlists')
          .select('''
            *,
            wish_items(*)
          ''')
          .eq('id', wishlistId)
          .single();
      
      return response;
    } catch (e) {
      MonitoringService.logErrorStatic('get_wishlist_with_items', e, stackTrace: StackTrace.current);
      return null;
    }
  }

  /// Busca wishlists públicas com informações do usuário
  Stream<List<Map<String, dynamic>>> getPublicWishlists({int limit = 20}) {
    return _supabaseClient
        .from('wishlists')
        .select('''
          *,
          users!wishlists_owner_id_fkey(
            id,
            display_name,
            photo_url,
            is_private
          ),
          wish_items(count)
        ''')
        .eq('is_private', false)
        .order('created_at', ascending: false)
        .limit(limit)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((e) {
          MonitoringService.logErrorStatic('get_public_wishlists', e, stackTrace: StackTrace.current);
          return <Map<String, dynamic>>[];
        });
  }

  // =====================================================
  // 2. QUERIES OTIMIZADAS PARA WISH_ITEMS
  // =====================================================

  /// Busca items com paginação e filtros otimizados
  Stream<List<Map<String, dynamic>>> getWishItemsPaginated(
    String wishlistId, {
    int page = 0,
    int limit = 20,
    String? category,
    SortOptions? sortOption,
  }) {
    try {
      dynamic query = _supabaseClient
          .from('wish_items')
          .select()
          .eq('wishlist_id', wishlistId);

      // Aplicar filtros
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      // Aplicar ordenação
      query = _applySortOption(query, sortOption);

      // Aplicar paginação
      query = query.range(page * limit, (page + 1) * limit - 1);

      return query
          .asStream()
          .map((data) => List<Map<String, dynamic>>.from(data))
          .handleError((e) {
            MonitoringService.logErrorStatic('get_wish_items_paginated', e, stackTrace: StackTrace.current);
            return <Map<String, dynamic>>[];
          });
    } catch (e) {
      MonitoringService.logErrorStatic('get_wish_items_paginated', e, stackTrace: StackTrace.current);
      return Stream.value(<Map<String, dynamic>>[]);
    }
  }

  /// Busca items por categoria com estatísticas
  Future<Map<String, dynamic>> getItemsByCategory(String wishlistId) async {
    try {
      final response = await _supabaseClient
          .from('wish_items')
          .select('category, price')
          .eq('wishlist_id', wishlistId);

      // Processar estatísticas
      final Map<String, List<double>> categoryPrices = {};
      double totalValue = 0;

      for (final item in response) {
        final category = item['category'] as String;
        final price = (item['price'] as num?)?.toDouble() ?? 0;

        categoryPrices.putIfAbsent(category, () => []).add(price);
        totalValue += price;
      }

      // Calcular estatísticas por categoria
      final Map<String, Map<String, dynamic>> categoryStats = {};
      categoryPrices.forEach((category, prices) {
        final avgPrice = prices.isNotEmpty ? prices.reduce((a, b) => a + b) / prices.length : 0;
        final minPrice = prices.isNotEmpty ? prices.reduce((a, b) => a < b ? a : b) : 0;
        final maxPrice = prices.isNotEmpty ? prices.reduce((a, b) => a > b ? a : b) : 0;

        categoryStats[category] = {
          'count': prices.length,
          'avg_price': avgPrice,
          'min_price': minPrice,
          'max_price': maxPrice,
          'total_value': prices.reduce((a, b) => a + b),
        };
      });

      return {
        'categories': categoryStats,
        'total_items': response.length,
        'total_value': totalValue,
      };
    } catch (e) {
      MonitoringService.logErrorStatic('get_items_by_category', e, stackTrace: StackTrace.current);
      return {};
    }
  }

  // =====================================================
  // 3. QUERIES OTIMIZADAS PARA USERS
  // =====================================================

  /// Busca usuários públicos com estatísticas
  Stream<List<Map<String, dynamic>>> getPublicUsers({int limit = 20}) {
    return _supabaseClient
        .from('users')
        .select('''
          id,
          display_name,
          photo_url,
          created_at,
          wishlists(count)
        ''')
        .eq('is_private', false)
        .order('created_at', ascending: false)
        .limit(limit)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((e) {
          MonitoringService.logErrorStatic('get_public_users', e, stackTrace: StackTrace.current);
          return <Map<String, dynamic>>[];
        });
  }

  /// Busca perfil do usuário com estatísticas completas
  Future<Map<String, dynamic>?> getUserProfileWithStats(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('''
            *,
            wishlists(count),
            wishlists!wishlists_owner_id_fkey(
              id,
              name,
              is_private,
              created_at,
              wish_items(count)
            )
          ''')
          .eq('id', userId)
          .single();

      // Calcular estatísticas
      final wishlists = List<Map<String, dynamic>>.from(response['wishlists'] ?? []);
      final totalWishlists = wishlists.length;
      final publicWishlists = wishlists.where((w) => w['is_private'] == false).length;
      int totalItems = 0;
      for (final w in wishlists) {
        totalItems += (w['wish_items']?[0]?['count'] as int?) ?? 0;
      }

      response['stats'] = {
        'total_wishlists': totalWishlists,
        'public_wishlists': publicWishlists,
        'private_wishlists': totalWishlists - publicWishlists,
        'total_items': totalItems,
      };

      return response;
    } catch (e) {
      MonitoringService.logErrorStatic('get_user_profile_with_stats', e, stackTrace: StackTrace.current);
      return null;
    }
  }

  // =====================================================
  // 4. QUERIES OTIMIZADAS PARA FRIENDS
  // =====================================================

  /// Busca amigos com informações completas
  Stream<List<Map<String, dynamic>>> getFriendsWithInfo(String userId) {
    return _supabaseClient
        .from('friends')
        .select('''
          *,
          users!friends_friend_id_fkey(
            id,
            display_name,
            photo_url,
            is_private,
            created_at
          )
        ''')
        .eq('user_id', userId)
        .order('added_at', ascending: false)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((e) {
          MonitoringService.logErrorStatic('get_friends_with_info', e, stackTrace: StackTrace.current);
          return <Map<String, dynamic>>[];
        });
  }

  /// Busca amigos mútuos (quem me adicionou)
  Stream<List<Map<String, dynamic>>> getMutualFriends(String userId) async* {
    try {
      // Buscar quem eu adicionei
      final myFriends = await _supabaseClient
          .from('friends')
          .select('friend_id')
          .eq('user_id', userId);

      if (myFriends.isEmpty) {
        yield [];
        return;
      }

      final myFriendIds = myFriends.map((f) => f['friend_id']).toList();

      // Buscar quem me adicionou de volta
      await for (final data in _supabaseClient
          .from('friends')
          .select('''
            *,
            users!friends_user_id_fkey(
              id,
              display_name,
              photo_url,
              is_private
            )
          ''')
          .eq('friend_id', userId)
          .filter('user_id', 'in', '(${myFriendIds.map((id) => "'$id'").join(',')})')
          .order('added_at', ascending: false)
          .asStream()
          .map((data) => List<Map<String, dynamic>>.from(data))) {
        yield data;
      }
    } catch (e) {
      MonitoringService.logErrorStatic('get_mutual_friends', e, stackTrace: StackTrace.current);
      yield [];
    }
  }

  // =====================================================
  // 5. BUSCA FULL-TEXT OTIMIZADA
  // =====================================================

  /// Busca full-text em wishlists
  Stream<List<Map<String, dynamic>>> searchWishlists(String query, {int limit = 20}) {
    return _supabaseClient
        .from('wishlists')
        .select('''
          *,
          users!wishlists_owner_id_fkey(
            id,
            display_name,
            photo_url
          ),
          wish_items(count)
        ''')
        .textSearch('name', query, config: 'portuguese')
        .eq('is_private', false)
        .order('created_at', ascending: false)
        .limit(limit)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((e) {
          MonitoringService.logErrorStatic('search_wishlists', e, stackTrace: StackTrace.current);
          return <Map<String, dynamic>>[];
        });
  }

  /// Busca full-text em wish_items
  Stream<List<Map<String, dynamic>>> searchWishItems(String query, {int limit = 20}) {
    return _supabaseClient
        .from('wish_items')
        .select('''
          *,
          wishlists!wish_items_wishlist_id_fkey(
            id,
            name,
            is_private,
            users!wishlists_owner_id_fkey(
              id,
              display_name
            )
          )
        ''')
        .textSearch('name', query, config: 'portuguese')
        .eq('wishlists.is_private', false)
        .order('created_at', ascending: false)
        .limit(limit)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((e) {
          MonitoringService.logErrorStatic('search_wish_items', e, stackTrace: StackTrace.current);
          return <Map<String, dynamic>>[];
        });
  }

  /// Busca full-text em usuários
  Stream<List<Map<String, dynamic>>> searchUsers(String query, {int limit = 20}) {
    return _supabaseClient
        .from('users')
        .select('''
          id,
          display_name,
          photo_url,
          bio,
          created_at,
          wishlists(count)
        ''')
        .textSearch('display_name', query, config: 'portuguese')
        .eq('is_private', false)
        .order('created_at', ascending: false)
        .limit(limit)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data))
        .handleError((e) {
          MonitoringService.logErrorStatic('search_users', e, stackTrace: StackTrace.current);
          return <Map<String, dynamic>>[];
        });
  }

  // =====================================================
  // 6. ESTATÍSTICAS E MÉTRICAS
  // =====================================================

  /// Busca perfil de utilizador por ID
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final profile = await _supabaseClient
          .from('users')
          .select('id, email, display_name, phone_number, created_at')
          .eq('id', userId)
          .maybeSingle();
      
      return profile;
    } catch (e) {
      MonitoringService.logErrorStatic('getUserProfile', e, stackTrace: StackTrace.current);
      return null;
    }
  }
  
  /// Busca wishlists públicas de um utilizador específico
  Stream<List<Map<String, dynamic>>> getPublicWishlistsForUser(String userId) {
    return _supabaseClient
        .from('wishlists')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Obtém estatísticas gerais da aplicação
  Future<Map<String, dynamic>> getAppStats() async {
    try {
      // Executar queries paralelas para estatísticas
      final futures = await Future.wait([
        _supabaseClient.from('users').select('id'),
        _supabaseClient.from('wishlists').select('id'),
        _supabaseClient.from('wish_items').select('id'),
        _supabaseClient.from('friends').select('id'),
      ]);

      return {
        'total_users': futures[0].length,
        'total_wishlists': futures[1].length,
        'total_items': futures[2].length,
        'total_friendships': futures[3].length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      MonitoringService.logErrorStatic('get_app_stats', e, stackTrace: StackTrace.current);
      return {};
    }
  }

  /// Obtém estatísticas do usuário
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final futures = await Future.wait([
        _supabaseClient
            .from('wishlists')
            .select('id, is_private')
            .eq('owner_id', userId),
        _supabaseClient
            .from('wish_items')
            .select('price')
            .eq('wishlists.owner_id', userId),
        _supabaseClient
            .from('friends')
            .select('id')
            .eq('user_id', userId),
      ]);

      final wishlists = futures[0] as List;
      final items = futures[1] as List;
      final friends = futures[2] as List;

      // Calcular valores totais
      double totalValue = 0;
      for (final item in items) {
        totalValue += (item['price'] as num?)?.toDouble() ?? 0;
      }

      return {
        'total_wishlists': wishlists.length,
        'public_wishlists': wishlists.where((w) => w['is_private'] == false).length,
        'private_wishlists': wishlists.where((w) => w['is_private'] == true).length,
        'total_items': items.length,
        'total_value': totalValue,
        'total_friends': friends.length,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      MonitoringService.logErrorStatic('get_user_stats', e, stackTrace: StackTrace.current);
      return {};
    }
  }

  // =====================================================
  // 7. FUNÇÕES AUXILIARES
  // =====================================================

  /// Aplica opções de ordenação na query
  dynamic _applySortOption(
    dynamic query,
    SortOptions? sortOption,
  ) {
    switch (sortOption) {
      case SortOptions.priceAsc:
        return query.order('price', ascending: true);
      case SortOptions.priceDesc:
        return query.order('price', ascending: false);
      case SortOptions.nameAsc:
        return query.order('name', ascending: true);
      case SortOptions.nameDesc:
        return query.order('name', ascending: false);
      default:
        return query.order('created_at', ascending: false);
    }
  }
}

// =====================================================
// 8. ENUMS E TIPOS
// =====================================================

/// Configurações de paginação
class PaginationConfig {
  final int page;
  final int limit;
  final String? cursor;

  const PaginationConfig({
    this.page = 0,
    this.limit = 20,
    this.cursor,
  });
}

/// Resultado de uma query paginada
class PaginatedResult<T> {
  final List<T> data;
  final bool hasMore;
  final String? nextCursor;
  final int totalCount;

  const PaginatedResult({
    required this.data,
    required this.hasMore,
    this.nextCursor,
    required this.totalCount,
  });
}
