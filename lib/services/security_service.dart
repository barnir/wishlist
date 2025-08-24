import 'dart:io';
import 'dart:typed_data';
import 'package:wishlist_app/services/monitoring_service.dart';

/// Security service for URL sanitization and content validation
class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Blocked domains (malware, phishing, etc.)
  static const List<String> _blockedDomains = [
    'localhost',
    '127.0.0.1',
    '0.0.0.0',
    'bit.ly', // Often used for malicious links
    'tinyurl.com',
    't.co', // Twitter shortened URLs can be problematic
  ];

  // Suspicious URL patterns
  static const List<String> _suspiciousPatterns = [
    'javascript:',
    'data:',
    'vbscript:',
    'file:/',
    'ftp:/',
  ];

  // Safe image file signatures (magic numbers)
  static const Map<String, List<int>> _imageSignatures = {
    'jpg': [0xFF, 0xD8, 0xFF],
    'jpeg': [0xFF, 0xD8, 0xFF],
    'png': [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    'gif': [0x47, 0x49, 0x46, 0x38],
    'webp': [0x52, 0x49, 0x46, 0x46],
  };

  /// Validate and sanitize URL for safe use
  Future<UrlValidationResult> validateAndSanitizeUrl(String url) async {
    try {
      // Basic sanitization
      String sanitizedUrl = url.trim();
      
      // Add protocol if missing
      if (!sanitizedUrl.startsWith('http://') && !sanitizedUrl.startsWith('https://')) {
        sanitizedUrl = 'https://$sanitizedUrl';
      }

      // Parse URI
      final uri = Uri.tryParse(sanitizedUrl);
      if (uri == null) {
        return UrlValidationResult.invalid('URL inválido');
      }

      // Check scheme
      if (!['http', 'https'].contains(uri.scheme.toLowerCase())) {
        return UrlValidationResult.invalid('Apenas HTTP e HTTPS são permitidos');
      }

      // Check for suspicious patterns
      for (final pattern in _suspiciousPatterns) {
        if (sanitizedUrl.toLowerCase().contains(pattern)) {
          MonitoringService.logWarningStatic(
            'SecurityService',
            'Suspicious URL pattern detected: $pattern in $sanitizedUrl',
          );
          return UrlValidationResult.invalid('URL contém padrões suspeitos');
        }
      }

      // Check blocked domains
      final host = uri.host.toLowerCase();
      for (final blockedDomain in _blockedDomains) {
        if (host == blockedDomain || host.endsWith('.$blockedDomain')) {
          MonitoringService.logWarningStatic(
            'SecurityService',
            'Blocked domain detected: $host',
          );
          return UrlValidationResult.invalid('Domínio não permitido');
        }
      }

      // Check for private/local IP ranges
      if (_isPrivateOrLocalIP(host)) {
        return UrlValidationResult.invalid('IPs privados não são permitidos');
      }

      // Length validation
      if (sanitizedUrl.length > 2048) {
        return UrlValidationResult.invalid('URL demasiado longo');
      }

      MonitoringService.logInfoStatic(
        'SecurityService',
        'URL validated successfully: $sanitizedUrl',
      );

      return UrlValidationResult.valid(sanitizedUrl);

    } catch (e) {
      MonitoringService.logErrorStatic(
        'SecurityService',
        'URL validation error: $e',
        stackTrace: StackTrace.current,
      );
      return UrlValidationResult.invalid('Erro ao validar URL');
    }
  }

  /// Check if host is a private or local IP
  bool _isPrivateOrLocalIP(String host) {
    // IPv4 private ranges
    final ipv4Patterns = [
      RegExp(r'^127\.'), // Loopback
      RegExp(r'^192\.168\.'), // Private Class C
      RegExp(r'^10\.'), // Private Class A
      RegExp(r'^172\.(1[6-9]|2[0-9]|3[0-1])\.'), // Private Class B
      RegExp(r'^169\.254\.'), // Link-local
      RegExp(r'^0\.0\.0\.0$'), // Any
    ];

    for (final pattern in ipv4Patterns) {
      if (pattern.hasMatch(host)) {
        return true;
      }
    }

    // IPv6 loopback and private
    if (host == '::1' || host.startsWith('fc00:') || host.startsWith('fd00:')) {
      return true;
    }

    return false;
  }

  /// Validate image file for security
  Future<ImageValidationResult> validateImage(File imageFile) async {
    try {
      // Check file existence
      if (!await imageFile.exists()) {
        return ImageValidationResult.invalid('Ficheiro não existe');
      }

      // Check file size (max 10MB)
      final sizeInBytes = await imageFile.length();
      const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
      
      if (sizeInBytes > maxSizeInBytes) {
        return ImageValidationResult.invalid('Imagem demasiado grande (máximo 10MB)');
      }

      if (sizeInBytes == 0) {
        return ImageValidationResult.invalid('Ficheiro vazio');
      }

      // Check file extension
      final extension = imageFile.path.toLowerCase().split('.').last;
      if (!_imageSignatures.containsKey(extension)) {
        return ImageValidationResult.invalid(
          'Formato não suportado. Use: ${_imageSignatures.keys.join(', ')}'
        );
      }

      // Validate file signature (magic numbers)
      final bytes = await imageFile.readAsBytes();
      if (!_validateImageSignature(bytes, extension)) {
        MonitoringService.logWarningStatic(
          'SecurityService',
          'Invalid image signature for file: ${imageFile.path}',
        );
        return ImageValidationResult.invalid('Ficheiro corrompido ou tipo incorreto');
      }

      // Additional security checks
      if (_containsSuspiciousImageContent(bytes)) {
        MonitoringService.logWarningStatic(
          'SecurityService',
          'Suspicious content detected in image: ${imageFile.path}',
        );
        return ImageValidationResult.invalid('Conteúdo suspeito detectado na imagem');
      }

      MonitoringService.logInfoStatic(
        'SecurityService',
        'Image validated successfully: ${imageFile.path} ($sizeInBytes bytes)',
      );

      return ImageValidationResult.valid();

    } catch (e) {
      MonitoringService.logErrorStatic(
        'SecurityService',
        'Image validation error: $e',
        stackTrace: StackTrace.current,
      );
      return ImageValidationResult.invalid('Erro ao validar imagem');
    }
  }

  /// Validate image file signature
  bool _validateImageSignature(Uint8List bytes, String extension) {
    final signature = _imageSignatures[extension];
    if (signature == null || bytes.length < signature.length) {
      return false;
    }

    for (int i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) {
        return false;
      }
    }

    return true;
  }

  /// Check for suspicious content in image bytes
  bool _containsSuspiciousImageContent(Uint8List bytes) {
    // Convert to string to check for embedded scripts or suspicious content
    final content = String.fromCharCodes(bytes.take(1024)); // Check first 1KB
    
    final suspiciousPatterns = [
      '<script',
      'javascript:',
      'data:text/html',
      'data:text/javascript',
      '<?php',
      '<%',
    ];

    final lowerContent = content.toLowerCase();
    return suspiciousPatterns.any((pattern) => lowerContent.contains(pattern));
  }

  /// Sanitize text input to prevent XSS and injection
  String sanitizeTextInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp('[<>"\'&]'), '') // Remove HTML/script characters
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '') // Remove JS
        .replaceAll(RegExp(r'data:', caseSensitive: false), '') // Remove data URIs
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Check for potentially dangerous content
  bool isDangerousContent(String content) {
    final dangerousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false, dotAll: true),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'data:text/html', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // Event handlers
      RegExp(r'expression\s*\(', caseSensitive: false), // CSS expressions
    ];

    return dangerousPatterns.any((pattern) => pattern.hasMatch(content));
  }

  /// Generate content security hash for integrity verification
  String generateContentHash(String content) {
    // Simple hash for content integrity (in production, use crypto package)
    int hash = 0;
    for (int i = 0; i < content.length; i++) {
      hash = ((hash << 5) - hash + content.codeUnitAt(i)) & 0xffffffff;
    }
    return hash.toString();
  }
}

/// URL validation result
class UrlValidationResult {
  final bool isValid;
  final String? sanitizedUrl;
  final String? error;

  const UrlValidationResult._({
    required this.isValid,
    this.sanitizedUrl,
    this.error,
  });

  factory UrlValidationResult.valid(String sanitizedUrl) =>
      UrlValidationResult._(isValid: true, sanitizedUrl: sanitizedUrl);
  
  factory UrlValidationResult.invalid(String error) =>
      UrlValidationResult._(isValid: false, error: error);
}

/// Image validation result
class ImageValidationResult {
  final bool isValid;
  final String? error;

  const ImageValidationResult._({
    required this.isValid,
    this.error,
  });

  factory ImageValidationResult.valid() =>
      const ImageValidationResult._(isValid: true);
  
  factory ImageValidationResult.invalid(String error) =>
      ImageValidationResult._(isValid: false, error: error);
}