import 'dart:async';
import 'dart:collection';
import 'package:mywishstash/services/monitoring_service.dart';

/// Rate limiter service to prevent abuse and protect against spam
class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  factory RateLimiterService() => _instance;
  RateLimiterService._internal();

  final Map<String, Queue<DateTime>> _requestHistory = {};
  final Map<String, DateTime> _lastRequestTime = {};
  final Map<String, int> _requestCounts = {};

  /// Rate limit configurations for different operations
  static const Map<String, RateLimitConfig> _configs = {
    'login': RateLimitConfig(maxRequests: 5, windowMinutes: 5, cooldownMinutes: 15),
    'register': RateLimitConfig(maxRequests: 3, windowMinutes: 10, cooldownMinutes: 30),
    'send_otp': RateLimitConfig(maxRequests: 3, windowMinutes: 5, cooldownMinutes: 10),
    'verify_otp': RateLimitConfig(maxRequests: 5, windowMinutes: 5, cooldownMinutes: 15),
    'password_reset': RateLimitConfig(maxRequests: 2, windowMinutes: 10, cooldownMinutes: 60),
    'create_wishlist': RateLimitConfig(maxRequests: 10, windowMinutes: 5, cooldownMinutes: 1),
    'upload_image': RateLimitConfig(maxRequests: 20, windowMinutes: 10, cooldownMinutes: 2),
    'add_item': RateLimitConfig(maxRequests: 30, windowMinutes: 5, cooldownMinutes: 1),
    'search_users': RateLimitConfig(maxRequests: 50, windowMinutes: 5, cooldownMinutes: 1),
    'web_scraping': RateLimitConfig(maxRequests: 10, windowMinutes: 10, cooldownMinutes: 5),
  };

  /// Check if an operation is allowed for a given identifier
  Future<RateLimitResult> checkRateLimit(String operation, String identifier) async {
    final config = _configs[operation];
    if (config == null) {
      MonitoringService.logErrorStatic(
        'Unknown operation: $operation',
        Exception('RateLimiter unknown operation'),
        context: 'RateLimiter',
      );
      return RateLimitResult.allowed();
    }

    final key = '${operation}_$identifier';
    final now = DateTime.now();
    
    // Initialize request history if needed
    _requestHistory[key] ??= Queue<DateTime>();
    
    final history = _requestHistory[key]!;
    
    // Clean old requests outside the window
    final windowStart = now.subtract(Duration(minutes: config.windowMinutes));
    while (history.isNotEmpty && history.first.isBefore(windowStart)) {
      history.removeFirst();
    }
    
    // Check if we're in cooldown period
    final lastRequest = _lastRequestTime[key];
    if (lastRequest != null) {
      final cooldownEnd = lastRequest.add(Duration(minutes: config.cooldownMinutes));
      if (now.isBefore(cooldownEnd)) {
        final remainingTime = cooldownEnd.difference(now);
        
        MonitoringService.logInfoStatic(
          'RateLimiter',
          'Rate limit cooldown active for $operation:$identifier, remaining: ${remainingTime.inMinutes}m',
        );
        
        return RateLimitResult.blocked(
          'Operação temporariamente bloqueada. Tente novamente em ${remainingTime.inMinutes + 1} minutos.',
          remainingTime,
        );
      }
    }
    
    // Check request count in current window
    if (history.length >= config.maxRequests) {
      final oldestRequest = history.first;
      final remainingTime = oldestRequest.add(Duration(minutes: config.windowMinutes)).difference(now);
      
      // Start cooldown
      _lastRequestTime[key] = now;
      
      MonitoringService.logWarningStatic(
        'RateLimiter',
        'Rate limit exceeded for $operation:$identifier (${history.length}/${config.maxRequests})',
      );
      
      return RateLimitResult.blocked(
        'Muitas tentativas. Aguarde ${remainingTime.inMinutes + 1} minutos.',
        remainingTime,
      );
    }
    
    // Allow request and record it
    history.add(now);
    _requestCounts[key] = (_requestCounts[key] ?? 0) + 1;
    
    MonitoringService.logInfoStatic(
      'RateLimiter',
      'Request allowed for $operation:$identifier (${history.length}/${config.maxRequests})',
    );
    
    return RateLimitResult.allowed();
  }

  /// Get current status for an operation/identifier
  RateLimitStatus getStatus(String operation, String identifier) {
    final config = _configs[operation];
    if (config == null) {
      return RateLimitStatus(requestsRemaining: 999, windowReset: DateTime.now());
    }

    final key = '${operation}_$identifier';
    final history = _requestHistory[key] ?? Queue<DateTime>();
    final now = DateTime.now();
    
    // Clean old requests
    final windowStart = now.subtract(Duration(minutes: config.windowMinutes));
    final recentRequests = history.where((time) => time.isAfter(windowStart)).length;
    
    final requestsRemaining = (config.maxRequests - recentRequests).clamp(0, config.maxRequests);
    final windowReset = history.isNotEmpty 
        ? history.first.add(Duration(minutes: config.windowMinutes))
        : now;
    
    return RateLimitStatus(
      requestsRemaining: requestsRemaining,
      windowReset: windowReset,
    );
  }

  /// Reset rate limit for a specific operation/identifier (admin use)
  void resetRateLimit(String operation, String identifier) {
    final key = '${operation}_$identifier';
    _requestHistory.remove(key);
    _lastRequestTime.remove(key);
    _requestCounts.remove(key);
    
    MonitoringService.logInfoStatic(
      'RateLimiter',
      'Rate limit reset for $operation:$identifier',
    );
  }

  /// Clean up old data (call periodically)
  void cleanup() {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _requestHistory.entries) {
      final key = entry.key;
      final history = entry.value;
      
      // Remove entries older than 24 hours
      final cutoff = now.subtract(const Duration(hours: 24));
      while (history.isNotEmpty && history.first.isBefore(cutoff)) {
        history.removeFirst();
      }
      
      // If history is empty, mark key for removal
      if (history.isEmpty) {
        keysToRemove.add(key);
      }
    }
    
    // Remove empty entries
    for (final key in keysToRemove) {
      _requestHistory.remove(key);
      _lastRequestTime.remove(key);
      _requestCounts.remove(key);
    }
    
    if (keysToRemove.isNotEmpty) {
      MonitoringService.logInfoStatic(
        'RateLimiter',
        'Cleaned up ${keysToRemove.length} expired rate limit entries',
      );
    }
  }

  /// Get statistics for monitoring
  Map<String, dynamic> getStatistics() {
    final stats = <String, dynamic>{
      'active_limits': _requestHistory.length,
      'total_requests': _requestCounts.values.fold(0, (sum, count) => sum + count),
      'operations': <String, dynamic>{},
    };
    
    for (final operation in _configs.keys) {
      final operationRequests = _requestCounts.entries
          .where((entry) => entry.key.startsWith('${operation}_'))
          .fold(0, (sum, entry) => sum + entry.value);
      
      stats['operations'][operation] = operationRequests;
    }
    
    return stats;
  }
}

