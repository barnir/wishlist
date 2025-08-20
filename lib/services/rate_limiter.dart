import 'dart:async';
import 'dart:collection';

/// Serviço de Rate Limiting para proteger contra abuso da API
///
/// Implementa rate limiting por:
/// - Endpoint específico
/// - IP do usuário
/// - Tipo de operação
/// - Janela de tempo configurável
class RateLimiter {
  // Cache de requests por chave (endpoint + user_id)
  static final Map<String, Queue<DateTime>> _requestCache = {};
  
  // Configurações padrão
  // Configurações padrão (não usadas diretamente, mas mantidas para referência)
  // static const int _defaultMaxRequests = 10;
  // static const Duration _defaultWindow = Duration(minutes: 1);
  
  // ⚠️ CONFIGURAÇÕES OTIMIZADAS PARA PLANO GRATUITO:
  // - Supabase: 500k Edge Function calls/mês
  // - ScraperAPI: 1k requests/mês
  // - Rate limiting conservador para não exceder limites
  static const Map<String, RateLimitConfig> _endpointConfigs = {
    'scrape': RateLimitConfig(maxRequests: 3, window: Duration(minutes: 5)), // Conservador
    'upload': RateLimitConfig(maxRequests: 2, window: Duration(minutes: 10)), // Muito conservador
    'auth': RateLimitConfig(maxRequests: 3, window: Duration(minutes: 15)), // Conservador
    'search': RateLimitConfig(maxRequests: 10, window: Duration(minutes: 2)), // Moderado
    'default': RateLimitConfig(maxRequests: 5, window: Duration(minutes: 5)), // Conservador
  };

  /// Verifica se uma requisição pode ser feita
  static bool canMakeRequest(String endpoint, {String? userId}) {
    final key = _generateKey(endpoint, userId);
    final config = _getConfig(endpoint);
    
    final now = DateTime.now();
    final requests = _requestCache[key] ?? Queue<DateTime>();
    
    // Remover requests fora da janela de tempo
    while (requests.isNotEmpty && 
           now.difference(requests.first) > config.window) {
      requests.removeFirst();
    }
    
    // Verificar se ainda há slots disponíveis
    if (requests.length >= config.maxRequests) {
      return false;
    }
    
    // Adicionar nova requisição
    requests.add(now);
    _requestCache[key] = requests;
    
    return true;
  }

  /// Aguarda até que uma requisição possa ser feita
  static Future<void> waitForSlot(String endpoint, {String? userId}) async {
    while (!canMakeRequest(endpoint, userId: userId)) {
      final config = _getConfig(endpoint);
      final key = _generateKey(endpoint, userId);
      final requests = _requestCache[key] ?? Queue<DateTime>();
      
      if (requests.isNotEmpty) {
        final oldestRequest = requests.first;
        // final config = _getConfig(endpoint);
        final nextAvailable = oldestRequest.add(config.window);
        final waitTime = nextAvailable.difference(DateTime.now());
        
        if (waitTime.isNegative) {
          // Limpar requests antigos e tentar novamente
          _cleanOldRequests(key);
          continue;
        }
        
        // Aguardar até o próximo slot disponível
        await Future.delayed(waitTime);
      } else {
        // Sem requests na fila, pode fazer imediatamente
        break;
      }
    }
  }

  /// Registra uma requisição (para tracking)
  static void recordRequest(String endpoint, {String? userId}) {
    final key = _generateKey(endpoint, userId);
    final now = DateTime.now();
    
    if (!_requestCache.containsKey(key)) {
      _requestCache[key] = Queue<DateTime>();
    }
    
    _requestCache[key]!.add(now);
  }

  /// Obtém estatísticas de rate limiting
  static Map<String, dynamic> getStats(String endpoint, {String? userId}) {
    final key = _generateKey(endpoint, userId);
    final requests = _requestCache[key] ?? Queue<DateTime>();
    final config = _getConfig(endpoint);
    final now = DateTime.now();
    
    // Filtrar requests válidos
    final validRequests = requests.where(
      (time) => now.difference(time) <= config.window
    ).length;
    
    return {
      'endpoint': endpoint,
      'userId': userId,
      'currentRequests': validRequests,
      'maxRequests': config.maxRequests,
      'windowSeconds': config.window.inSeconds,
      'remainingRequests': config.maxRequests - validRequests,
      'canMakeRequest': validRequests < config.maxRequests,
    };
  }

  /// Reseta o rate limiting para um endpoint/usuário
  static void reset(String endpoint, {String? userId}) {
    final key = _generateKey(endpoint, userId);
    _requestCache.remove(key);
  }

  /// Limpa todos os dados de rate limiting
  static void clearAll() {
    _requestCache.clear();
  }

  /// Limpa requests antigos para uma chave específica
  static void _cleanOldRequests(String key) {
    if (!_requestCache.containsKey(key)) return;
    
    final requests = _requestCache[key]!;
    final now = DateTime.now();
    
    // Remover requests antigos (mais de 1 hora)
    while (requests.isNotEmpty && 
           now.difference(requests.first) > Duration(hours: 1)) {
      requests.removeFirst();
    }
    
    // Se não há mais requests, remover a chave
    if (requests.isEmpty) {
      _requestCache.remove(key);
    }
  }

  /// Gera chave única para cache
  static String _generateKey(String endpoint, String? userId) {
    return userId != null ? '${endpoint}_$userId' : '${endpoint}_anonymous';
  }

  /// Obtém configuração para um endpoint
  static RateLimitConfig _getConfig(String endpoint) {
    return _endpointConfigs[endpoint] ?? _endpointConfigs['default']!;
  }

  /// Limpa periodicamente requests antigos
  static void startCleanupTimer() {
    Timer.periodic(Duration(minutes: 5), (timer) {
      final keysToRemove = <String>[];
      
      for (final entry in _requestCache.entries) {
        final requests = entry.value;
        final now = DateTime.now();
        
        // Remover requests mais antigos que 1 hora
        while (requests.isNotEmpty && 
               now.difference(requests.first) > Duration(hours: 1)) {
          requests.removeFirst();
        }
        
        // Marcar para remoção se não há mais requests
        if (requests.isEmpty) {
          keysToRemove.add(entry.key);
        }
      }
      
      // Remover chaves vazias
      for (final key in keysToRemove) {
        _requestCache.remove(key);
      }
    });
  }
}

/// Configuração de rate limiting para um endpoint
class RateLimitConfig {
  final int maxRequests;
  final Duration window;
  
  const RateLimitConfig({
    required this.maxRequests,
    required this.window,
  });
}

/// Mixin para adicionar rate limiting aos serviços
mixin RateLimitMixin {
  /// Executa uma função com rate limiting
  Future<T> withRateLimit<T>(
    String endpoint, {
    String? userId,
    required Future<T> Function() operation,
  }) async {
    // Aguardar slot disponível
    await RateLimiter.waitForSlot(endpoint, userId: userId);
    
    try {
      // Registrar requisição
      RateLimiter.recordRequest(endpoint, userId: userId);
      
      // Executar operação
      return await operation();
    } catch (e) {
      // Em caso de erro, não contar contra o rate limit
      RateLimiter.reset(endpoint, userId: userId);
      rethrow;
    }
  }

  /// Verifica se pode fazer requisição sem aguardar
  bool canMakeRequest(String endpoint, {String? userId}) {
    return RateLimiter.canMakeRequest(endpoint, userId: userId);
  }

  /// Obtém estatísticas de rate limiting
  Map<String, dynamic> getRateLimitStats(String endpoint, {String? userId}) {
    return RateLimiter.getStats(endpoint, userId: userId);
  }
}
