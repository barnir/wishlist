import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:mime/mime.dart';

/// Serviço seguro para interagir com Supabase Storage.
///
/// Este serviço implementa validações completas de segurança:
/// - Validação de tipo MIME
/// - Verificação de magic bytes
/// - Limite de tamanho de arquivo
/// - Sanitização de nomes de arquivo
/// - Otimização de imagens
class SupabaseStorageServiceSecure {
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  final String _bucketName = 'wishlist-images';

  // Configurações de segurança
  static const int MAX_FILE_SIZE = 5 * 1024 * 1024; // 5MB
  static const List<String> ALLOWED_MIME_TYPES = [
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'image/gif'
  ];
  
  // Magic bytes para validação de arquivos
  static const Map<String, List<int>> MAGIC_BYTES = {
    'image/jpeg': [0xFF, 0xD8, 0xFF],
    'image/png': [0x89, 0x50, 0x4E, 0x47],
    'image/webp': [0x52, 0x49, 0x46, 0x46],
    'image/gif': [0x47, 0x49, 0x46, 0x38],
  };

  /// Upload seguro de imagem com validações completas
  Future<String?> uploadImage(File imageFile, String path) async {
    try {
      // 1. Validação de tamanho
      final fileSize = await imageFile.length();
      if (fileSize > MAX_FILE_SIZE) {
        throw SecurityException('Arquivo muito grande. Máximo: ${MAX_FILE_SIZE ~/ (1024 * 1024)}MB');
      }

      // 2. Validação de tipo MIME
      final mimeType = lookupMimeType(imageFile.path);
      if (mimeType == null || !ALLOWED_MIME_TYPES.contains(mimeType)) {
        throw SecurityException('Tipo de arquivo não permitido. Tipos permitidos: ${ALLOWED_MIME_TYPES.join(', ')}');
      }

      // 3. Validação de magic bytes
      final bytes = await imageFile.readAsBytes();
      if (!_validateMagicBytes(bytes, mimeType)) {
        throw SecurityException('Arquivo corrompido ou tipo inválido');
      }

      // 4. Sanitização do nome do arquivo
      final sanitizedPath = _sanitizePath(path);
      final fileName = _generateSecureFileName(imageFile.path, mimeType);
      final filePath = '$sanitizedPath/$fileName';

      // 5. Otimização da imagem
      final optimizedImageBytes = await _optimizeImageSecure(bytes, mimeType);
      
      // 6. Upload com validação adicional
      final response = await _supabaseClient.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            optimizedImageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mimeType,
            ),
          );

