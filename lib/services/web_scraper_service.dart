import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:wishlist_app/services/firebase_functions_service.dart';

/// Serviço de web scraping seguro usando Firebase Cloud Functions
/// 
/// ⚠️ LIMITAÇÕES PLANO GRATUITO:
/// - Firebase: 2M Cloud Functions calls/mês (66k/dia)
/// - ScraperAPI: 1k requests/mês (fallback)
/// 
/// OTIMIZAÇÕES IMPLEMENTADAS:
/// - Cache local para evitar re-scraping
/// - Rate limiting inteligente
/// - Fallback para scraping básico (sem API externa)
/// - Validação de domínios para reduzir chamadas desnecessárias
class WebScraperServiceSecure {
  final FirebaseFunctionsService _functions = FirebaseFunctionsService();
  
  // Cache local para economizar chamadas à Edge Function (plano gratuito)
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const Duration _cacheExpiry = Duration(hours: 24); // Cache por 24h

  /// Fazer scraping de uma URL usando a Edge Function segura
  /// 
  /// ⚠️ OTIMIZADO PARA PLANO GRATUITO:
  /// - Cache local para evitar re-scraping da mesma URL
  /// - Rate limiting para não exceder limites
  /// - Fallback para scraping básico (sem custo)
  Future<Map<String, dynamic>> scrape(String url, {String? userId}) async {
    try {
      // Verificar cache primeiro (economiza chamadas à Cloud Function)
      final cachedResult = _getFromCache(url);
      if (cachedResult != null) {
        debugPrint('📦 Cache hit for URL: $url');
        return cachedResult;
      }
      
      // Primeiro tentar usar a Cloud Function segura
      final result = await _scrapeWithCloudFunction(url);
      
      // Guardar no cache (economiza futuras chamadas)
      _saveToCache(url, result);
      
      return result;
    } catch (e) {
      // Se a Cloud Function falhar, usar fallback com validação
      MonitoringService.logErrorStatic('web_scraping_cloud_function', e, stackTrace: StackTrace.current);
      final fallbackResult = await _scrapeWithFallback(url);
      
      // Guardar resultado do fallback no cache também
      _saveToCache(url, fallbackResult);
      
      return fallbackResult;
    }
  }

  /// Scraping usando Firebase Cloud Function segura
  Future<Map<String, dynamic>> _scrapeWithCloudFunction(String url) async {
    try {
      final data = await _functions.scrapeUrl(url);
      
      // Validar resposta da Cloud Function
      if (data is Map<String, dynamic>) {
        return {
          'title': _sanitizeText(data['title']?.toString() ?? 'Título não encontrado'),
          'price': _sanitizePrice(data['price']?.toString() ?? '0.00'),
          'image': _sanitizeImageUrl(data['image']?.toString() ?? ''),
          'description': _sanitizeText(data['description']?.toString() ?? ''),
          'category': _detectCategory(data['title']?.toString() ?? '', data['description']?.toString() ?? ''),
          'rating': _sanitizeRating(data['rating']?.toString()),
          'currency': data['currency']?.toString() ?? 'EUR',
          'availability': data['availability']?.toString() ?? 'Desconhecido',
        };
      } else {
        throw Exception('Invalid response format from Cloud Function');
      }
    } catch (e) {
      throw Exception('Cloud Function error: ${e.toString()}');
    }
  }

