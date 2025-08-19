import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wishlist_app/services/supabase_storage_service.dart';
import 'package:wishlist_app/models/sort_options.dart';

/// Service for interacting with the Supabase database.
///
/// This service provides methods for performing CRUD operations on wishlists and wish items,
/// as well as fetching public data.
class SupabaseDatabaseService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final _supabaseStorageService = SupabaseStorageService();

  // Wishlists operations

  /// Retrieves a stream of wishlists for the given user.
  Stream<List<Map<String, dynamic>>> getWishlists(String userId) {
    return _supabaseClient
        .from('wishlists')
        .stream(primaryKey: ['id'])
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
  }

  /// Retrieves a list of wishlists for the current user.
  Future<List<Map<String, dynamic>>> getWishlistsForCurrentUser() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return [];
    }
    final response = await _supabaseClient
        .from('wishlists')
        .select('id, name')
        .eq('owner_id', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Retrieves a single wishlist by its ID.
  Future<Map<String, dynamic>?> getWishlist(String wishlistId) async {
    final response = await _supabaseClient
        .from('wishlists')
        .select()
        .eq('id', wishlistId)
        .single();
    return response;
  }

  /// Saves a wishlist to the database.
  ///
  /// If [wishlistId] is provided, the existing wishlist will be updated.
  /// Otherwise, a new wishlist will be created.
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
      finalImageUrl = await _supabaseStorageService.uploadImage(
        imageFile,
        'wishlist_images',
      );
      if (finalImageUrl == null) {
        throw Exception('Erro ao carregar imagem.');
      }
    }

    final data = {
      'name': name,
      'is_private': isPrivate,
      'image_url': finalImageUrl,
    };

    if (wishlistId == null) {
      final currentUserId = userId ?? _supabaseClient.auth.currentUser?.id;
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

  /// Deletes a wishlist from the database.
  Future<void> deleteWishlist(String wishlistId) async {
    await _supabaseClient.from('wishlists').delete().eq('id', wishlistId);
  }

  // Wish items operations

  /// Retrieves a stream of wish items for the given wishlist.
  ///
  /// The stream can be filtered by [category] and sorted by [sortOption].
  Stream<List<Map<String, dynamic>>> getWishItems(
    String wishlistId, {
    String? category,
    SortOptions? sortOption,
  }) {
    dynamic query = _supabaseClient
        .from('wish_items')
        .select()
        .eq('wishlist_id', wishlistId);

    if (category != null) {
      query = query.eq('category', category);
    }

    if (sortOption != null) {
      switch (sortOption) {
        case SortOptions.priceAsc:
          query = query.order('price', ascending: true);
          break;
        case SortOptions.priceDesc:
          query = query.order('price', ascending: false);
          break;
        case SortOptions.nameAsc:
          query = query.order('name', ascending: true);
          break;
        case SortOptions.nameDesc:
          query = query.order('name', ascending: false);
          break;
      }
    } else {
      query = query.order('created_at', ascending: false);
    }

    return query.asStream().map(
      (data) => List<Map<String, dynamic>>.from(data),
    );
  }

  /// Retrieves a single wish item by its ID.
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
      // Handle case where item might not exist or other errors
      return null;
    }
  }

  /// Saves a wish item to the database.
  ///
  /// If [itemId] is provided, the existing item will be updated.
  /// Otherwise, a new item will be created.
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
      finalImageUrl = await _supabaseStorageService.uploadImage(
        imageFile,
        'item_images',
      );
      if (finalImageUrl == null) {
        throw Exception('Erro ao carregar imagem.');
      }
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

  /// Deletes a wish item from the database.
  Future<void> deleteWishItem(String wishlistId, String itemId) async {
    await _supabaseClient.from('wish_items').delete().eq('id', itemId);
  }

  // Public data operations

  /// Retrieves a stream of public users.
  ///
  /// The stream can be filtered by [searchTerm].
  Stream<List<Map<String, dynamic>>> getPublicUsers({String? searchTerm}) {
    var query = _supabaseClient.from('users').select().eq('is_private', false);

    if (searchTerm != null && searchTerm.isNotEmpty) {
      // Supabase text search is more advanced, but for simple startsWith/endsWith
      // you might use `ilike` or `like` with wildcards, or FTS.
      // For now, a basic filter:
      query = query.ilike('display_name', '$searchTerm%');
    }

    return query
        .order('display_name', ascending: true)
        .asStream()
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  /// Retrieves a stream of public wishlists.
  ///
  /// The stream can be filtered by [searchTerm].
  Stream<List<Map<String, dynamic>>> getPublicWishlists({String? searchTerm}) {
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
}
