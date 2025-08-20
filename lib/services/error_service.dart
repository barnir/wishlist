import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Serviço centralizado para tratamento de erros
///
/// Fornece:
/// - Tradução de erros para português
/// - Logging estruturado
/// - Categorização de erros
/// - Sugestões de resolução
class ErrorService {
  // Categorias de erro
  static const String _authError = 'auth';
  static const String _networkError = 'network';
  static const String _databaseError = 'database';
  static const String _storageError = 'storage';
  static const String _validationError = 'validation';
  static const String _rateLimitError = 'rate_limit';
  static const String _unknownError = 'unknown';

  /// Converte erro técnico em mensagem amigável
  static String getReadableError(dynamic error, {String? context}) {
    try {
      // Erros de autenticação
      if (error is AuthException) {
        return _handleAuthError(error);
      }

      // Erros do Supabase
      if (error is PostgrestException) {
        return _handleDatabaseError(error);
      }

      // Erros de storage
      if (error is StorageException) {
        return _handleStorageError(error);
      }

      // Erros de rede
      if (error.toString().contains('SocketException') ||
          error.toString().contains('NetworkException') ||
          error.toString().contains('TimeoutException')) {
        return _handleNetworkError(error);
      }

      // Erros de rate limiting
      if (error.toString().contains('rate limit') ||
          error.toString().contains('too many requests')) {
        return _handleRateLimitError(error);
      }

      // Erros de validação
      if (error.toString().contains('validation') ||
          error.toString().contains('invalid')) {
        return _handleValidationError(error);
      }

      // Erro desconhecido
      return _handleUnknownError(error, context);
    } catch (e) {
      return 'Ocorreu um erro inesperado. Tente novamente.';
    }
  }

  /// Obtém categoria do erro
  static String getErrorCategory(dynamic error) {
    if (error is AuthException) return _authError;
    if (error is PostgrestException) return _databaseError;
    if (error is StorageException) return _storageError;
    
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socket') || errorStr.contains('network') || errorStr.contains('timeout')) {
      return _networkError;
    }
    
    if (errorStr.contains('rate limit') || errorStr.contains('too many requests')) {
      return _rateLimitError;
    }
    
    if (errorStr.contains('validation') || errorStr.contains('invalid')) {
      return _validationError;
    }
    