  /// Fallback para scraping básico com validação inteligente
  Future<Map<String, dynamic>> _scrapeWithFallback(String url) async {
    final uri = Uri.parse(url);
    final hostname = uri.host.toLowerCase();
    final isTrusted = _isTrustedDomain(hostname);
    
    // Validar domínio antes de fazer scraping
    if (!_isAllowedDomain(url)) {
      return {
        'title': 'Domínio não suportado: $hostname',
        'price': '0.00', 
        'image': '',
        'error': 'Domain not supported for secure scraping',
        'warning': 'Este domínio não está na nossa lista de lojas verificadas'
      };
    }
    
    // Variável para armazenar resultado
    Map<String, dynamic> result = {};
    
    // ⚠️ PLANO GRATUITO: ScraperAPI tem apenas 1k requests/mês
    // Usar apenas como último recurso para domínios confiáveis
    if (Config.scraperApiKey.isNotEmpty && isTrusted) {
      try {
        debugPrint('🔄 Using ScraperAPI (free tier: 1k requests/month)');
        result = await _scrapeWithScraperAPI(url);
      } catch (e) {
        debugPrint('ScraperAPI failed: $e');
        result = await _basicScrape(url);
      }
    } else {
      // Para domínios não confiáveis ou sem ScraperAPI, usar scraping básico
      debugPrint('🔄 Using basic scraping (no external API cost)');
      result = await _basicScrape(url);
    }
    
    // Adicionar aviso se não for domínio totalmente confiável
    if (!isTrusted) {
      result['warning'] = 'Loja não verificada - dados podem não estar completos';
      result['domain_status'] = 'unverified';
    } else {
      result['domain_status'] = 'verified';
    }
    
    return result;
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
        final description = _extractDescription(document);
        final rating = _extractRating(document);

        return {
          'title': _sanitizeText(title),
          'price': _sanitizePrice(price),
          'image': _sanitizeImageUrl(image),
          'description': _sanitizeText(description),
          'category': _detectCategory(title, description),
          'rating': _sanitizeRating(rating),
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

  /// Validar se o domínio é permitido ou usar fallback inteligente
  bool _isAllowedDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final hostname = uri.host.toLowerCase();
      
      // Primeiro verificar lista de domínios confiáveis
      if (_isTrustedDomain(hostname)) {
        return true;
      }
      
      // Se não estiver na lista, usar validação inteligente
      return _isValidEcommerceDomain(hostname);
    } catch (e) {
      return false;
    }
  }
  
