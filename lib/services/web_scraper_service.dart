import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:wishlist_app/config.dart';
import 'package:wishlist_app/services/rate_limiter.dart';
import 'package:wishlist_app/services/error_service.dart';

/// Serviço de web scraping seguro usando Edge Function do Supabase
/// 
/// Esta versão usa a Edge Function 'secure-scraper' que implementa:
/// - Validação de domínios permitidos
/// - Sanitização de dados
/// - Proteção contra SSRF
/// - Timeout e rate limiting
class WebScraperServiceSecure with RateLimitMixin {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// Fazer scraping de uma URL usando a Edge Function segura
  Future<Map<String, dynamic>> scrape(String url, {String? userId}) async {
    return withRateLimit('scrape', userId: userId, operation: () async {
      try {
        // Primeiro tentar usar a Edge Function segura
        final result = await _scrapeWithEdgeFunction(url);
        return result;
          } catch (e) {
      // Se a Edge Function falhar, usar fallback com validação
      ErrorService.logError('web_scraping_edge_function', e, StackTrace.current);
      return _scrapeWithFallback(url);
    }
    });
  }

  /// Scraping usando Edge Function segura
  Future<Map<String, dynamic>> _scrapeWithEdgeFunction(String url) async {
    try {
      final response = await _supabaseClient.functions.invoke(
        'secure-scraper',
        body: {'url': url},
      );

      if (response.status != 200) {
        throw Exception('Edge Function failed with status: ${response.status}');
      }

      final data = response.data;
      
      // Validar resposta da Edge Function
      if (data is Map<String, dynamic>) {
        return {
          'title': _sanitizeText(data['title']?.toString() ?? 'Título não encontrado'),
          'price': _sanitizePrice(data['price']?.toString() ?? '0.00'),
          'image': _sanitizeImageUrl(data['image']?.toString() ?? ''),
          'currency': data['currency']?.toString() ?? 'EUR',
          'availability': data['availability']?.toString() ?? 'Desconhecido',
        };
      } else {
        throw Exception('Invalid response format from Edge Function');
      }
    } catch (e) {
      throw Exception('Edge Function error: ${e.toString()}');
    }
  }

  /// Fallback para scraping básico com validação de domínios
  Future<Map<String, dynamic>> _scrapeWithFallback(String url) async {
    // Validar domínio antes de fazer scraping
    if (!_isAllowedDomain(url)) {
      return {
        'title': 'Domínio não permitido',
        'price': '0.00', 
        'image': '',
        'error': 'Domain not allowed for scraping'
      };
    }

    // Se ScraperAPI estiver configurado, usar como fallback
    if (Config.scraperApiKey.isNotEmpty) {
      try {
        return await _scrapeWithScraperAPI(url);
      } catch (e) {
        debugPrint('ScraperAPI failed: $e');
      }
    }

    // Último recurso: scraping básico
    return await _basicScrape(url);
  }

  /// Scraping usando ScraperAPI (fallback)
  Future<Map<String, dynamic>> _scrapeWithScraperAPI(String url) async {
    final scraperApiUrl = 'http://api.scraperapi.com?api_key=${Config.scraperApiKey}&url=${Uri.encodeComponent(url)}&autoparse=true';
    
    final response = await http.get(
      Uri.parse(scraperApiUrl),
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Accept': 'application/json,text/html',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      var title = data['name'] ?? data['title'] ?? _extractTitleFromHtml(data['body']);
      var price = _parsePrice(data['price'] ?? data['price_string']);
      var image = data['image'] ?? data['image_url'] ?? _extractImageFromHtml(data['body'], url);

      if ((price == '0.00' || price.isEmpty) && data['body'] != null) {
        final document = parser.parse(data['body']);
        price = _extractPrice(document);
      }

      return {
        'title': _sanitizeText(title),
        'price': _sanitizePrice(price),
        'image': _sanitizeImageUrl(image),
      };
    } else {
      throw Exception('ScraperAPI request failed with status: ${response.statusCode}');
    }
  }

