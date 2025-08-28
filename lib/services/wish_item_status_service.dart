import 'package:wishlist_app/services/firebase_database_service.dart';
import '../models/wish_item_status.dart';

/// Wish Item Status Service - Temporarily disabled during Firebase migration
/// 
/// TODO: Complete migration to Firestore syntax
class WishItemStatusService {

  // Marcar item como "vou comprar" ou "comprado"
  Future<WishItemStatus> setItemStatus({
    required String wishItemId,
    required ItemPurchaseStatus status,
    bool visibleToOwner = true,
    String? notes,
  }) async {
    throw UnimplementedError('WishItemStatusService migration to Firestore pending');
  }

  // Obter status atual de um item
  Future<WishItemStatus?> getItemStatus(String wishItemId) async {
    return null; // Temporarily return null during migration
  }

  // Obter todos os statuses de uma wishlist
  Future<List<WishItemStatus>> getWishlistStatuses(String wishlistId) async {
    return []; // Temporarily return empty list during migration
  }

  // Remover status de um item
  Future<void> removeItemStatus(String wishItemId) async {
    // Temporarily do nothing during migration
  }

  // Obter items que o utilizador marcou para comprar
  Future<List<WishItemStatus>> getMyPurchaseStatuses() async {
    return []; // Temporarily return empty list during migration
  }

  // Verificar se um utilizador pode ver estatísticas de uma wishlist
  Future<bool> canViewWishlistStats(String wishlistId) async {
    return false; // Temporarily return false during migration
  }

  // Obter estatísticas de uma wishlist (quantos items estão reservados, comprados, etc.)
  Future<Map<String, int>> getWishlistStats(String wishlistId) async {
    return {
      'total': 0,
      'reserved': 0,
      'purchased': 0,
      'available': 0,
    }; // Temporarily return empty stats during migration
  }
}