import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firebase Cloud Functions Service
/// Replaces SupabaseFunctionsService with Firebase Cloud Functions
class FirebaseFunctionsService {
  static final FirebaseFunctionsService _instance = FirebaseFunctionsService._internal();
  factory FirebaseFunctionsService() => _instance;
  FirebaseFunctionsService._internal();

  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Delete current user account
  Future<void> deleteUserAccount() async {
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

  /// Get health status and usage statistics
  Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      debugPrint('📊 Calling healthCheck Cloud Function');
      
      final callable = _functions.httpsCallable('healthCheck');
      final result = await callable.call();
      
      final data = Map<String, dynamic>.from(result.data);
      debugPrint('✅ Health check completed');
      
      return data;
    } catch (e) {
      debugPrint('❌ Error getting health status: $e');
      
      return {
        'status': 'error',
        'error': e.toString(),
        'usage': {
          'reads': 0,
          'writes': 0,
          'functions': 0,
        },
        'limits': {
          'reads': 50000,
          'writes': 20000,
          'functions': 66666,
        }
      };
    }
  }

  /// Check if we're approaching usage limits
  Future<bool> isApproachingLimits() async {
    try {
      final health = await getHealthStatus();
      
      if (health['status'] != 'healthy') return false;
      
      final usage = health['usage'] as Map<String, dynamic>;
      final limits = health['limits'] as Map<String, dynamic>;
      
      // Check if we're at 80% of any limit
      final readPercent = (usage['reads'] as num) / (limits['reads'] as num);
      final writePercent = (usage['writes'] as num) / (limits['writes'] as num);
      final functionPercent = (usage['functions'] as num) / (limits['functions'] as num);
      
      return readPercent >= 0.8 || writePercent >= 0.8 || functionPercent >= 0.8;
    } catch (e) {
      debugPrint('❌ Error checking usage limits: $e');
      return false;
    }
  }

  /// Get usage percentage for display
  Future<Map<String, double>> getUsagePercentages() async {
    try {
      final health = await getHealthStatus();
      
      if (health['status'] != 'healthy') {
        return {
          'reads': 0.0,
          'writes': 0.0,
          'functions': 0.0,
        };
      }
      
      final usage = health['usage'] as Map<String, dynamic>;
      final limits = health['limits'] as Map<String, dynamic>;
      
      return {
        'reads': ((usage['reads'] as num) / (limits['reads'] as num) * 100),
        'writes': ((usage['writes'] as num) / (limits['writes'] as num) * 100),
        'functions': ((usage['functions'] as num) / (limits['functions'] as num) * 100),
      };
    } catch (e) {
      debugPrint('❌ Error getting usage percentages: $e');
      return {
        'reads': 0.0,
        'writes': 0.0,
        'functions': 0.0,
      };
    }
  }

  /// Show usage warning if approaching limits
  Future<void> checkAndShowUsageWarning(BuildContext context) async {
    try {
      final isApproaching = await isApproachingLimits();
      
      if (isApproaching && context.mounted) {
        final percentages = await getUsagePercentages();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️ Atenção: Aproximando dos limites diários'),
                Text('Reads: ${percentages['reads']!.toStringAsFixed(1)}%'),
                Text('Writes: ${percentages['writes']!.toStringAsFixed(1)}%'),
                Text('Functions: ${percentages['functions']!.toStringAsFixed(1)}%'),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
              textColor: Colors.white,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error checking usage warning: $e');
    }
  }
}