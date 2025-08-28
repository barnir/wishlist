import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import '../models/wish_item_status.dart';

/// Enhanced WishItemStatusService with temporal intentions system.
/// 
/// Features:
/// - 7-day expiration for "will_buy" intentions
/// - Only valid (non-expired) intentions are considered
/// - Automatic cleanup of expired intentions
/// - Push notifications for expiration warnings
/// - Favorites visibility (not friends visibility)
class WishItemStatusServiceTemporal {
  final _database = FirebaseDatabaseService();

  // ============================================================================
  // CORE STATUS OPERATIONS WITH TEMPORAL LOGIC
  // ============================================================================

  /// Set item status with temporal logic
  Future<WishItemStatus> setItemStatus({
    required String wishItemId,
    required ItemPurchaseStatus status,
    bool visibleToOwner = false,
    String? notes,
  }) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      // Verify user can interact with this wishlist
      final canInteract = await canInteractWithWishlist(wishItemId);
      if (!canInteract) {
        throw Exception('Não tem permissões para interagir com este item');
      }

      // Check for existing status
      final existingStatus = await _database
          .from('wish_item_statuses')
          .select()
          .eq('wish_item_id', wishItemId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      Map<String, dynamic> statusData = {
        'wish_item_id': wishItemId,
        'user_id': currentUserId,
        'status': status.value,
        'visible_to_owner': visibleToOwner,
        'notes': notes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existingStatus != null) {
        // Update existing status
        final updated = await _database
            .from('wish_item_statuses')
            .update(statusData)
            .eq('id', existingStatus['id'])
            .select()
            .single();
        
        return WishItemStatus.fromMap(updated);
      } else {
        // Create new status
        statusData['created_at'] = DateTime.now().toIso8601String();
        
        final created = await _database
            .from('wish_item_statuses')
            .insert(statusData)
            .select()
            .single();
        
        return WishItemStatus.fromMap(created);
      }
    } catch (e) {
      MonitoringService.logErrorStatic('set_item_status_temporal', e, stackTrace: StackTrace.current);
      throw Exception('Erro ao definir status do item: $e');
    }
  }

  /// Remove item status (cancel intention or purchase)
  Future<bool> removeItemStatus(String wishItemId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) {
        throw Exception('Utilizador não autenticado');
      }

      await _database
          .from('wish_item_statuses')
          .delete()
          .eq('wish_item_id', wishItemId)
          .eq('user_id', currentUserId);

      return true;
    } catch (e) {
      MonitoringService.logErrorStatic('remove_item_status', e, stackTrace: StackTrace.current);
      throw Exception('Erro ao remover status do item: $e');
    }
  }

  // ============================================================================
  // TEMPORAL QUERIES - ONLY VALID (NON-EXPIRED) STATUSES
  // ============================================================================

  /// Get only VALID friend statuses for an item (excludes expired intentions)
  /// This respects the favorites system visibility rules
  Future<List<WishItemStatus>> getValidFriendItemStatuses(String wishItemId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return [];

      // Use the database view that filters expired intentions
      final statuses = await _database
          .from('valid_wish_item_intentions')
          .select()
          .eq('wish_item_id', wishItemId)
          .neq('user_id', currentUserId);

      return statuses.map((status) => WishItemStatus.fromMap(status)).toList();
    } catch (e) {
      MonitoringService.logErrorStatic('get_valid_friend_statuses', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Get my current status for an item (including expired for self-view)
  Future<WishItemStatus?> getMyItemStatus(String wishItemId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return null;

      final status = await _database
          .from('wish_item_statuses')
          .select()
          .eq('wish_item_id', wishItemId)
          .eq('user_id', currentUserId)
          .maybeSingle();

      if (status == null) return null;
      return WishItemStatus.fromMap(status);
    } catch (e) {
      MonitoringService.logErrorStatic('get_my_item_status', e, stackTrace: StackTrace.current);
      return null;
    }
  }

  /// Get item with all valid statuses (temporal-aware)
  Future<WishItemWithStatus> getItemWithValidStatus(Map<String, dynamic> wishItem) async {
    final wishItemId = wishItem['id'] as String;
    
    final myStatus = await getMyItemStatus(wishItemId);
    final friendStatuses = await getValidFriendItemStatuses(wishItemId);

    return WishItemWithStatus(
      wishItem: wishItem,
      friendStatuses: friendStatuses,
      myStatus: myStatus,
    );
  }

  // ============================================================================
  // EXPIRATION AND CLEANUP OPERATIONS
  // ============================================================================

  /// Check if a status is expired (only for will_buy)
  bool isStatusExpired(WishItemStatus status) {
    if (status.status != ItemPurchaseStatus.willBuy) {
      return false; // Purchased statuses never expire
    }
    
    final now = DateTime.now();
    final expirationDate = status.createdAt.add(Duration(days: 7));
    return now.isAfter(expirationDate);
  }

  /// Get expiring intentions for current user (expire within 24h)
  Future<List<WishItemStatus>> getMyExpiringIntentions() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return [];

      final now = DateTime.now();
      final tomorrow = now.add(Duration(days: 1));
      final weekAgo = now.subtract(Duration(days: 7));

      final statuses = await _database
          .from('wish_item_statuses')
          .select()
          .eq('user_id', currentUserId)
          .eq('status', 'will_buy')
          .gte('created_at', weekAgo.toIso8601String())
          .lt('created_at', tomorrow.subtract(Duration(days: 7)).toIso8601String());

      return statuses
          .map((status) => WishItemStatus.fromMap(status))
          .where((status) {
            final expirationDate = status.createdAt.add(Duration(days: 7));
            return expirationDate.isAfter(now) && expirationDate.isBefore(tomorrow);
          })
          .toList();
    } catch (e) {
      MonitoringService.logErrorStatic('get_expiring_intentions', e, stackTrace: StackTrace.current);
      return [];
    }
  }

  /// Manually cleanup expired intentions for current user
  Future<int> cleanupMyExpiredIntentions() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return 0;

      final weekAgo = DateTime.now().subtract(Duration(days: 7));

      final result = await _database
          .from('wish_item_statuses')
          .delete()
          .eq('user_id', currentUserId)
          .eq('status', 'will_buy')
          .lt('created_at', weekAgo.toIso8601String());

      return result.length ?? 0;
    } catch (e) {
      MonitoringService.logErrorStatic('cleanup_expired_intentions', e, stackTrace: StackTrace.current);
      return 0;
    }
  }

  // ============================================================================
  // FAVORITES SYSTEM INTEGRATION
  // ============================================================================

  /// Check if user can interact with a wishlist (favorites system)
  Future<bool> canInteractWithWishlist(String wishItemId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return false;

      // Get wishlist info through item
      final wishItem = await _database
          .from('wish_items')
          .select('wishlist_id')
          .eq('id', wishItemId)
          .single();

      final wishlist = await _database
          .from('wishlists')
          .select('user_id, is_private')
          .eq('id', wishItem['wishlist_id'])
          .single();

      // If owner, can always interact
      if (wishlist['user_id'] == currentUserId) return true;

      // If private wishlist, need to be favorite
      if (wishlist['is_private'] == true) {
        return await isFavorite(wishlist['user_id']);
      }

      // Public wishlist - can interact if user is favorite
      return await isFavorite(wishlist['user_id']);
    } catch (e) {
      MonitoringService.logErrorStatic('can_interact_wishlist', e, stackTrace: StackTrace.current);
      return false;
    }
  }

  /// Check if current user marked another user as favorite
  Future<bool> isFavorite(String userId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return false;

      final result = await _database
          .from('user_favorites')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('favorite_user_id', userId)
          .maybeSingle();

      return result != null;
    } catch (e) {
      MonitoringService.logErrorStatic('is_favorite_check', e, stackTrace: StackTrace.current);
      return false;
    }
  }

  // ============================================================================
  // STREAMS AND REAL-TIME DATA
  // ============================================================================

  /// Stream of my marked items (including expired for self-view)
  Stream<List<Map<String, dynamic>>> getMyMarkedItemsStream() {
    final currentUserId = AuthService.getCurrentUserId();
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _database
        .from('wish_item_statuses')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('updated_at', ascending: false);
  }

  /// Stream of valid statuses for a specific item (excludes expired)
  Stream<List<Map<String, dynamic>>> getItemStatusesStream(String wishItemId) {
    return _database
        .from('valid_wish_item_intentions')
        .stream(primaryKey: ['id'])
        .eq('wish_item_id', wishItemId)
        .order('updated_at', ascending: false);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get time remaining before intention expires
  Duration? getTimeUntilExpiration(WishItemStatus status) {
    if (status.status != ItemPurchaseStatus.willBuy) {
      return null; // Purchased statuses don't expire
    }
    
    final now = DateTime.now();
    final expirationDate = status.createdAt.add(Duration(days: 7));
    
    if (now.isAfter(expirationDate)) {
      return Duration.zero; // Already expired
    }
    
    return expirationDate.difference(now);
  }

  /// Convert duration to human readable format
  String formatTimeRemaining(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} dia${duration.inDays == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hora${duration.inHours == 1 ? '' : 's'}';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minuto${duration.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Menos de 1 minuto';
    }
  }
}