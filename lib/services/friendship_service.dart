import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/friendship.dart';

class FriendshipService {
  final _supabase = Supabase.instance.client;

  // Enviar pedido de amizade
  Future<bool> sendFriendRequest(String friendId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('Utilizador não autenticado');

      // Verificar se já existe alguma relação
      final existingFriendship = await _supabase
          .from('friendships')
          .select()
          .or('and(user_id.eq.$currentUserId,friend_id.eq.$friendId),and(user_id.eq.$friendId,friend_id.eq.$currentUserId)')
          .maybeSingle();

      if (existingFriendship != null) {
        throw Exception('Já existe uma relação com este utilizador');
      }

      await _supabase.from('friendships').insert({
        'user_id': currentUserId,
        'friend_id': friendId,
        'status': FriendshipStatus.pending.value,
      });

      return true;
    } catch (e) {
      throw Exception('Erro ao enviar pedido de amizade: $e');
    }
  }

  // Aceitar pedido de amizade
  Future<bool> acceptFriendRequest(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.accepted.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId);

      return true;
    } catch (e) {
      throw Exception('Erro ao aceitar pedido de amizade: $e');
    }
  }

  // Rejeitar pedido de amizade
  Future<bool> rejectFriendRequest(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.rejected.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId);

      return true;
    } catch (e) {
      throw Exception('Erro ao rejeitar pedido de amizade: $e');
    }
  }

  // Remover amizade
  Future<bool> removeFriend(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .delete()
          .eq('id', friendshipId);

      return true;
    } catch (e) {
      throw Exception('Erro ao remover amizade: $e');
    }
  }

  // Bloquear utilizador
  Future<bool> blockUser(String friendshipId) async {
    try {
      await _supabase
          .from('friendships')
          .update({
            'status': FriendshipStatus.blocked.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', friendshipId);

      return true;
    } catch (e) {
      throw Exception('Erro ao bloquear utilizador: $e');
    }
  }

  // Obter lista de amigos
  Stream<List<Map<String, dynamic>>> getFriends() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id']);
  }

  // Obter pedidos de amizade pendentes (recebidos)
  Stream<List<Map<String, dynamic>>> getPendingFriendRequests() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id']);
  }

  // Obter pedidos de amizade enviados
  Stream<List<Map<String, dynamic>>> getSentFriendRequests() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _supabase
        .from('friendships')
        .stream(primaryKey: ['id']);
  }

  // Verificar status da amizade com um utilizador específico
  Future<FriendshipStatus?> getFriendshipStatus(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final friendship = await _supabase
          .from('friendships')
          .select('status')
          .or('and(user_id.eq.$currentUserId,friend_id.eq.$userId),and(user_id.eq.$userId,friend_id.eq.$currentUserId)')
          .maybeSingle();

      if (friendship == null) return null;
      
      return FriendshipStatus.fromString(friendship['status'] as String);
    } catch (e) {
      return null;
    }
  }

  // Obter detalhes da amizade
  Future<Friendship?> getFriendship(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final friendshipData = await _supabase
          .from('friendships')
          .select()
          .or('and(user_id.eq.$currentUserId,friend_id.eq.$userId),and(user_id.eq.$userId,friend_id.eq.$currentUserId)')
          .maybeSingle();

      if (friendshipData == null) return null;
      
      return Friendship.fromMap(friendshipData);
    } catch (e) {
      return null;
    }
  }
}