/// Rate limit configuration
class RateLimitConfig {
  final int maxRequests;
  final int windowMinutes;
  final int cooldownMinutes;

  const RateLimitConfig({
    required this.maxRequests,
    required this.windowMinutes,
    required this.cooldownMinutes,
  });
}

/// Rate limit check result
class RateLimitResult {
  final bool isAllowed;
  final String? message;
  final Duration? retryAfter;

  const RateLimitResult._({
    required this.isAllowed,
    this.message,
    this.retryAfter,
  });

  factory RateLimitResult.allowed() => const RateLimitResult._(isAllowed: true);
  
  factory RateLimitResult.blocked(String message, Duration retryAfter) => 
      RateLimitResult._(
        isAllowed: false,
        message: message,
        retryAfter: retryAfter,
      );
}

/// Current rate limit status
class RateLimitStatus {
  final int requestsRemaining;
  final DateTime windowReset;

  const RateLimitStatus({
    required this.requestsRemaining,
    required this.windowReset,
  });
}

/// Mixin for easy rate limiting integration
mixin RateLimited {
  final _rateLimiter = RateLimiterService();

  Future<bool> checkRateLimit(String operation, String identifier, {
    void Function(String)? onBlocked,
  }) async {
    final result = await _rateLimiter.checkRateLimit(operation, identifier);
    
    if (!result.isAllowed && onBlocked != null) {
      onBlocked(result.message ?? 'Rate limit exceeded');
    }
    
    return result.isAllowed;
  }
}