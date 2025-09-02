import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
// Using flutter_contacts built-in permission system
import 'package:mywishstash/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mywishstash/repositories/favorites_repository.dart';
import 'package:mywishstash/services/monitoring_service.dart';

class ContactsService {
  final FirebaseFirestore _firestore;
  final FavoritesRepository _favoritesRepo;
  ContactsService({FirebaseFirestore? firestore, FavoritesRepository? favoritesRepository})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _favoritesRepo = favoritesRepository ?? FavoritesRepository();

  // Solicitar permissão para aceder aos contactos usando flutter_contacts
  Future<bool> requestContactsPermission() async {
    return await FlutterContacts.requestPermission();
  }

  // Verificar se tem permissão para contactos usando flutter_contacts
  Future<bool> hasContactsPermission() async {
    return await FlutterContacts.requestPermission(readonly: true);
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
    final phoneNumbers = <String>{};  // Use Set para evitar duplicados automaticamente
    
    for (final contact in contacts) {
      for (final phone in contact.phones) {
        // Gerar múltiplas variações do número
        final variations = _generateNumberVariations(phone.number);
        phoneNumbers.addAll(variations);
      }
    }
    
    return phoneNumbers.where((number) => number.isNotEmpty).toList();
  }

  // Gerar variações de um número para aumentar chances de match
  List<String> _generateNumberVariations(String phoneNumber) {
    final variations = <String>{};
    
    // Variação principal (normalizada)
    final mainNumber = _cleanPhoneNumber(phoneNumber);
    if (mainNumber.isNotEmpty) {
      variations.add(mainNumber);
    }
    
    // Número original limpo (só dígitos)
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isNotEmpty) {
      // Tentar várias normalizações do número só com dígitos
      variations.addAll(_generateNormalizedVariations(digitsOnly));
    }
    
