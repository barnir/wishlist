import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ContactsService {
  final _supabase = Supabase.instance.client;

  // Solicitar permissão para aceder aos contactos
  Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  // Verificar se tem permissão para contactos
  Future<bool> hasContactsPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }

  // Obter todos os contactos do dispositivo
  Future<List<Contact>> getDeviceContacts() async {
    if (!await hasContactsPermission()) {
      final granted = await requestContactsPermission();
      if (!granted) {
        throw Exception('Permissão para aceder aos contactos foi negada');
      }
    }

    try {
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
      return contacts;
    } catch (e) {
      throw Exception('Erro ao carregar contactos: $e');
    }
  }

  // Extrair números de telefone dos contactos
  List<String> extractPhoneNumbers(List<Contact> contacts) {
    final phoneNumbers = <String>[];
    
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        // Limpar e normalizar o número de telefone
        final cleanNumber = _cleanPhoneNumber(phone.number);
        if (cleanNumber.isNotEmpty && !phoneNumbers.contains(cleanNumber)) {
          phoneNumbers.add(cleanNumber);
        }
      }
    }
    
    return phoneNumbers;
  }

  // Limpar e normalizar número de telefone
  String _cleanPhoneNumber(String phoneNumber) {
    // Remover todos os caracteres não numéricos exceto o +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Se começar com 00, substituir por +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }
    
    // Se for um número português (9 dígitos) sem código de país, adicionar +351
    if (cleaned.length == 9 && cleaned.startsWith('9')) {
      cleaned = '+351$cleaned';
    }
    
    return cleaned;
  }

  // Encontrar utilizadores registados com base nos contactos
  Future<List<Map<String, dynamic>>> findRegisteredFriends() async {
    try {
      final contacts = await getDeviceContacts();
      final phoneNumbers = extractPhoneNumbers(contacts);
      
      if (phoneNumbers.isEmpty) {
        return [];
      }

      // Procurar utilizadores com estes números de telefone
      final registeredUsers = await _supabase
          .from('profiles')
          .select('id, display_name, phone_number')
          .inFilter('phone_number', phoneNumbers);

      // Criar mapa de contacto para facilitar a associação
      final contactMap = <String, Contact>{};
      for (final contact in contacts) {
        for (final phone in contact.phones) {
          final cleanNumber = _cleanPhoneNumber(phone.number);
          contactMap[cleanNumber] = contact;
        }
      }

      // Enriquecer os dados dos utilizadores com informações dos contactos
      final enrichedUsers = <Map<String, dynamic>>[];
      for (final user in registeredUsers) {
        final phoneNumber = user['phone_number'] as String?;
        if (phoneNumber != null) {
          final contact = contactMap[phoneNumber];
          enrichedUsers.add({
            ...user,
            'contact_name': contact?.displayName,
            'is_from_contacts': true,
          });
        }
      }

      return enrichedUsers;
    } catch (e) {
      throw Exception('Erro ao encontrar amigos registados: $e');
    }
  }

  // Sincronizar contactos periodicamente (pode ser chamada em background)
  Future<void> syncContacts() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final registeredFriends = await findRegisteredFriends();
      
      // Guardar cache dos contactos encontrados (opcional)
      // Isto pode ser útil para mostrar sugestões de amigos
      for (final friend in registeredFriends) {
        // Verificar se já existe uma sugestão ou amizade
        final existingRelation = await _supabase
            .from('friendships')
            .select('id')
            .or('and(user_id.eq.$currentUserId,friend_id.eq.${friend['id']}),and(user_id.eq.${friend['id']},friend_id.eq.$currentUserId)')
            .maybeSingle();

        // Se não existe relação, pode criar uma sugestão (opcional)
        if (existingRelation == null) {
          // TODO: Implementar sistema de sugestões se necessário
        }
      }
    } catch (e) {
      // Falhar silenciosamente para não interromper a app
      print('Erro na sincronização de contactos: $e');
    }
  }

  // Obter sugestões de amigos baseadas nos contactos
  Future<List<Map<String, dynamic>>> getFriendSuggestions() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return [];

      final registeredFriends = await findRegisteredFriends();
      
      // Filtrar utilizadores que já são amigos ou têm pedidos pendentes
      final suggestions = <Map<String, dynamic>>[];
      
      for (final friend in registeredFriends) {
        // Verificar se já existe alguma relação
        final existingFriendship = await _supabase
            .from('friendships')
            .select('status')
            .or('and(user_id.eq.$currentUserId,friend_id.eq.${friend['id']}),and(user_id.eq.${friend['id']},friend_id.eq.$currentUserId)')
            .maybeSingle();

        // Se não existe relação, adicionar às sugestões
        if (existingFriendship == null && friend['id'] != currentUserId) {
          suggestions.add({
            ...friend,
            'suggestion_reason': 'Está nos teus contactos',
          });
        }
      }

      return suggestions;
    } catch (e) {
      return [];
    }
  }
}