import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/wish_item_status.dart';

/// Serviço para gerenciar o status de compra dos itens da wishlist usando Firebase
/// 
/// Completamente migrado para Firestore
class WishItemStatusService {
  static final WishItemStatusService _instance = WishItemStatusService._internal();
  factory WishItemStatusService() => _instance;
  WishItemStatusService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  /// Define o status de compra de um item numa wishlist
  /// 
  /// Este método permite que amigos indiquem que vão comprar um item ou que já o compraram.
  /// Implementação Firebase completa com considerações de segurança e consistência de dados.
  ///
  /// Comportamentos:
  /// - Se o utilizador já tiver um status para este item, será atualizado
  /// - Se não tiver, será criado um novo documento de status
  /// - Timestamps são gerenciados pelo servidor (FieldValue.serverTimestamp)
  /// 
  /// Segurança:
  /// - Verifica se o utilizador está autenticado
  /// - Verifica se o item existe antes de criar um status
  /// 
  /// @param wishItemId ID do item para o qual definir o status
  /// @param status Enum indicando se vai comprar ou já comprou (willBuy/purchased)
  /// @param visibleToOwner Se verdadeiro, o dono da wishlist pode ver este status
  /// @param notes Notas opcionais do amigo sobre a compra (privadas)
  /// @returns O objeto WishItemStatus criado/atualizado com dados do servidor
  /// @throws Exception se o utilizador não estiver autenticado ou o item não existir
  Future<WishItemStatus> setItemStatus({
    required String wishItemId,
    required ItemPurchaseStatus status,
    bool visibleToOwner = true,
    String? notes,
  }) async {
    try {
      debugPrint('🔥 Setting item status in Firestore: $wishItemId');
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Verificar se o item existe
      final itemDoc = await _firestore.collection('wish_items').doc(wishItemId).get();
      if (!itemDoc.exists) {
        throw Exception('Item not found');
      }

      // Criar ou atualizar o status
      final statusQuery = await _firestore
          .collection('item_statuses')
          .where('wish_item_id', isEqualTo: wishItemId)
          .where('user_id', isEqualTo: currentUserId)
          .get();

      late DocumentReference statusRef;
      
      if (statusQuery.docs.isEmpty) {
        // Criar novo status
        statusRef = _firestore.collection('item_statuses').doc();
      } else {
        // Atualizar status existente
        statusRef = statusQuery.docs.first.reference;
      }

      final now = FieldValue.serverTimestamp();
      final data = {
        'wish_item_id': wishItemId,
        'user_id': currentUserId,
        'status': status.value,
        'visible_to_owner': visibleToOwner,
        'notes': notes,
        'updated_at': now,
      };

      if (statusQuery.docs.isEmpty) {
        // Para novo status, adicionar created_at
        data['created_at'] = now;
        data['id'] = statusRef.id;
      }

      await statusRef.set(data, SetOptions(merge: true));
      
      // Recuperar o documento criado/atualizado para retornar
      final updatedDoc = await statusRef.get();
      final result = updatedDoc.data() as Map<String, dynamic>;
      
      // Converter Timestamp para DateTime
      final createdAt = (result['created_at'] as Timestamp?)?.toDate() ?? DateTime.now();
      final updatedAt = (result['updated_at'] as Timestamp?)?.toDate();
      
      debugPrint('✅ Item status set successfully');
      
      return WishItemStatus(
        id: result['id'],
        wishItemId: result['wish_item_id'],
        userId: result['user_id'],
        status: ItemPurchaseStatus.fromString(result['status']),
        visibleToOwner: result['visible_to_owner'] ?? false,
        notes: result['notes'],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('❌ Error setting item status: $e');
      rethrow;
    }
  }

  /// Obtém o status atual de um item para o utilizador logado
  /// 
  /// Verifica se o utilizador atual marcou um item como "vou comprar" ou "comprado".
  /// Retorna null se não houver status ou se o utilizador não estiver autenticado.
  ///
  /// Otimização:
  /// - Usa limit(1) para garantir eficiência na consulta
  /// - Retorna apenas o primeiro status encontrado (um utilizador só deve ter um status por item)
  /// 
  /// Integração Firebase:
  /// - Converte Timestamp do Firestore para DateTime do Dart
  /// - Mantém consistência de modelo com objetos WishItemStatus
  /// 
  /// @param wishItemId ID do item para verificar o status
  /// @returns O status do item para o utilizador atual, ou null se não existir
  Future<WishItemStatus?> getItemStatus(String wishItemId) async {
    try {
      debugPrint('🔥 Getting item status from Firestore: $wishItemId');
      
      if (currentUserId == null) return null;

      final querySnapshot = await _firestore
          .collection('item_statuses')
          .where('wish_item_id', isEqualTo: wishItemId)
          .where('user_id', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      
      // Converter Timestamp para DateTime
      final createdAt = (data['created_at'] as Timestamp).toDate();
      final updatedAt = (data['updated_at'] as Timestamp?)?.toDate();
      
      return WishItemStatus(
        id: data['id'],
        wishItemId: data['wish_item_id'],
        userId: data['user_id'],
        status: ItemPurchaseStatus.fromString(data['status']),
        visibleToOwner: data['visible_to_owner'] ?? false,
        notes: data['notes'],
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      debugPrint('❌ Error getting item status: $e');
      return null;
    }
  }

  /// Obtém todos os status de compra associados a uma wishlist
  /// 
  /// Este método faz uma consulta em duas etapas para obter todos os status:
  /// 1. Primeiro obtém todos os IDs de items da wishlist
  /// 2. Depois faz uma consulta whereIn para obter todos os status desses items
  ///
  /// Uso de recursos:
  /// - Otimizado para minimizar número de consultas ao Firestore
  /// - Usa whereIn para buscar múltiplos status em uma única consulta
  /// 
  /// Casos especiais:
  /// - Retorna lista vazia se a wishlist não tiver items
  /// - Retorna lista vazia se nenhum item tiver status definido
  /// 
  /// @param wishlistId ID da wishlist para buscar os status
  /// @returns Lista de objetos WishItemStatus para todos os items da wishlist
  Future<List<WishItemStatus>> getWishlistStatuses(String wishlistId) async {
    try {
      debugPrint('🔥 Getting wishlist statuses from Firestore: $wishlistId');
      
      // Primeiro obtemos todos os items da wishlist
      final itemsQuery = await _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId)
          .get();
          
      if (itemsQuery.docs.isEmpty) {
        return [];
      }
      
      // Extraímos os IDs dos items
      final itemIds = itemsQuery.docs.map((doc) => doc.id).toList();
      
      // Agora buscamos os statuses para esses items
      final statusesQuery = await _firestore
          .collection('item_statuses')
          .where('wish_item_id', whereIn: itemIds)
          .get();
          
      return statusesQuery.docs.map((doc) {
        final data = doc.data();
        
        // Converter Timestamp para DateTime
        final createdAt = (data['created_at'] as Timestamp).toDate();
        final updatedAt = (data['updated_at'] as Timestamp?)?.toDate();
        
        return WishItemStatus(
          id: data['id'],
          wishItemId: data['wish_item_id'],
          userId: data['user_id'],
          status: ItemPurchaseStatus.fromString(data['status']),
          visibleToOwner: data['visible_to_owner'] ?? false,
          notes: data['notes'],
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting wishlist statuses: $e');
      return [];
    }
  }

  /// Remove o status de compra de um item para o utilizador atual
  /// 
  /// Permite que um utilizador desista da intenção de compra ou remova
  /// o registro de compra de um item. O status é excluído permanentemente.
  ///
  /// Segurança:
  /// - Verifica se o utilizador está autenticado
  /// - Só permite remover status criados pelo próprio utilizador
  /// 
  /// Comportamento:
  /// - Se não encontrar status para o item/utilizador, silenciosamente não faz nada
  /// - Remove apenas o primeiro status encontrado (normalmente só existe um)
  /// 
  /// @param wishItemId ID do item do qual remover o status
  /// @throws Exception se o utilizador não estiver autenticado
  Future<void> removeItemStatus(String wishItemId) async {
    try {
      debugPrint('🔥 Removing item status from Firestore: $wishItemId');
      
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final querySnapshot = await _firestore
          .collection('item_statuses')
          .where('wish_item_id', isEqualTo: wishItemId)
          .where('user_id', isEqualTo: currentUserId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        debugPrint('✅ Item status removed successfully');
      }
    } catch (e) {
      debugPrint('❌ Error removing item status: $e');
      rethrow;
    }
  }

  /// Obtém todos os items que o utilizador atual marcou para comprar ou já comprou
  /// 
  /// Útil para exibir na seção "Minhas Compras" ou "Items Reservados" do utilizador.
  /// Retorna uma lista ordenada do mais recente para o mais antigo.
  ///
  /// Campos retornados:
  /// - Todos os campos do modelo WishItemStatus
  /// - Timestamps convertidos para DateTime
  /// 
  /// Performance:
  /// - Usa índice em user_id + created_at para consulta eficiente
  /// - Resultados ordenados por data de criação (mais recentes primeiro)
  /// 
  /// @returns Lista de todos os status de compra do utilizador atual
  /// @returns Lista vazia se o utilizador não estiver autenticado ou não tiver compras
  Future<List<WishItemStatus>> getMyPurchaseStatuses() async {
    try {
      debugPrint('🔥 Getting user purchase statuses from Firestore');
      
      if (currentUserId == null) {
        return [];
      }

      final querySnapshot = await _firestore
          .collection('item_statuses')
          .where('user_id', isEqualTo: currentUserId)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        
        // Converter Timestamp para DateTime
        final createdAt = (data['created_at'] as Timestamp).toDate();
        final updatedAt = (data['updated_at'] as Timestamp?)?.toDate();
        
        return WishItemStatus(
          id: data['id'],
          wishItemId: data['wish_item_id'],
          userId: data['user_id'],
          status: ItemPurchaseStatus.fromString(data['status']),
          visibleToOwner: data['visible_to_owner'] ?? false,
          notes: data['notes'],
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Error getting user purchase statuses: $e');
      return [];
    }
  }

  /// Verifica se o utilizador atual tem permissão para ver estatísticas de uma wishlist
  /// 
  /// Regras de permissão implementadas:
  /// - Donos de wishlist sempre podem ver estatísticas de suas próprias listas
  /// - Qualquer utilizador pode ver estatísticas de wishlists públicas
  /// - Wishlists privadas só têm estatísticas visíveis para o dono
  ///
  /// Segurança:
  /// - Não revela a existência de wishlists privadas a utilizadores não autorizados
  /// - Não vaza informações de perfil do dono
  /// 
  /// @param wishlistId ID da wishlist para verificar permissões
  /// @returns true se o utilizador pode ver estatísticas, false caso contrário
  Future<bool> canViewWishlistStats(String wishlistId) async {
    try {
      if (currentUserId == null) {
        return false;
      }

      // Verificar se o utilizador é dono da wishlist
      final wishlistDoc = await _firestore.collection('wishlists').doc(wishlistId).get();
      if (!wishlistDoc.exists) {
        return false;
      }

      // Se o utilizador é dono da wishlist, pode ver as estatísticas
      final wishlistData = wishlistDoc.data()!;
      if (wishlistData['owner_id'] == currentUserId) {
        return true;
      }

      // Verificar se a wishlist é pública
      final isPrivate = wishlistData['is_private'] ?? false;
      if (!isPrivate) {
        return true;  // Wishlists públicas podem ter estatísticas visíveis
      }

      // Para wishlists privadas, só o dono pode ver estatísticas
      return false;
    } catch (e) {
      debugPrint('❌ Error checking wishlist stats permission: $e');
      return false;
    }
  }

  /// Calcula estatísticas completas de uma wishlist
  /// 
  /// Fornece uma visão geral do estado atual de uma wishlist:
  /// - total: Número total de items na wishlist
  /// - reserved: Número de items que amigos marcaram como "vou comprar"
  /// - purchased: Número de items já comprados
  /// - available: Número de items ainda disponíveis (total - reserved - purchased)
  ///
  /// Implementação Firebase:
  /// - Utiliza queries eficientes para minimizar a quantidade de dados transferidos
  /// - Executa dois queries separados para obter dados precisos sem duplicidade
  /// - Executa cálculos no cliente para não sobrecarregar o Firestore
  /// 
  /// Consistência de dados:
  /// - Um item é contado como "reservado" se alguém marcou como "vou comprar"
  /// - Um item é contado como "comprado" se alguém marcou como "purchased"
  /// - Se houver múltiplos status para um item, todos são contados individualmente
  /// 
  /// @param wishlistId ID da wishlist para calcular estatísticas
  /// @returns Mapa com as estatísticas calculadas
  Future<Map<String, int>> getWishlistStats(String wishlistId) async {
    try {
      debugPrint('🔥 Getting wishlist stats from Firestore: $wishlistId');
      
      final result = {
        'total': 0,
        'reserved': 0,
        'purchased': 0,
        'available': 0,
      };
      
      // Primeiro obtemos o total de itens na wishlist
      final itemsQuery = await _firestore
          .collection('wish_items')
          .where('wishlist_id', isEqualTo: wishlistId)
          .get();
          
      result['total'] = itemsQuery.docs.length;
      
      if (itemsQuery.docs.isEmpty) {
        return result;
      }
      
      // Extraímos os IDs dos items
      final itemIds = itemsQuery.docs.map((doc) => doc.id).toList();
      
      // Agora buscamos os statuses para esses items
      final statusesQuery = await _firestore
          .collection('item_statuses')
          .where('wish_item_id', whereIn: itemIds)
          .get();
          
      // Calculamos as estatísticas
      for (final doc in statusesQuery.docs) {
        final data = doc.data();
        final status = ItemPurchaseStatus.fromString(data['status']);
        
        if (status == ItemPurchaseStatus.willBuy) {
          result['reserved'] = (result['reserved'] ?? 0) + 1;
        } else if (status == ItemPurchaseStatus.purchased) {
          result['purchased'] = (result['purchased'] ?? 0) + 1;
        }
      }
      
      // Calculamos quantos items estão disponíveis
      result['available'] = result['total']! - (result['reserved']! + result['purchased']!);
      
      return result;
    } catch (e) {
      debugPrint('❌ Error getting wishlist stats: $e');
      return {
        'total': 0,
        'reserved': 0,
        'purchased': 0,
        'available': 0,
      };
    }
  }
}