      if (response.isNotEmpty) {
        return _supabaseClient.storage.from(_bucketName).getPublicUrl(filePath);
      }
      return null;
    } on StorageException catch (e) {
      print('Storage error: ${e.message}');
      return null;
    } on SecurityException catch (e) {
      print('Security validation failed: ${e.message}');
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  /// Valida magic bytes do arquivo
  bool _validateMagicBytes(Uint8List bytes, String mimeType) {
    final expectedMagicBytes = MAGIC_BYTES[mimeType];
    if (expectedMagicBytes == null) return false;
    
    if (bytes.length < expectedMagicBytes.length) return false;
    
    for (int i = 0; i < expectedMagicBytes.length; i++) {
      if (bytes[i] != expectedMagicBytes[i]) return false;
    }
    return true;
  }

  /// Sanitiza o caminho do arquivo
  String _sanitizePath(String path) {
    return path
        .replaceAll(RegExp(r'[^a-zA-Z0-9/_-]'), '') // Remove caracteres perigosos
        .replaceAll(RegExp(r'\.\.'), '') // Remove tentativas de path traversal
        .replaceAll(RegExp(r'//+'), '/') // Normaliza barras
        .trim();
  }

  /// Gera nome de arquivo seguro
  String _generateSecureFileName(String originalPath, String mimeType) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 10000;
    final extension = _getExtensionFromMimeType(mimeType);
    
    return '${timestamp}_${random}$extension';
  }

  /// Obtém extensão do tipo MIME
  String _getExtensionFromMimeType(String mimeType) {
    switch (mimeType) {
      case 'image/jpeg':
      case 'image/jpg':
        return '.jpg';
      case 'image/png':
        return '.png';
      case 'image/webp':
        return '.webp';
      case 'image/gif':
        return '.gif';
      default:
        return '.jpg';
    }
  }

  /// Otimização segura de imagem
  Future<Uint8List> _optimizeImageSecure(Uint8List imageBytes, String mimeType) async {
    try {
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Não foi possível decodificar a imagem');
      }

      // Validação de dimensões
      if (image.width <= 0 || image.height <= 0) {
        throw Exception('Dimensões de imagem inválidas');
      }

      // Redimensionar se muito grande
      if (image.width > 2048 || image.height > 2048) {
        image = img.copyResize(
          image,
          width: 2048,
          height: -1, // Manter proporção
        );
      }

      // Redimensionar se muito pequeno (melhorar qualidade)
      if (image.width < 100 || image.height < 100) {
        image = img.copyResize(
          image,
          width: 100,
          height: -1,
        );
      }

      // Comprimir baseado no tipo
      switch (mimeType) {
        case 'image/jpeg':
        case 'image/jpg':
          return img.encodeJpg(image, quality: 85);
        case 'image/png':
          return img.encodePng(image, level: 6);
        case 'image/webp':
          return img.encodeJpg(image, quality: 85); // Fallback para JPG
        case 'image/gif':
          return img.encodeGif(image);
        default:
          return img.encodeJpg(image, quality: 85);
      }
    } catch (e) {
      print('Erro na otimização: $e');
      // Retornar original se otimização falhar
      return imageBytes;
    }
  }

  /// Upload de imagem com validação de URL
  Future<String?> uploadImageFromUrl(String imageUrl, String path) async {
    try {
      // Validar URL
      final uri = Uri.parse(imageUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw SecurityException('URL inválida');
      }

      // Verificar se é HTTPS (mais seguro)
      if (uri.scheme != 'https' && uri.scheme != 'http') {
        throw SecurityException('Apenas URLs HTTP/HTTPS são permitidas');
      }

      // Fazer download da imagem
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(uri);
      request.headers.set('User-Agent', 'WishlistApp/1.0');
      
      final response = await request.close();
      
      if (response.statusCode != 200) {
        throw Exception('Falha ao baixar imagem: ${response.statusCode}');
      }

      // Ler bytes
      final bytes = await _consolidateHttpClientResponseBytes(response);
      
      // Validar tamanho
      if (bytes.length > MAX_FILE_SIZE) {
        throw SecurityException('Imagem muito grande');
      }

      // Detectar tipo MIME
      final mimeType = _detectMimeTypeFromBytes(bytes);
      if (mimeType == null || !ALLOWED_MIME_TYPES.contains(mimeType)) {
        throw SecurityException('Tipo de imagem não permitido');
      }

      // Validar magic bytes
      if (!_validateMagicBytes(bytes, mimeType)) {
        throw SecurityException('Arquivo corrompido ou tipo inválido');
      }

      // Continuar com upload normal
      final sanitizedPath = _sanitizePath(path);
      final fileName = _generateSecureFileName('url_image', mimeType);
      final filePath = '$sanitizedPath/$fileName';

      final optimizedBytes = await _optimizeImageSecure(bytes, mimeType);

      final uploadResponse = await _supabaseClient.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            optimizedBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: mimeType,
            ),
          );

      if (uploadResponse.isNotEmpty) {
        return _supabaseClient.storage.from(_bucketName).getPublicUrl(filePath);
      }
      return null;
    } catch (e) {
      print('Erro no upload de URL: $e');
      return null;
    }
  }

  /// Método auxiliar para consolidar bytes da resposta HTTP
  Future<Uint8List> _consolidateHttpClientResponseBytes(HttpClientResponse response) async {
    final List<int> bytes = [];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }
    return Uint8List.fromList(bytes);
  }

  /// Detectar tipo MIME a partir dos bytes
  String? _detectMimeTypeFromBytes(Uint8List bytes) {
    if (bytes.length < 4) return null;
    
    // Verificar magic bytes para cada tipo
    for (final entry in MAGIC_BYTES.entries) {
      if (_validateMagicBytes(bytes, entry.key)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Deletar imagem com validação
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Validar URL
      final uri = Uri.parse(imageUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw SecurityException('URL inválida');
      }

      // Verificar se é do nosso bucket
      if (!uri.host.contains('supabase.co') || !uri.path.contains(_bucketName)) {
        throw SecurityException('URL não pertence ao nosso storage');
      }

      final pathSegments = uri.pathSegments;
      if (pathSegments.length > 2) {
        final String pathInBucket = pathSegments
            .sublist(pathSegments.indexOf(_bucketName) + 1)
            .join('/');
        
        await _supabaseClient.storage.from(_bucketName).remove([pathInBucket]);
        return true;
      }
      return false;
    } on StorageException {
      return false;
    } on SecurityException {
      return false;
    } catch (e) {
      print('Erro ao deletar imagem: $e');
      return false;
    }
  }

  /// Obter estatísticas de uso do storage
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final files = await _supabaseClient.storage.from(_bucketName).list();
      
      int totalFiles = 0;
      int totalSize = 0;
      Map<String, int> typeCount = {};

      for (final file in files) {
        totalFiles++;
        totalSize += (file.metadata?['size'] ?? 0) as int;
        
        final mimeType = file.metadata?['mimetype'] ?? 'unknown';
        typeCount[mimeType] = (typeCount[mimeType] ?? 0) + 1;
      }

      return {
        'totalFiles': totalFiles,
        'totalSize': totalSize,
        'typeCount': typeCount,
        'bucketName': _bucketName,
      };
    } catch (e) {
      print('Erro ao obter estatísticas: $e');
      return {};
    }
  }
}

/// Exceção personalizada para erros de segurança
class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}
