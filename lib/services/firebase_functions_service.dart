import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firebase Cloud Functions Service
/// Firebase Cloud Functions service - serverless function calls with monitoring
class FirebaseFunctionsService {
  static final FirebaseFunctionsService _instance = FirebaseFunctionsService._internal();
  factory FirebaseFunctionsService() => _instance;
  FirebaseFunctionsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Delete current user account
  Future<void> deleteUserAccount({int retry = 0}) async {
    const maxRetries = 3;
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      debugPrint('🗑️ Calling deleteUser Cloud Function');
      
      final callable = _functions.httpsCallable('deleteUser');
      final result = await callable.call();
      
      debugPrint('✅ User deletion completed: ${result.data}');
    } catch (e) {
      debugPrint('❌ Error deleting user account: $e');
      
      if (e is FirebaseFunctionsException) {
        debugPrint('Function error code: ${e.code}');
        debugPrint('Function error message: ${e.message}');
        debugPrint('Function error details: ${e.details}');
        
        // Handle specific error cases
        switch (e.code) {
          case 'unauthenticated':
            throw Exception('Utilizador não autenticado. Por favor, faça login novamente.');
          case 'permission-denied':
            // Occasionally transient if security rules just changed; retry with backoff
            if (retry < maxRetries) {
              final delay = Duration(milliseconds: 400 * (retry + 1));
              debugPrint('🔁 permission-denied retry #${retry + 1} in ${delay.inMilliseconds}ms');
              await Future.delayed(delay);
              return deleteUserAccount(retry: retry + 1);
            }
            throw Exception('Não tem permissão para apagar esta conta.');
          case 'resource-exhausted':
            throw Exception('Limite diário de operações atingido. Tente novamente amanhã.');
          default:
            throw Exception('Erro ao apagar conta: ${e.message}');
        }
      }
      
      rethrow;
    }
  }

  /// Secure scraper for extracting product info from URLs
  Future<Map<String, dynamic>> scrapeUrl(String url) async {
    try {
      debugPrint('🔍 Calling secureScraper Cloud Function for URL: $url');
      
      final callable = _functions.httpsCallable('secureScraper');
      final result = await callable.call({'url': url});
      
      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ Scraping completed successfully');
      
      return data;
    } catch (e) {
      debugPrint('❌ Error scraping URL: $e');
      
      if (e is FirebaseFunctionsException) {
        debugPrint('Function error code: ${e.code}');
        debugPrint('Function error message: ${e.message}');
        debugPrint('Function error details: ${e.details}');
        
        // Handle specific error cases
        switch (e.code) {
          case 'invalid-argument':
            throw Exception('URL inválida. Por favor, verifique o link.');
          case 'permission-denied':
            throw Exception('Domínio não permitido por razões de segurança.');
          case 'resource-exhausted':
            throw Exception('Limite diário de operações atingido. Tente novamente amanhã.');
          case 'deadline-exceeded':
            throw Exception('Timeout: O site demorou muito para responder.');
          default:
            // Return fallback data for scraping errors
            return {
              'title': 'Título não encontrado',
              'price': '0.00',
              'currency': 'EUR',
              'image': '',
              'description': '',
              'category': 'Outros',
              'availability': 'Desconhecido',
              'error': e.message ?? 'Erro desconhecido ao fazer scraping'
            };
        }
      }
      
      // Return fallback data for unexpected errors
      return {
        'title': 'Título não encontrado',
        'price': '0.00',
        'currency': 'EUR',
        'image': '',
        'description': '',
        'category': 'Outros',
        'availability': 'Desconhecido',
        'error': 'Erro inesperado ao fazer scraping'
      };
    }
  }

  /// Lightweight enrichment (metadata + cache) - preferido para fluxo de share
  Future<Map<String, dynamic>> enrichLink(String url) async {
    try {
      debugPrint('✨ Calling enrichLink Cloud Function for URL: $url');
      final callable = _functions.httpsCallable('enrichLink');
      final result = await callable.call({'url': url});
      final data = Map<String, dynamic>.from(result.data);
      return data;
    } catch (e) {
      debugPrint('❌ Error enriching URL: $e');
      if (e is FirebaseFunctionsException && e.code == 'resource-exhausted') {
        return {
          'title': '',
          'price': null,
          'currency': 'EUR',
          'image': '',
          'sourceDomain': '',
          'canonicalUrl': url,
          'rateLimited': true,
          'error': 'Limite de enriquecimentos atingido. Tente novamente mais tarde.'
        };
      }
      // Fallback minimal structure; cliente pode continuar com campos manuais
      return {
        'title': '',
        'price': null,
        'currency': 'EUR',
        'image': '',
        'sourceDomain': '',
        'canonicalUrl': url,
        'error': e.toString(),
      };
    }
  }

}