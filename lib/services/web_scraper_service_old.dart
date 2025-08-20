import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart';
import 'package:wishlist_app/config.dart';

class WebScraperService {
  Future<Map<String, dynamic>> scrape(String url) async {
    if (Config.scraperApiKey.isEmpty) {
      // print('SCRAPER_API_KEY is not set. Using basic scraping.');
      return _basicScrape(url);
    }

    try {
      final scraperApiUrl =
          'http://api.scraperapi.com?api_key=${Config.scraperApiKey}&url=${Uri.encodeComponent(url)}&autoparse=true';
      final response = await http.get(Uri.parse(scraperApiUrl));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        var title =
            data['name'] ??
            data['title'] ??
            _extractTitleFromHtml(data['body']);
        var price = _parsePrice(data['price'] ?? data['price_string']);
        var image =
            data['image'] ??
            data['image_url'] ??
            _extractImageFromHtml(data['body'], url);

        if ((price == '0.00' || price.isEmpty) && data['body'] != null) {
          final document = parser.parse(data['body']);
          price = _extractPrice(document);
        }

        return {'title': title, 'price': price, 'image': image};
      } else {
        // print('ScraperAPI request failed with status: ${response.statusCode}. Falling back to basic scraping.');
        return _basicScrape(url);
      }
    } catch (e) {
      // print('Error using ScraperAPI: $e. Falling back to basic scraping.');
      return _basicScrape(url);
    }
  }

  Future<Map<String, dynamic>> _basicScrape(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);

        final title = _extractTitle(document);
        final price = _extractPrice(document);
        final image = _extractImage(document, url);

        return {'title': title, 'price': price, 'image': image};
      } else {
        throw Exception('Failed to load website');
      }
    } catch (e) {
      // print('Error scraping website: $e');
      return {'title': 'Could not fetch title', 'price': '0.00', 'image': ''};
    }
  }

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