  /// Scraping básico com validação
  Future<Map<String, dynamic>> _basicScrape(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'pt-PT,pt;q=0.9,en;q=0.8',
          'DNT': '1',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        final title = _extractTitle(document);
        final price = _extractPrice(document);
        final image = _extractImage(document, url);

        return {
          'title': _sanitizeText(title),
          'price': _sanitizePrice(price),
          'image': _sanitizeImageUrl(image),
        };
      } else {
        throw Exception('Failed to load website: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in basic scraping: $e');
      return {
        'title': 'Could not fetch title',
        'price': '0.00',
        'image': '',
        'error': e.toString()
      };
    }
  }

  /// Validar se o domínio é permitido
  bool _isAllowedDomain(String url) {
    const allowedDomains = [
      'amazon.com', 'amazon.pt', 'amazon.es', 'amazon.fr', 'amazon.co.uk',
      'ebay.com', 'ebay.pt', 'ebay.es', 'ebay.fr', 'ebay.co.uk',
      'mercadolivre.pt', 'mercadolivre.com.br',
      'fnac.pt', 'fnac.com', 'fnac.es', 'fnac.fr',
      'worten.pt', 'worten.es',
      'pcdiga.pt',
      'globaldata.pt',
      'novoatalho.pt',
      'continente.pt',
      'elcorteingles.pt', 'elcorteingles.es',
      'mediamarkt.pt', 'mediamarkt.es',
      'radiopopular.pt',
      'kuantokusta.pt'
    ];

    try {
      final uri = Uri.parse(url);
      final hostname = uri.host.toLowerCase();
      
      return allowedDomains.any((domain) => 
        hostname == domain || hostname.endsWith('.$domain')
      );
    } catch (e) {
      return false;
    }
  }

  /// Sanitizar texto removendo caracteres perigosos
  String _sanitizeText(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[^\w\s\-.,!?()áàâãéèêíìîóòôõúùûçÁÀÂÃÉÈÊÍÌÎÓÒÔÕÚÙÛÇ]'), '') // Remove caracteres especiais
        .replaceAll(RegExp(r'\s+'), ' ') // Normalizar espaços
        .trim();
  }

  /// Sanitizar preço garantindo formato válido
  String _sanitizePrice(String price) {
    final cleanPrice = price.replaceAll(RegExp(r'[^0-9.,]'), '');
    try {
      final parsedPrice = double.parse(cleanPrice.replaceAll(',', '.'));
      return parsedPrice.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  /// Sanitizar URL de imagem
  String _sanitizeImageUrl(String imageUrl) {
    if (imageUrl.isEmpty) return '';
    
    try {
      final uri = Uri.parse(imageUrl);
      
      // Verificar se é HTTPS (mais seguro)
      if (uri.scheme != 'https' && uri.scheme != 'http') {
        return '';
      }
      
      // Verificar se é uma extensão de imagem válida
      final path = uri.path.toLowerCase();
      if (!path.endsWith('.jpg') && 
          !path.endsWith('.jpeg') && 
          !path.endsWith('.png') && 
          !path.endsWith('.webp') &&
          !path.endsWith('.gif')) {
        return '';
      }
      
      return imageUrl;
    } catch (e) {
      return '';
    }
  }

  // Métodos de extração mantidos do serviço original
  String _extractTitle(Document document) {
    var title = document
        .querySelector('meta[property="og:title"]')
        ?.attributes['content'];
    if (title != null && title.isNotEmpty) return title;

    title = document.querySelector('title')?.text;
    if (title != null && title.isNotEmpty) return title;

    title = document.querySelector('h1')?.text;
    if (title != null && title.isNotEmpty) return title;

    return 'No title found';
  }

  String _extractPrice(Document document) {
    const priceSelectors = [
      '[itemprop="price"]',
      '[property="product:price:amount"]',
      '.price',
      '#price',
      '#priceblock_ourprice',
      '.price-tag',
      '.product-price',
    ];

    for (var selector in priceSelectors) {
      final priceElement = document.querySelector(selector);
      if (priceElement != null) {
        final price = priceElement.attributes.containsKey('content')
            ? priceElement.attributes['content']
            : priceElement.text;
        if (price != null && price.isNotEmpty) return _parsePrice(price);
      }
    }

    const priceProperties = [
      'product:price:amount',
      'og:price:amount',
      'price',
    ];

    for (var prop in priceProperties) {
      final priceElement = document.querySelector('meta[property="$prop"]');
      if (priceElement != null) {
        final price = priceElement.attributes['content'];
        if (price != null && price.isNotEmpty) return _parsePrice(price);
      }
    }

    final bodyText = document.body?.text ?? '';
    final priceRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})*[.,]\d{2})');
    final match = priceRegex.firstMatch(bodyText);
    if (match != null) return _parsePrice(match.group(1)!);

    return '0.00';
  }

  String _extractImage(Document document, String baseUrl) {
    var imageUrl = document
        .querySelector('meta[property="og:image"]')
        ?.attributes['content'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return _resolveUrl(imageUrl, baseUrl);
    }

    const commonImageContainers = [
      'div.product-image',
      'div.product-gallery',
      'div.image',
      'figure',
    ];
    for (var container in commonImageContainers) {
      final imageElement = document.querySelector('$container img');
      if (imageElement != null) {
        imageUrl = imageElement.attributes['src'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          return _resolveUrl(imageUrl, baseUrl);
        }
      }
    }

    final firstImg = document.querySelector('img');
    if (firstImg != null) {
      imageUrl = firstImg.attributes['src'];
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return _resolveUrl(imageUrl, baseUrl);
      }
    }

    return '';
  }

  String _extractTitleFromHtml(String? body) {
    if (body == null) return 'No title found';
    final document = parser.parse(body);
    return _extractTitle(document);
  }

  String _extractImageFromHtml(String? body, String baseUrl) {
    if (body == null) return '';
    final document = parser.parse(body);
    return _extractImage(document, baseUrl);
  }

  String _parsePrice(dynamic price) {
    if (price == null) return '0.00';
    if (price is num) return price.toStringAsFixed(2);

    String priceString = price.toString();
    priceString = priceString.replaceAll(RegExp(r'[^0-9.,]'), '');
    priceString = priceString.replaceAll(',', '.');

    try {
      final parsedPrice = double.parse(priceString);
      return parsedPrice.toStringAsFixed(2);
    } catch (e) {
      return '0.00';
    }
  }

  String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http')) return url;
    final uri = Uri.parse(baseUrl);
    return uri.resolve(url).toString();
  }
}