    return _unknownError;
  }

  /// Obtém sugestão de resolução para o erro
  static String getErrorSuggestion(dynamic error) {
    final category = getErrorCategory(error);
    
    switch (category) {
      case _authError:
        return 'Verifique suas credenciais e tente fazer login novamente.';
      case _networkError:
        return 'Verifique sua conexão com a internet e tente novamente.';
      case _databaseError:
        return 'Os dados podem estar temporariamente indisponíveis. Tente novamente em alguns instantes.';
      case _storageError:
        return 'Verifique se o arquivo não está corrompido e tente fazer upload novamente.';
      case _validationError:
        return 'Verifique se todos os campos estão preenchidos corretamente.';
      case _rateLimitError:
        return 'Aguarde alguns instantes antes de tentar novamente.';
      case _unknownError:
      default:
        return 'Tente novamente. Se o problema persistir, reinicie o aplicativo.';
    }
  }

  /// Loga erro para debugging
  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    final category = getErrorCategory(error);
    // Log error with timestamp for debugging
    debugPrint('[$category] $context: $error at ${DateTime.now().toIso8601String()}');
    
    // Log entry for debugging (commented out to avoid unused variable warning)
    // final logEntry = {
    //   'timestamp': timestamp,
    //   'context': context,
    //   'category': category,
    //   'error': error.toString(),
    //   'stackTrace': stackTrace?.toString(),
    // };

    // Log estruturado para debugging
    if (kDebugMode) {
      debugPrint('🚨 ERROR [$category] in $context:');
      debugPrint('   Error: ${error.toString()}');
      if (stackTrace != null) {
        debugPrint('   StackTrace: ${stackTrace.toString()}');
      }
    }

    // TODO: Em produção, enviar para serviço de logging
    // _sendToLoggingService(logEntry);
  }

  /// Trata erros de autenticação
  static String _handleAuthError(AuthException error) {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Email ou senha incorretos. Verifique suas credenciais.';
      case 'Email not confirmed':
        return 'Confirme seu email antes de fazer login.';
      case 'User not found':
        return 'Usuário não encontrado. Verifique se o email está correto.';
      case 'Too many requests':
        return 'Muitas tentativas de login. Aguarde alguns minutos.';
      case 'Invalid phone number':
        return 'Número de telefone inválido. Verifique o formato.';
      case 'Invalid OTP':
        return 'Código de verificação inválido. Tente novamente.';
      default:
        return 'Erro de autenticação: ${error.message}';
    }
  }

  /// Trata erros de banco de dados
  static String _handleDatabaseError(PostgrestException error) {
    switch (error.code) {
      case '23505': // Unique violation
        return 'Este item já existe.';
      case '23503': // Foreign key violation
        return 'Referência inválida. O item pode ter sido removido.';
      case '23514': // Check violation
        return 'Dados inválidos. Verifique os valores inseridos.';
      case '42P01': // Undefined table
        return 'Erro interno do sistema. Tente novamente.';
      case '42501': // Insufficient privilege
        return 'Sem permissão para realizar esta ação.';
      default:
        return 'Erro de dados: ${error.message}';
    }
  }

  /// Trata erros de storage
  static String _handleStorageError(StorageException error) {
    switch (error.statusCode) {
      case '413':
        return 'Arquivo muito grande. Use um arquivo menor.';
      case '415':
        return 'Tipo de arquivo não suportado. Use JPG, PNG ou WebP.';
      case '403':
        return 'Sem permissão para fazer upload.';
      case '404':
        return 'Arquivo não encontrado.';
      default:
        return 'Erro de arquivo: ${error.message}';
    }
  }

  /// Trata erros de rede
  static String _handleNetworkError(dynamic error) {
    if (error.toString().contains('timeout')) {
      return 'Conexão lenta. Verifique sua internet e tente novamente.';
    }
    if (error.toString().contains('connection refused')) {
      return 'Servidor indisponível. Tente novamente em alguns instantes.';
    }
    return 'Problema de conexão. Verifique sua internet.';
  }

  /// Trata erros de rate limiting
  static String _handleRateLimitError(dynamic error) {
    return 'Muitas requisições. Aguarde alguns instantes antes de tentar novamente.';
  }

  /// Trata erros de validação
  static String _handleValidationError(dynamic error) {
    if (error.toString().contains('email')) {
      return 'Email inválido. Verifique o formato.';
    }
    if (error.toString().contains('phone')) {
      return 'Número de telefone inválido.';
    }
    if (error.toString().contains('url')) {
      return 'URL inválida. Verifique o link.';
    }
    return 'Dados inválidos. Verifique as informações inseridas.';
  }

  /// Trata erros desconhecidos
  static String _handleUnknownError(dynamic error, String? context) {
    if (context != null) {
      return 'Erro em $context: ${error.toString()}';
    }
    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  /// Verifica se o erro é recuperável
  static bool isRecoverableError(dynamic error) {
    final category = getErrorCategory(error);
    
    // Erros não recuperáveis
    if (category == _authError && error is AuthException) {
      return !['User not found', 'Invalid login credentials'].contains(error.message);
    }
    
    // Erros de rede são geralmente recuperáveis
    if (category == _networkError) return true;
    
    // Rate limiting é recuperável
    if (category == _rateLimitError) return true;
    
    // Validação é recuperável
    if (category == _validationError) return true;
    
    // Storage pode ser recuperável
    if (category == _storageError && error is StorageException) {
      return !['413', '415'].contains(error.statusCode); // Arquivo muito grande ou tipo inválido
    }
    
    return false;
  }

  /// Obtém ação recomendada para o erro
  static String getRecommendedAction(dynamic error) {
    if (!isRecoverableError(error)) {
      return 'Reinicie o aplicativo';
    }
    
    final category = getErrorCategory(error);
    
    switch (category) {
      case _networkError:
        return 'Verificar conexão';
      case _rateLimitError:
        return 'Aguardar';
      case _validationError:
        return 'Corrigir dados';
      case _storageError:
        return 'Tentar novamente';
      default:
        return 'Tentar novamente';
    }
  }

  /// Cria relatório de erro para debugging
  static Map<String, dynamic> createErrorReport(
    String context, 
    dynamic error, 
    StackTrace? stackTrace,
    {Map<String, dynamic>? additionalData}
  ) {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'context': context,
      'error': error.toString(),
      'category': getErrorCategory(error),
      'recoverable': isRecoverableError(error),
      'readableMessage': getReadableError(error, context: context),
      'suggestion': getErrorSuggestion(error),
      'recommendedAction': getRecommendedAction(error),
      'stackTrace': stackTrace?.toString(),
      'additionalData': additionalData,
    };
  }
}
