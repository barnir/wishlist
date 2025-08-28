import 'package:wishlist_app/services/auth_service.dart';
import 'package:wishlist_app/services/firebase_database_service.dart';
import '../models/wish_item_status.dart';

class WishItemStatusService {
  final _database = FirebaseDatabaseService();

  // Marcar item como "vou comprar" ou "comprado"
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

      // Verificar se já existe um status para este item pelo utilizador atual
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
        // Atualizar status existente
        final updated = await _database
            .from('wish_item_statuses')
            .update(statusData)
            .eq('id', existingStatus['id'])
            .select()
            .single();
        
        return WishItemStatus.fromMap(updated);
      } else {
        // Criar novo status
        statusData['created_at'] = DateTime.now().toIso8601String();
        
        final created = await _database
            .from('wish_item_statuses')
            .insert(statusData)
            .select()
            .single();
        
        return WishItemStatus.fromMap(created);
      }
    } catch (e) {
      throw Exception('Erro ao definir status do item: $e');
    }
  }

  // Remover status do item (cancelar "vou comprar" ou "comprado")
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
      throw Exception('Erro ao remover status do item: $e');
    }
  }

  // Obter status de um item específico pelo utilizador atual
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
      return null;
    }
  }

  // Obter todos os status de um item (exceto do utilizador atual)
  Future<List<WishItemStatus>> getFriendItemStatuses(String wishItemId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return [];

      final statuses = await _database
          .from('wish_item_statuses')
          .select()
          .eq('wish_item_id', wishItemId)
          .neq('user_id', currentUserId);

      return statuses.map((status) => WishItemStatus.fromMap(status)).toList();
    } catch (e) {
      return [];
    }
  }

  // Obter status agregado de um item (meu + amigos)
  Future<WishItemWithStatus> getItemWithStatus(Map<String, dynamic> wishItem) async {
    final wishItemId = wishItem['id'] as String;
    
    final myStatus = await getMyItemStatus(wishItemId);
    final friendStatuses = await getFriendItemStatuses(wishItemId);

    return WishItemWithStatus(
      wishItem: wishItem,
      friendStatuses: friendStatuses,
      myStatus: myStatus,
    );
  }

  // Obter todos os status de itens de uma wishlist (para o dono)
  Future<Map<String, List<WishItemStatus>>> getWishlistItemStatuses(
    String wishlistId, {
    bool onlyVisibleToOwner = true,
  }) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return {};

      // Primeiro, verificar se o utilizador atual é o dono da wishlist
      final wishlist = await _database
          .from('wishlists')
          .select('user_id')
          .eq('id', wishlistId)
          .single();

      if (wishlist['user_id'] != currentUserId) {
        throw Exception('Não tens permissão para ver estes status');
      }

      // Obter todos os itens da wishlist
      final wishItems = await _database
          .from('wish_items')
          .select('id')
          .eq('wishlist_id', wishlistId);

      final itemIds = wishItems.map((item) => item['id'] as String).toList();
      
      if (itemIds.isEmpty) return {};

      // Obter status dos itens
      var query = _database
          .from('wish_item_statuses')
          .select('*, users!user_id(display_name)')
          .inFilter('wish_item_id', itemIds);

      // Se só queremos status visíveis ao dono
      if (onlyVisibleToOwner) {
        query = query.eq('visible_to_owner', true);
      }

      final statuses = await query;

      // Agrupar status por item
      final Map<String, List<WishItemStatus>> statusByItem = {};
      
      for (final statusData in statuses) {
        final status = WishItemStatus.fromMap(statusData);
        final itemId = status.wishItemId;
        
        if (!statusByItem.containsKey(itemId)) {
          statusByItem[itemId] = [];
        }
        statusByItem[itemId]!.add(status);
      }

      return statusByItem;
    } catch (e) {
      throw Exception('Erro ao obter status dos itens: $e');
    }
  }

  // Obter itens que marquei como "vou comprar" ou "comprado"
  Stream<List<Map<String, dynamic>>> getMyMarkedItems() {
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

  // Verificar se o utilizador atual pode ver/modificar uma wishlist
  Future<bool> canInteractWithWishlist(String wishlistId) async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return false;

      final wishlist = await _database
          .from('wishlists')
          .select('user_id, is_private')
          .eq('id', wishlistId)
          .single();

      // Se é o dono, pode sempre interagir
      if (wishlist['user_id'] == currentUserId) return true;

      // Se é privada, só favoritos podem ver
      if (wishlist['is_private'] == true) {
        return await _isFavorite(currentUserId, wishlist['user_id']);
      }

      // Wishlist pública pode ser vista por todos
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verificar se utilizador marcou outro como favorito
  Future<bool> _isFavorite(String userId, String favoriteUserId) async {
    try {
      final favorite = await _database
          .from('user_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('favorite_user_id', favoriteUserId)
          .maybeSingle();

      return favorite != null;
    } catch (e) {
      return false;
    }
  }
}