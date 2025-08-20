import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wishlist_app/services/error_service.dart';

/// Serviço de cache inteligente para otimização de performance
/// Implementa cache com invalidação automática e estratégias de expiração
class CacheService {
  static const String _wishlistsKey = 'cached_wishlists';
  static const String _userProfileKey = 'cached_user_profile';
  static const String _publicWishlistsKey = 'cached_public_wishlists';
  static const String _publicUsersKey = 'cached_public_users';
  static const String _friendsKey = 'cached_friends';
  static const String _appStatsKey = 'cached_app_stats';
  
  static const Duration _defaultExpiry = Duration(hours: 1);
  static const Duration _shortExpiry = Duration(minutes: 15);
  static const Duration _longExpiry = Duration(hours: 6);

  // =====================================================
  // 1. CACHE DE WISHLISTS
  // =====================================================

  /// Cache de wishlists do usuário
  static Future<void> cacheWishlists(String userId, List<Map<String, dynamic>> wishlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': wishlists,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
        'version': '1.0',
      };
      
      await prefs.setString('${_wishlistsKey}_$userId', jsonEncode(cacheData));
    } catch (e) {
      ErrorService.logError('cache_wishlists', e, StackTrace.current);
    }
  }

  /// Obtém wishlists do cache
  static Future<List<Map<String, dynamic>>?> getCachedWishlists(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_wishlistsKey}_$userId');
      
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        final cachedUserId = cacheData['userId'];
        
        // Verificar se cache é válido e do usuário correto
        if (DateTime.now().difference(timestamp) < _defaultExpiry && 
            cachedUserId == userId) {
          return List<Map<String, dynamic>>.from(cacheData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ErrorService.logError('get_cached_wishlists', e, StackTrace.current);
      return null;
    }
  }

  /// Invalida cache de wishlists
  static Future<void> invalidateWishlistsCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_wishlistsKey}_$userId');
    } catch (e) {
      ErrorService.logError('invalidate_wishlists_cache', e, StackTrace.current);
    }
  }

  // =====================================================
  // 2. CACHE DE PERFIL DO USUÁRIO
  // =====================================================

  /// Cache do perfil do usuário
  static Future<void> cacheUserProfile(String userId, Map<String, dynamic> profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': profile,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
      
      await prefs.setString('${_userProfileKey}_$userId', jsonEncode(cacheData));
    } catch (e) {
      ErrorService.logError('cache_user_profile', e, StackTrace.current);
    }
  }

  /// Obtém perfil do usuário do cache
  static Future<Map<String, dynamic>?> getCachedUserProfile(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_userProfileKey}_$userId');
      
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _defaultExpiry) {
          return Map<String, dynamic>.from(cacheData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ErrorService.logError('get_cached_user_profile', e, StackTrace.current);
      return null;
    }
  }

  /// Invalida cache do perfil do usuário
  static Future<void> invalidateUserProfileCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_userProfileKey}_$userId');
    } catch (e) {
      ErrorService.logError('invalidate_user_profile_cache', e, StackTrace.current);
    }
  }

  // =====================================================
  // 3. CACHE DE DADOS PÚBLICOS
  // =====================================================

  /// Cache de wishlists públicas
  static Future<void> cachePublicWishlists(List<Map<String, dynamic>> wishlists) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': wishlists,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
      
      await prefs.setString(_publicWishlistsKey, jsonEncode(cacheData));
    } catch (e) {
      ErrorService.logError('cache_public_wishlists', e, StackTrace.current);
    }
  }

  /// Obtém wishlists públicas do cache
  static Future<List<Map<String, dynamic>>?> getCachedPublicWishlists() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_publicWishlistsKey);
      
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _shortExpiry) {
          return List<Map<String, dynamic>>.from(cacheData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ErrorService.logError('get_cached_public_wishlists', e, StackTrace.current);
      return null;
    }
  }

  /// Cache de usuários públicos
  static Future<void> cachePublicUsers(List<Map<String, dynamic>> users) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': users,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
      
      await prefs.setString(_publicUsersKey, jsonEncode(cacheData));
    } catch (e) {
      ErrorService.logError('cache_public_users', e, StackTrace.current);
    }
  }

  /// Obtém usuários públicos do cache
  static Future<List<Map<String, dynamic>>?> getCachedPublicUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_publicUsersKey);
      
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _longExpiry) {
          return List<Map<String, dynamic>>.from(cacheData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ErrorService.logError('get_cached_public_users', e, StackTrace.current);
      return null;
    }
  }

  // =====================================================
  // 4. CACHE DE AMIGOS
  // =====================================================

  /// Cache de amigos
  static Future<void> cacheFriends(String userId, List<Map<String, dynamic>> friends) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': friends,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
        'version': '1.0',
      };
      
      await prefs.setString('${_friendsKey}_$userId', jsonEncode(cacheData));
    } catch (e) {
      ErrorService.logError('cache_friends', e, StackTrace.current);
    }
  }

  /// Obtém amigos do cache
  static Future<List<Map<String, dynamic>>?> getCachedFriends(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_friendsKey}_$userId');
      
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        final cachedUserId = cacheData['userId'];
        
        if (DateTime.now().difference(timestamp) < _defaultExpiry && 
            cachedUserId == userId) {
          return List<Map<String, dynamic>>.from(cacheData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ErrorService.logError('get_cached_friends', e, StackTrace.current);
      return null;
    }
  }

  /// Invalida cache de amigos
  static Future<void> invalidateFriendsCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_friendsKey}_$userId');
    } catch (e) {
      ErrorService.logError('invalidate_friends_cache', e, StackTrace.current);
    }
  }

  // =====================================================
  // 5. CACHE DE ESTATÍSTICAS
  // =====================================================

  /// Cache de estatísticas da aplicação
  static Future<void> cacheAppStats(Map<String, dynamic> stats) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': stats,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'version': '1.0',
      };
      
      await prefs.setString(_appStatsKey, jsonEncode(cacheData));
    } catch (e) {
      ErrorService.logError('cache_app_stats', e, StackTrace.current);
    }
  }

  /// Obtém estatísticas da aplicação do cache
  static Future<Map<String, dynamic>?> getCachedAppStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_appStatsKey);
      
      if (cached != null) {
        final cacheData = jsonDecode(cached);
        final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
        
        if (DateTime.now().difference(timestamp) < _longExpiry) {
          return Map<String, dynamic>.from(cacheData['data']);
        }
      }
      
      return null;
    } catch (e) {
      ErrorService.logError('get_cached_app_stats', e, StackTrace.current);
      return null;
    }
  }

  // =====================================================
  // 6. FUNÇÕES DE UTILIDADE
  // =====================================================

  /// Invalida todo o cache de um usuário
  static Future<void> invalidateAllUserCache(String userId) async {
    try {
      await Future.wait([
        invalidateWishlistsCache(userId),
        invalidateUserProfileCache(userId),
        invalidateFriendsCache(userId),
      ]);
    } catch (e) {
      ErrorService.logError('invalidate_all_user_cache', e, StackTrace.current);
    }
  }

  /// Invalida todo o cache público
  static Future<void> invalidateAllPublicCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_publicWishlistsKey),
        prefs.remove(_publicUsersKey),
        prefs.remove(_appStatsKey),
      ]);
    } catch (e) {
      ErrorService.logError('invalidate_all_public_cache', e, StackTrace.current);
    }
  }

  /// Limpa todo o cache
  static Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_wishlistsKey) ||
        key.startsWith(_userProfileKey) ||
        key.startsWith(_publicWishlistsKey) ||
        key.startsWith(_publicUsersKey) ||
        key.startsWith(_friendsKey) ||
        key == _appStatsKey
      ).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
    } catch (e) {
      ErrorService.logError('clear_all_cache', e, StackTrace.current);
    }
  }

  /// Obtém estatísticas do cache
  static Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_wishlistsKey) ||
        key.startsWith(_userProfileKey) ||
        key.startsWith(_publicWishlistsKey) ||
        key.startsWith(_publicUsersKey) ||
        key.startsWith(_friendsKey) ||
        key == _appStatsKey
      ).toList();

      int totalSize = 0;
      int expiredEntries = 0;
      int validEntries = 0;

      for (final key in cacheKeys) {
        final cached = prefs.getString(key);
        if (cached != null) {
          totalSize += cached.length;
          
          try {
            final cacheData = jsonDecode(cached);
            final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
            
            if (DateTime.now().difference(timestamp) < _defaultExpiry) {
              validEntries++;
            } else {
              expiredEntries++;
            }
          } catch (e) {
            expiredEntries++;
          }
        }
      }

      return {
        'total_entries': cacheKeys.length,
        'valid_entries': validEntries,
        'expired_entries': expiredEntries,
        'total_size_bytes': totalSize,
        'total_size_mb': (totalSize / 1024 / 1024).toStringAsFixed(2),
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ErrorService.logError('get_cache_stats', e, StackTrace.current);
      return {};
    }
  }

  /// Limpa entradas expiradas do cache
  static Future<void> cleanupExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((key) => 
        key.startsWith(_wishlistsKey) ||
        key.startsWith(_userProfileKey) ||
        key.startsWith(_publicWishlistsKey) ||
        key.startsWith(_publicUsersKey) ||
        key.startsWith(_friendsKey) ||
        key == _appStatsKey
      ).toList();

      int cleanedEntries = 0;

      for (final key in cacheKeys) {
        final cached = prefs.getString(key);
        if (cached != null) {
          try {
            final cacheData = jsonDecode(cached);
            final timestamp = DateTime.fromMillisecondsSinceEpoch(cacheData['timestamp']);
            
            // Verificar se expirou baseado no tipo de cache
            Duration expiry = _defaultExpiry;
            if (key == _publicWishlistsKey) {
              expiry = _shortExpiry;
            } else if (key == _publicUsersKey || key == _appStatsKey) {
              expiry = _longExpiry;
            }
            
            if (DateTime.now().difference(timestamp) > expiry) {
              await prefs.remove(key);
              cleanedEntries++;
            }
          } catch (e) {
            // Se não conseguir decodificar, remover entrada corrompida
            await prefs.remove(key);
            cleanedEntries++;
          }
        }
      }

      if (cleanedEntries > 0) {
        debugPrint('Cache cleanup: removed $cleanedEntries expired entries');
      }
    } catch (e) {
      ErrorService.logError('cleanup_expired_cache', e, StackTrace.current);
    }
  }
}