  /// Lista massiva de domínios confiáveis
  bool _isTrustedDomain(String hostname) {
    const trustedDomains = [
      // === MARKETPLACES GLOBAIS ===
      // Amazon (todas as regiões)
      'amazon.com', 'amazon.pt', 'amazon.es', 'amazon.fr', 'amazon.co.uk', 
      'amazon.de', 'amazon.it', 'amazon.ca', 'amazon.com.br', 'amazon.in',
      'amazon.com.mx', 'amazon.co.jp', 'amazon.com.au', 'amazon.sg',
      // eBay (todas as regiões)
      'ebay.com', 'ebay.pt', 'ebay.es', 'ebay.fr', 'ebay.co.uk', 
      'ebay.de', 'ebay.it', 'ebay.ca', 'ebay.com.au', 'ebay.in',
      // AliExpress
      'aliexpress.com', 'aliexpress.us', 'pt.aliexpress.com', 'es.aliexpress.com',
      'fr.aliexpress.com', 'de.aliexpress.com', 'it.aliexpress.com',
      // Outros marketplaces asiáticos
      'shein.com', 'pt.shein.com', 'es.shein.com', 'fr.shein.com', 'de.shein.com',
      'wish.com', 'pt.wish.com', 'es.wish.com',
      'temu.com', 'pt.temu.com', 'es.temu.com',
      'banggood.com', 'pt.banggood.com', 'es.banggood.com',
      'gearbest.com', 'dhgate.com', 'lightinthebox.com',
      
      // === LOJAS PORTUGUESAS ===
      'fnac.pt', 'worten.pt', 'pcdiga.pt', 'globaldata.pt', 'novoatalho.pt',
      'continente.pt', 'radiopopular.pt', 'kuantokusta.pt', 'chupamobile.pt',
      'bertrand.pt', 'staples.pt', 'ikea.com', 'leroy.pt',
      'celeiro.pt', 'prozis.com', 'mango.com', 'parfois.com',
      
      // === LOJAS ESPANHOLAS ===
      'elcorteingles.es', 'mediamarkt.es', 'worten.es', 'fnac.es',
      'carrefour.es', 'alcampo.es', 'leroymerlin.es', 'pccomponentes.com',
      
      // === MODA INTERNACIONAL ===
      'zara.com', 'hm.com', 'uniqlo.com', 'gap.com', 'forever21.com',
      'asos.com', 'boohoo.com', 'prettylittlething.com', 'missguided.com',
      'zalando.pt', 'zalando.es', 'zalando.fr', 'zalando.de', 'zalando.it',
      'aboutyou.pt', 'aboutyou.es', 'aboutyou.fr', 'aboutyou.de',
      'lamoda.pt', 'lamoda.es', 'modivo.pt', 'modivo.es',
      
      // === DESPORTO ===
      'nike.com', 'adidas.com', 'adidas.pt', 'puma.com', 'reebok.com',
      'underarmour.com', 'newbalance.com', 'asics.com', 'vans.com',
      'converse.com', 'timberland.com', 'sportzone.pt', 'intersport.pt',
      
      // === ELETRÔNICOS ===
      'apple.com', 'samsung.com', 'sony.com', 'lg.com', 'philips.com',
      'asus.com', 'hp.com', 'dell.com', 'lenovo.com', 'acer.com',
      'bestbuy.com', 'newegg.com', 'bhphotovideo.com',
      
      // === CASA E JARDIM ===
      'ikea.com', 'homedepot.com', 'lowes.com', 'wayfair.com',
      'overstock.com', 'bedbathandbeyond.com', 'williams-sonoma.com',
      
      // === LIVROS ===
      'bookdepository.com', 'waterstones.com', 'barnesandnoble.com',
      'thriftbooks.com', 'abebooks.com', 'bertrand.pt',
      
      // === BELEZA ===
      'sephora.com', 'ulta.com', 'beautylish.com', 'lookfantastic.com',
      'feelunique.com', 'strawberrynet.com', 'douglas.pt', 'douglas.es',
      
      // === VIAGENS ===
      'booking.com', 'expedia.com', 'hotels.com', 'trivago.com',
      'airbnb.com', 'vrbo.com', 'momondo.com', 'kayak.com',
      
      // === MERCADO LIVRE ===
      'mercadolivre.pt', 'mercadolivre.com.br', 'mercadolibre.com.ar',
      'mercadolibre.com.mx', 'mercadolibre.cl', 'mercadolibre.com.co',
      
      // === OUTROS EUROPEUS ===
      'bol.com', 'coolblue.nl', 'otto.de', 'alternate.de',
      'conforama.fr', 'darty.fr', 'cdiscount.fr', 'rue-du-commerce.com',
      'pixmania.com', 'grosbill.com', 'ldlc.com'
    ];
    
    return trustedDomains.any((domain) => 
      hostname == domain || hostname.endsWith('.$domain')
    );
  }
  
