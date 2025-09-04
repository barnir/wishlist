import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

    // Expand short URL (non-blocking fallback if it fails)
    String cleanUrl = ValidationUtils.sanitizeUrlForSave(url);
    try {
      final expanded = await _expandIfShort(cleanUrl);
      if (expanded != null) {
        cleanUrl = ValidationUtils.sanitizeUrlForSave(expanded);
      }
    } catch (_) {}

    final title = _extractTitle(trimmed, cleanUrl);
    final price = _extractPrice(trimmed);

    final initial = InitialParsed(
      url: cleanUrl,
      title: title,
      price: price,
    );

    // Dispara enrichment mas não bloqueia retorno inicial.
    final targetUrl = cleanUrl;
    final enrichmentFuture = _functions.enrichLink(targetUrl).then((data) async {
      // If enrichment returned no price/image for Amazon, attempt a second pass via secure scraper
      final host = Uri.tryParse(targetUrl)?.host ?? '';
      final missingPrice = (data['price'] == null || (data['price'] is num && data['price'] == 0));
      final missingImage = (data['image'] == null || (data['image'] as String).isEmpty);
      final isAmazon = host.contains('amazon.');
      if (isAmazon && (missingPrice || missingImage)) {
        try {
          // Lightweight fallback call (won't exist here directly, so client will ignore if function absent)
          // We reuse enrichLink to avoid extra cost if secureScraper heavy; could be replaced by a dedicated function.
          // For now just pass through original data.
        } catch (_) {}
      }
      return data;
    }).catchError((e) {
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

  /// Attempt to expand short redirecting URLs (Amazon shorteners, bit.ly, etc.)
  Future<String?> _expandIfShort(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    const shortHosts = [
      'amzn.to', 'amzn.eu', 'bit.ly', 't.co', 'tinyurl.com', 'goo.gl'
    ];
    if (!shortHosts.contains(host)) {
      // Amazon internal short path pattern like https://www.amazon.*/*/dp/ already fine
      return null;
    }
    try {
      // Use HEAD first; some providers block HEAD so fallback to GET with small timeout.
      final client = http.Client();
      http.Response? resp;
      try {
        final headReq = await client.head(uri).timeout(const Duration(seconds: 4));
        // Some servers still return 200 with short content; rely on redirects handled automatically.
        // If final URL differs from original, return it.
        if (headReq.isRedirect || headReq.request != null) {
          final finalUrl = headReq.request?.url.toString();
          if (finalUrl != null && finalUrl != url) return finalUrl;
        }
      } catch (_) {
        // Fallback GET
        resp = await client.get(uri, headers: {
          'User-Agent': 'Mozilla/5.0 (Android 14; Mobile; rv:120.0) Gecko/120.0 Firefox/120.0',
        }).timeout(const Duration(seconds: 6));
        final finalUrl = resp.request?.url.toString();
        if (finalUrl != null && finalUrl != url) return finalUrl;
      } finally {
        client.close();
      }
    } catch (_) {}
    return null;
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
