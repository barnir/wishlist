import 'package:flutter/foundation.dart';
import 'firebase_functions_service.dart';
import '../utils/validation_utils.dart';

/// ShareEnrichmentService
/// Fluxo dedicado ao caso de partilha (ACTION_SEND / texto colado):
/// 1. Parse rápido (title + preço + url) do texto bruto.
/// 2. Retorna dados mínimos imediatos para preencher formulário.
/// 3. Dispara enrichment assíncrono (enrichLink) para completar.
class ShareEnrichmentService {
  static final ShareEnrichmentService _i = ShareEnrichmentService._internal();
  factory ShareEnrichmentService() => _i;
  ShareEnrichmentService._internal();

  final FirebaseFunctionsService _functions = FirebaseFunctionsService();

  /// Resultado inicial (instantâneo) + Future de enrichment opcional.
  Future<ShareEnrichmentResult> processSharedText(String raw) async {
    final trimmed = raw.trim();
    final url = _extractFirstUrl(trimmed);
    if (url == null) {
      return ShareEnrichmentResult(initial: InitialParsed.empty());
    }

    final cleanUrl = ValidationUtils.sanitizeUrlForSave(url);
    final title = _extractTitle(trimmed, cleanUrl);
    final price = _extractPrice(trimmed);

    final initial = InitialParsed(
      url: cleanUrl,
      title: title,
      price: price,
    );

    // Dispara enrichment mas não bloqueia retorno inicial.
    final enrichmentFuture = _functions.enrichLink(cleanUrl).catchError((e) {
      if (kDebugMode) debugPrint('Enrichment failed: $e');
      return <String, dynamic>{'error': e.toString()};
    });

    return ShareEnrichmentResult(initial: initial, enrichmentFuture: enrichmentFuture);
  }

  String? _extractFirstUrl(String text) {
    final regex = RegExp(r'https?://[^\s)]+', caseSensitive: false);
    final match = regex.firstMatch(text);
    return match?.group(0);
  }

  String? _extractPrice(String text) {
    final regex = RegExp(r'(\d+[.,]\d{1,2})\s*€');
    final match = regex.firstMatch(text);
    if (match != null) {
      return match.group(1)!.replaceAll(',', '.');
    }
    return null;
  }

  String? _extractTitle(String text, String url) {
    // Remove URL e preços do texto para ficar só o potencial título
    var cleaned = text.replaceAll(url, '');
    cleaned = cleaned.replaceAll(RegExp(r'(\d+[.,]\d{1,2})\s*€'), '');
    cleaned = cleaned.trim();
    if (cleaned.isEmpty) return null;
    // Limit size
    if (cleaned.length > 120) cleaned = cleaned.substring(0, 120);
    return cleaned;
  }
}

class ShareEnrichmentResult {
  final InitialParsed initial;
  final Future<Map<String,dynamic>>? enrichmentFuture;
  ShareEnrichmentResult({required this.initial, this.enrichmentFuture});
}

class InitialParsed {
  final String? url;
  final String? title;
  final String? price; // decimal string
  const InitialParsed({this.url, this.title, this.price});
  static InitialParsed empty() => const InitialParsed();
}