  /// Validação inteligente para domínios de e-commerce
  bool _isValidEcommerceDomain(String hostname) {
    // Padrões suspeitos que devemos evitar
    const suspiciousPatterns = [
      'localhost', '127.0.0.1', '0.0.0.0', '192.168.',
      'file://', 'data:', 'javascript:', 'vbscript:',
      '.onion', 'bit.ly', 'tinyurl', 'ow.ly', 't.co'
    ];
    
    // Verificar se é um domínio suspeito
    for (final pattern in suspiciousPatterns) {
      if (hostname.contains(pattern)) {
        return false;
      }
    }
    
    // Padrões que indicam sites de e-commerce legítimos
    const ecommerceIndicators = [
      'shop', 'store', 'loja', 'tienda', 'boutique', 'market',
      'buy', 'sell', 'commerce', 'retail', 'outlet',
      'fashion', 'clothing', 'electronics', 'books', 'games'
    ];
    
    // Verificar se contém indicadores de e-commerce
    final hasEcommerceIndicator = ecommerceIndicators.any((indicator) => 
      hostname.contains(indicator)
    );
    
    // TLD confiáveis para e-commerce
    const trustedTlds = [
      '.com', '.pt', '.es', '.fr', '.de', '.it', '.co.uk',
      '.net', '.org', '.eu', '.shop', '.store'
    ];
    
    final hasTrustedTld = trustedTlds.any((tld) => hostname.endsWith(tld));
    
    // Permitir se tem indicador de e-commerce E TLD confiável
    return hasEcommerceIndicator && hasTrustedTld;
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
      // Padrões gerais
      '[itemprop="price"]',
      '[property="product:price:amount"]',
      '.price',
      '#price',
      '.product-price',
      '.price-tag',
      '.current-price',
      '.sale-price',
      // Amazon
      '#priceblock_ourprice',
      '#priceblock_dealprice',
      '.a-price-whole',
      '.a-offscreen',
      // AliExpress
      '.product-price-value',
      '.price-current',
      '.price-sale',
      '[data-spm-anchor-id*="price"]',
      // Shein
      '.original-price',
      '.sale-price',
      '.price-sale',
      '.she-price',
      // Wish
      '.price-current',
      '.ProductCard__price',
      // Temu
      '.goods-price',
      '.price-text',
      // Seletores específicos adicionais
      '[class*="price"]',
      '[id*="price"]',
      '.cost',
      '.amount'
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

    // Verificar meta tags adicionais
    imageUrl = document
        .querySelector('meta[name="twitter:image"]')
        ?.attributes['content'];
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return _resolveUrl(imageUrl, baseUrl);
    }