    return variations.toList();
  }
  
  // Gerar normalizações específicas para um número só com dígitos
  List<String> _generateNormalizedVariations(String digitsOnly) {
    final variations = <String>{};
    
    if (digitsOnly.isEmpty) return [];
    
    // Para números portugueses
    if (digitsOnly.length == 9) {
      if (digitsOnly.startsWith('9') || digitsOnly.startsWith('2') || digitsOnly.startsWith('3')) {
        variations.add('+351$digitsOnly');
      }
    }
    
    // Se começar com 351 (código de Portugal)
    if (digitsOnly.startsWith('351') && digitsOnly.length == 12) {
      variations.add('+$digitsOnly');
      variations.add('+351${digitsOnly.substring(3)}'); // Duplicar por segurança
    }
    
    // Se começar com 00351 (formato internacional sem +)
    if (digitsOnly.startsWith('00351') && digitsOnly.length == 14) {
      variations.add('+351${digitsOnly.substring(5)}');
    }
    
    // Para outros países comuns
    _addInternationalVariations(digitsOnly, variations);
    
    return variations.toList();
  }
  
  void _addInternationalVariations(String digitsOnly, Set<String> variations) {
    // EUA/Canadá: +1
    if (digitsOnly.length == 10 && !digitsOnly.startsWith('0')) {
      variations.add('+1$digitsOnly');
    }
    if (digitsOnly.startsWith('1') && digitsOnly.length == 11) {
      variations.add('+$digitsOnly');
    }
    
    // Reino Unido: +44
    if (digitsOnly.startsWith('44') && digitsOnly.length >= 10) {
      variations.add('+$digitsOnly');
    }
    
    // França: +33
    if (digitsOnly.startsWith('33') && digitsOnly.length >= 10) {
      variations.add('+$digitsOnly');
    }
    
    // Espanha: +34
    if (digitsOnly.startsWith('34') && digitsOnly.length >= 10) {
      variations.add('+$digitsOnly');
    }
    
    // Alemanha: +49
    if (digitsOnly.startsWith('49') && digitsOnly.length >= 10) {
      variations.add('+$digitsOnly');
    }
    
    // Brasil: +55
    if (digitsOnly.startsWith('55') && digitsOnly.length >= 12) {
      variations.add('+$digitsOnly');
    }
  }

  // Limpar e normalizar número de telefone
  String _cleanPhoneNumber(String phoneNumber) {
    if (phoneNumber.trim().isEmpty) return '';
    
    // Remover todos os caracteres não numéricos exceto o +
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Se começar com 00, substituir por +
    if (cleaned.startsWith('00')) {
      cleaned = '+${cleaned.substring(2)}';
    }
    
    // Normalização específica para Portugal
    if (!cleaned.startsWith('+')) {
      // Número português típico: 9 dígitos começando por 9
      if (cleaned.length == 9 && cleaned.startsWith('9')) {
        cleaned = '+351$cleaned';
      }
      // Número português com código nacional: 351XXXXXXXXX
      else if (cleaned.length == 12 && cleaned.startsWith('351')) {
        cleaned = '+$cleaned';
      }
      // Número português longo: começar por 2, 3 ou 9 (fixo/móvel)
      else if (cleaned.length == 9 && RegExp(r'^[239]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
      // Número português com 8 dígitos (fixo antigo)
      else if (cleaned.length == 8 && RegExp(r'^[2-3]').hasMatch(cleaned)) {
        cleaned = '+351$cleaned';
      }
      // Outros países comuns (adicionar conforme necessário)
      else if (cleaned.length == 10 && cleaned.startsWith('1')) {
        // EUA/Canadá: +1XXXXXXXXXX
        cleaned = '+$cleaned';
      }
      else if (cleaned.length == 11 && cleaned.startsWith('44')) {
        // Reino Unido: +44XXXXXXXXXX
        cleaned = '+$cleaned';
      }
      else if (cleaned.length == 11 && cleaned.startsWith('33')) {
        // França: +33XXXXXXXXX
        cleaned = '+$cleaned';
      }
      else if (cleaned.length == 12 && cleaned.startsWith('49')) {
        // Alemanha: +49XXXXXXXXXXX
        cleaned = '+$cleaned';
      }
      else if (cleaned.length == 11 && cleaned.startsWith('34')) {
        // Espanha: +34XXXXXXXXX
        cleaned = '+$cleaned';
      }
      else if (cleaned.length == 13 && cleaned.startsWith('55')) {
        // Brasil: +55XXXXXXXXXXX
        cleaned = '+$cleaned';
      }
    }
    
    // Validação final: deve ter pelo menos 8 dígitos após o código do país
    if (cleaned.startsWith('+') && cleaned.length >= 10) {
      return cleaned;
    }
    
    // Se não conseguiu normalizar, retornar vazio
    return '';
  }

  // Encontrar utilizadores registados com base nos contactos
  Future<List<Map<String, dynamic>>> findRegisteredFriends() async {
    try {
      final contacts = await getDeviceContacts();
      final phoneNumbers = extractPhoneNumbers(contacts);
      
      if (phoneNumbers.isEmpty) {
        return [];
      }

      // Procurar utilizadores com estes números de telefone (batched whereIn queries)
      final registeredUsers = <Map<String, dynamic>>[];
      const batchSize = 10; // Firestore whereIn limit
      for (int i = 0; i < phoneNumbers.length; i += batchSize) {
        final slice = phoneNumbers.skip(i).take(batchSize).toList();
        try {
          final snap = await _firestore
              .collection('users')
              .where('phone_number', whereIn: slice)
              .where('is_private', isEqualTo: false)
              .get();
          for (final doc in snap.docs) {
            registeredUsers.add({'id': doc.id, ...doc.data()});
          }
        } catch (e) {
          debugPrint('❌ Firestore lookup falhou (lote ${i ~/ batchSize}): $e');
        }
      }
      debugPrint('✅ Encontrados ${registeredUsers.length} utilizadores para ${phoneNumbers.length} números');

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
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return;

      final registeredFriends = await findRegisteredFriends();
      
      // Guardar cache dos contactos encontrados (opcional)
      // Isto pode ser útil para mostrar sugestões de amigos
      for (final friend in registeredFriends) {
        // Verificar se já está nos favoritos
  final existingFavorite = await _favoritesRepo.isFavorite(currentUserId, friend['id']);

        // Se não está nos favoritos, pode criar uma sugestão (opcional)
        if (!existingFavorite) {
          // FUTURE: Implement suggestion system if needed
        }
      }
    } catch (e) {
      // Falhar silenciosamente para não interromper a app
      MonitoringService.logErrorStatic('sync_contacts', e, stackTrace: StackTrace.current);
    }
  }

  // Obter sugestões de amigos baseadas nos contactos
  Future<List<Map<String, dynamic>>> getFriendSuggestions() async {
    try {
      final currentUserId = AuthService.getCurrentUserId();
      if (currentUserId == null) return [];

      final registeredFriends = await findRegisteredFriends();
      
      // Filtrar utilizadores que já são amigos ou têm pedidos pendentes
      final suggestions = <Map<String, dynamic>>[];
      
      for (final friend in registeredFriends) {
        // Verificar se já está nos favoritos
  final existingFavorite = await _favoritesRepo.isFavorite(currentUserId, friend['id']);

        // Se não está nos favoritos, adicionar às sugestões
        if (!existingFavorite && friend['id'] != currentUserId) {
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