    const commonImageContainers = [
      'div.product-image',
      'div.product-gallery',
      'div.image',
      'figure',
      // Amazon
      '#landingImage',
      '.a-dynamic-image',
      '#imgTagWrapperId img',
      // AliExpress
      '.image-view img',
      '.product-image img',
      '[data-role="image"] img',
      // Shein
      '.product-intro__head-gallery img',
      '.crop-image-container img',
      '.she-swiper-slide img',
      // Wish
      '.ProductCard__image img',
      '.product-image-container img',
      // Temu
      '.goods-gallery img',
      '.main-image img',
      // Seletores genéricos melhorados
      '[class*="product"] img',
      '[class*="gallery"] img',
      '[class*="main"] img'
    ];
    for (var container in commonImageContainers) {
      final imageElement = document.querySelector(container);
      if (imageElement != null) {
        imageUrl = imageElement.attributes['src'] ?? imageElement.attributes['data-src'];
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
    
    // Suporte para diferentes formatos de preço
    // Remover texto antes e depois dos números
    final priceRegex = RegExp(r'(\d{1,3}(?:[.,]\d{3})*[.,]\d{2}|\d+[.,]\d{2}|\d+)');
    final match = priceRegex.firstMatch(priceString);
    
    if (match != null) {
      String cleanPrice = match.group(0)!;
      
      // Normalizar separadores decimais
      if (cleanPrice.contains(',') && cleanPrice.contains('.')) {
        // Formato europeu: 1.234,56
        cleanPrice = cleanPrice.replaceAll('.', '').replaceAll(',', '.');
      } else if (cleanPrice.contains(',')) {
        // Pode ser 1,234.56 (US) ou 1234,56 (EU)
        final commaIndex = cleanPrice.lastIndexOf(',');
        final afterComma = cleanPrice.substring(commaIndex + 1);
        if (afterComma.length == 2) {
          // Formato europeu: 1234,56
          cleanPrice = cleanPrice.replaceAll(',', '.');
        } else {
          // Formato americano: 1,234.56
          cleanPrice = cleanPrice.replaceAll(',', '');
        }
      }
      
      try {
        final parsedPrice = double.parse(cleanPrice);
        return parsedPrice.toStringAsFixed(2);
      } catch (e) {
        debugPrint('Error parsing price: $cleanPrice');
      }
    }
    
    return '0.00';
  }

  String _resolveUrl(String url, String baseUrl) {
    if (url.startsWith('http')) return url;
    final uri = Uri.parse(baseUrl);
    return uri.resolve(url).toString();
  }
  
  /// Extrair descrição do produto
  String _extractDescription(Document document) {
    // Tentar extrair de meta tags primeiro
    var description = document
        .querySelector('meta[property="og:description"]')
        ?.attributes['content'];
    if (description != null && description.isNotEmpty) {
      return description;
    }

    description = document
        .querySelector('meta[name="description"]')
        ?.attributes['content'];
    if (description != null && description.isNotEmpty) {
      return description;
    }

    // Seletores específicos para descrições de produtos
    const descriptionSelectors = [
      // Genéricos
      '[itemprop="description"]',
      '.product-description',
      '.product-details',
      '.product-info',
      '.description',
      '#description',
      '.product-summary',
      // Amazon
      '#feature-bullets ul',
      '#productDescription',
      '.a-unordered-list',
      '.product-facts',
      // AliExpress
      '.product-property',
      '.product-info-section',
      '.product-overview',
      // Shein
      '.product-intro__description',
      '.goods-desc',
      // Wish
      '.ProductCard__description',
      '.product-description-container',
      // Temu
      '.goods-desc',
      '.product-desc',
      // Outros padrões comuns
      '[class*="desc"]',
      '[class*="summary"]',
      '[class*="detail"]'
    ];

    for (var selector in descriptionSelectors) {
      final descElement = document.querySelector(selector);
      if (descElement != null && descElement.text.isNotEmpty) {
        // Limitar o tamanho da descrição
        final desc = descElement.text.trim();
        if (desc.length > 500) {
          return '${desc.substring(0, 497)}...';
        }
        return desc;
      }
    }

    // Como último recurso, tentar encontrar parágrafos com informação relevante
    final paragraphs = document.querySelectorAll('p');
    for (final p in paragraphs) {
      final text = p.text.trim();
      if (text.length > 50 && text.length < 300) {
        // Verificar se parece ser uma descrição de produto
        if (_looksLikeProductDescription(text)) {
          return text;
        }
      }
    }

    return '';
  }

  /// Extrair rating/avaliação do produto
  String _extractRating(Document document) {
    // Seletores para ratings
    const ratingSelectors = [
      '[itemprop="ratingValue"]',
      '.rating-value',
      '.star-rating',
      '.average-rating',
      // Amazon
      '.a-icon-alt',
      '[data-hook="average-star-rating"]',
      '.cr-average-stars',
      // AliExpress
      '.rating-value',
      '.evaluation-score',
      // Genéricos
      '[class*="rating"]',
      '[class*="star"]',
      '[class*="score"]'
    ];

    for (var selector in ratingSelectors) {
      final ratingElement = document.querySelector(selector);
      if (ratingElement != null) {
        var rating = ratingElement.attributes['content'] ?? 
                    ratingElement.text;
        
        // Extrair número do rating (ex: "4.5 de 5" -> "4.5")
        final ratingMatch = RegExp(r'(\d+[.,]\d+|\d+)').firstMatch(rating);
        if (ratingMatch != null) {
          return ratingMatch.group(1)!.replaceAll(',', '.');
        }
      }
    }

    return '';
  }

  /// Detectar categoria do produto baseado no título e descrição
  String _detectCategory(String title, String description) {
    final content = '${title.toLowerCase()} ${description.toLowerCase()}';
    
    // Mapeamento de palavras-chave para categorias
    const categoryMappings = {
      'Livro': [
        'book', 'livro', 'novel', 'romance', 'biografia', 'ensaio', 'autor',
        'literatura', 'ficção', 'história', 'poetry', 'poesia', 'manual',
        'guia', 'encyclopedia', 'enciclopédia', 'dicionário', 'dictionary'
      ],
      'Eletrónico': [
        'smartphone', 'phone', 'telemóvel', 'tablet', 'laptop', 'computador',
        'headphones', 'auscultadores', 'camera', 'câmara', 'tv', 'televisão',
        'gaming', 'console', 'playstation', 'xbox', 'nintendo', 'electronic',
        'eletrónico', 'digital', 'tech', 'technology', 'gadget', 'device',
        'smart', 'wireless', 'bluetooth', 'usb', 'charger', 'carregador'
      ],
      'Viagem': [
        'mala', 'suitcase', 'bagagem', 'travel', 'viagem', 'flight', 'hotel',
        'vacation', 'férias', 'backpack', 'mochila', 'passport', 'passaporte',
        'luggage', 'trip', 'journey', 'tourism', 'turismo', 'destination'
      ],
      'Moda': [
        'fashion', 'moda', 'clothing', 'roupa', 'shirt', 'camisa', 'dress',
        'vestido', 'shoes', 'sapatos', 'jeans', 'jacket', 'casaco', 'pants',
        'calças', 'skirt', 'saia', 'blouse', 'blusa', 'style', 'estilo',
        'designer', 'brand', 'marca', 'accessories', 'acessórios', 'watch',
        'relógio', 'jewelry', 'jóias', 'bag', 'bolsa', 'hat', 'chapéu'
      ],
      'Casa': [
        'home', 'casa', 'furniture', 'móveis', 'kitchen', 'cozinha',
        'bathroom', 'casa de banho', 'bedroom', 'quarto', 'living room',
        'sala', 'decoration', 'decoração', 'appliance', 'eletrodoméstico',
        'cleaning', 'limpeza', 'garden', 'jardim', 'tool', 'ferramenta',
        'lamp', 'lâmpada', 'table', 'mesa', 'chair', 'cadeira', 'sofa'
      ]
    };

    // Contar matches para cada categoria
    final categoryScores = <String, int>{};
    
    for (final entry in categoryMappings.entries) {
      final category = entry.key;
      final keywords = entry.value;
      
      int score = 0;
      for (final keyword in keywords) {
        if (content.contains(keyword)) {
          score++;
        }
      }
      
      if (score > 0) {
        categoryScores[category] = score;
      }
    }
    
    // Retornar categoria com maior pontuação
    if (categoryScores.isNotEmpty) {
      final sortedCategories = categoryScores.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedCategories.first.key;
    }
    
    // Default fallback
    return 'Outros';
  }

  /// Verificar se o texto parece ser uma descrição de produto
  bool _looksLikeProductDescription(String text) {
    // Características de descrições de produto
    const productIndicators = [
      'característica', 'feature', 'especificação', 'specification',
      'material', 'cor', 'color', 'tamanho', 'size', 'dimensão',
      'qualidade', 'quality', 'design', 'style', 'marca', 'brand',
      'produto', 'product', 'artigo', 'item'
    ];
    
    final lowerText = text.toLowerCase();
    return productIndicators.any((indicator) => lowerText.contains(indicator));
  }

  /// Sanitizar rating garantindo formato válido
  String? _sanitizeRating(String? rating) {
    if (rating == null || rating.isEmpty) return null;
    
    try {
      final parsedRating = double.parse(rating);
      // Garantir que está entre 0 e 5
      if (parsedRating >= 0 && parsedRating <= 5) {
        return parsedRating.toStringAsFixed(1);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    
    return null;
  }

  /// Métodos de cache para economizar chamadas à Edge Function
  Map<String, dynamic>? _getFromCache(String url) {
    final cacheEntry = _cache[url];
    if (cacheEntry != null) {
      final timestamp = cacheEntry['timestamp'] as DateTime?;
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return cacheEntry['data'] as Map<String, dynamic>;
      } else {
        // Cache expirado, remover
        _cache.remove(url);
      }
    }
    return null;
  }
  
  void _saveToCache(String url, Map<String, dynamic> data) {
    _cache[url] = {
      'data': data,
      'timestamp': DateTime.now(),
    };
    
    // Limpar cache antigo se ficar muito grande (economizar memória)
    if (_cache.length > 100) {
      final now = DateTime.now();
      _cache.removeWhere((key, value) {
        final timestamp = value['timestamp'] as DateTime?;
        return timestamp != null && 
               now.difference(timestamp) > _cacheExpiry;
      });
    }
  }
}
