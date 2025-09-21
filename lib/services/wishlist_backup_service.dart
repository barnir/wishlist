import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:mywishstash/models/wish_item.dart';
import 'package:mywishstash/models/wishlist.dart';
import 'package:mywishstash/repositories/wish_item_repository.dart';
import 'package:mywishstash/repositories/wishlist_repository.dart';
import 'package:mywishstash/services/auth_service.dart';
import 'package:mywishstash/utils/app_logger.dart';
import 'package:mywishstash/services/share_enrichment_service.dart';
import 'package:mywishstash/services/firebase_functions_service.dart';

class WishlistExportResult {
  const WishlistExportResult({
    required this.file,
    required this.wishlistCount,
    required this.itemCount,
  });

  final File file;
  final int wishlistCount;
  final int itemCount;
}

class WishlistImportSummary {
  const WishlistImportSummary({
    required this.wishlistsCreated,
    required this.itemsCreated,
    required this.errors,
  });

  final int wishlistsCreated;
  final int itemsCreated;
  final List<String> errors;

  bool get hasErrors => errors.isNotEmpty;
}

class WishlistBackupPayloadEntry {
  WishlistBackupPayloadEntry({
    required this.wishlist,
    required this.items,
  });

  final Wishlist wishlist;
  final List<WishItem> items;

  Map<String, dynamic> toJson() {
    final wishlistMap = Map<String, dynamic>.from(wishlist.toMap())
      ..['legacy_id'] = wishlist.id
      ..['image_url'] = null;

    return {
      'wishlist': wishlistMap,
      'items': items.map((item) {
        final itemMap = Map<String, dynamic>.from(item.toMap())
          ..['legacy_id'] = item.id
          ..['image_url'] = null;
        return itemMap;
      }).toList(),
    };
  }

  static WishlistBackupPayloadEntry fromJson(Map<String, dynamic> json) {
    final wishlistJson = Map<String, dynamic>.from(json['wishlist'] as Map<String, dynamic>);
    final itemsJson = (json['items'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item as Map<String, dynamic>))
        .toList();

    return WishlistBackupPayloadEntry(
      wishlist: Wishlist.fromMap(wishlistJson),
      items: itemsJson.map(WishItem.fromMap).toList(growable: false),
    );
  }
}

class WishlistBackupPayload {
  WishlistBackupPayload({
    required this.generatedAt,
    required this.entries,
    this.version = 1,
  });

  final int version;
  final DateTime generatedAt;
  final List<WishlistBackupPayloadEntry> entries;

  Map<String, dynamic> toJson() => {
        'version': version,
        'generatedAt': generatedAt.toIso8601String(),
        'wishlists': entries.map((entry) => entry.toJson()).toList(),
      };

  static WishlistBackupPayload fromJson(Map<String, dynamic> json) {
    final version = json['version'] as int? ?? 1;
    final generatedAt = DateTime.tryParse(json['generatedAt'] as String? ?? '') ?? DateTime.now();
    final wishlists = (json['wishlists'] as List<dynamic>? ?? [])
        .map((raw) => WishlistBackupPayloadEntry.fromJson(
              Map<String, dynamic>.from(raw as Map<String, dynamic>),
            ))
        .toList(growable: false);

    return WishlistBackupPayload(
      version: version,
      generatedAt: generatedAt,
      entries: wishlists,
    );
  }
}

class WishlistBackupService {
  WishlistBackupService({
    WishlistRepository? wishlistRepository,
    WishItemRepository? wishItemRepository,
    AuthService? authService,
  })  : _wishlistRepository = wishlistRepository ?? WishlistRepository(),
        _wishItemRepository = wishItemRepository ?? WishItemRepository(),
        _authService = authService ?? AuthService();

  final WishlistRepository _wishlistRepository;
  final WishItemRepository _wishItemRepository;
  final AuthService _authService;

  Future<WishlistExportResult?> exportToFile() async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      appLog('Cannot export wishlists without authenticated user', tag: 'BACKUP');
      return null;
    }

    final wishlists = await _wishlistRepository.fetchAllForOwner(userId);
    final entries = <WishlistBackupPayloadEntry>[];
    var totalItems = 0;

    for (final wishlist in wishlists) {
      final items = await _wishItemRepository.fetchAllForWishlist(wishlist.id);
      totalItems += items.length;
      entries.add(
        WishlistBackupPayloadEntry(
          wishlist: wishlist,
          items: items,
        ),
      );
    }

    final payload = WishlistBackupPayload(
      generatedAt: DateTime.now(),
      entries: entries,
    );

    final dir = await getTemporaryDirectory();
    final sanitizedStamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/wishlists-export-$sanitizedStamp.json');
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(payload.toJson()),
      flush: true,
    );

    appLog('Wishlists exported', tag: 'BACKUP', data: {
      'wishlists': wishlists.length,
      'items': totalItems,
      'path': file.path,
    });

    return WishlistExportResult(
      file: file,
      wishlistCount: wishlists.length,
      itemCount: totalItems,
    );
  }

  Future<WishlistImportSummary> importFromJson(String jsonContent) async {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      return const WishlistImportSummary(
        wishlistsCreated: 0,
        itemsCreated: 0,
        errors: ['User must be authenticated to import wishlists'],
      );
    }

    try {
      final raw = jsonDecode(jsonContent) as Map<String, dynamic>;
      final payload = WishlistBackupPayload.fromJson(raw);

      var wishlistsCreated = 0;
      var itemsCreated = 0;
      final errors = <String>[];

      for (final entry in payload.entries) {
        final wishlist = entry.wishlist;
        final newWishlistId = await _wishlistRepository.createFromBackup(
          ownerId: userId,
          name: wishlist.name,
          isPrivate: wishlist.isPrivate,
          createdAt: wishlist.createdAt,
          imageUrl: null,
        );

        if (newWishlistId == null) {
          errors.add('Failed to recreate wishlist ${wishlist.name}');
          continue;
        }

        wishlistsCreated += 1;

        for (final item in entry.items) {
          final createdItemId = await _wishItemRepository.createFromBackup(
            wishlistId: newWishlistId,
            ownerId: userId,
            item: item,
          );

          if (createdItemId == null) {
            errors.add('Failed to import item ${item.name} (${wishlist.name})');
            continue;
          }
          itemsCreated += 1;

          // Post-import enrichment: if item has link but no image, fetch metadata/image asynchronously
          final hasLink = (item.link != null && item.link!.trim().isNotEmpty);
          final hasImage = (item.imageUrl != null && item.imageUrl!.trim().isNotEmpty);
          if (hasLink && !hasImage) {
            _scheduleItemEnrichment(createdItemId, item);
          }
        }
      }

      appLog('Wishlist import finished', tag: 'BACKUP', data: {
        'wishlists': wishlistsCreated,
        'items': itemsCreated,
        'errors': errors.length,
      });

      return WishlistImportSummary(
        wishlistsCreated: wishlistsCreated,
        itemsCreated: itemsCreated,
        errors: errors,
      );
    } catch (e, st) {
      logE('Wishlist import failed', tag: 'BACKUP', error: e, stackTrace: st);
      return WishlistImportSummary(
        wishlistsCreated: 0,
        itemsCreated: 0,
        errors: ['Invalid backup file: ${e.toString()}'],
      );
    }
  }

  Future<WishlistImportSummary> importFromFile(File file) async {
    final content = await file.readAsString();
    return importFromJson(content);
  }

  // Schedules enrichment for an imported item and updates its document with results (image/price/link/status).
  void _scheduleItemEnrichment(String newItemId, WishItem importedItem) {
    try {
      final link = importedItem.link;
      if (link == null || link.trim().isEmpty) return;

      Future.microtask(() async {
        try {
          final svc = ShareEnrichmentService();
          final res = await svc.processSharedText(link);
          final data = await res.enrichmentFuture; // may be null if parsing failed
          if (data == null) {
            await _wishItemRepository.update(newItemId, {'enrich_status': 'failed'});
            return;
          }

          final image = (data['image'] ?? '').toString().trim();
          final priceRaw = data['price'];
          final canonicalUrl = (data['canonicalUrl'] ?? '').toString().trim();
          final isRateLimited = data['rateLimited'] == true;

          final update = <String, dynamic>{};
          var enriched = false;

          if (image.isNotEmpty) {
            var finalImageUrl = image;
            if (!_isCloudinaryUrl(image)) {
              try {
                final mirror = await FirebaseFunctionsService().mirrorToCloudinary(
                  url: image,
                  folder: 'wishlist/products',
                  publicIdHint: 'import_$newItemId',
                );
                final secureUrl = (mirror['secure_url'] ?? '').toString().trim();
                if (secureUrl.isNotEmpty) {
                  finalImageUrl = secureUrl;
                }
              } catch (mirrorErr, mirrorSt) {
                logE(
                  'Mirror to Cloudinary failed',
                  tag: 'BACKUP',
                  error: mirrorErr,
                  stackTrace: mirrorSt,
                  data: {'itemId': newItemId},
                );
              }
            }
            update['image_url'] = finalImageUrl;
            enriched = true;
          }

          final price = _parsePrice(priceRaw);
          if (price != null && importedItem.price == null) {
            update['price'] = price;
            enriched = true;
          }

          if (canonicalUrl.isNotEmpty) {
            update['link'] = canonicalUrl;
          }

          if (isRateLimited) {
            update['enrich_status'] = 'rate_limited';
          } else {
            update['enrich_status'] = enriched ? 'enriched' : 'failed';
          }

          final ok = await _wishItemRepository.update(newItemId, update);
          if (!ok) {
            appLog('Post-import enrichment update failed', tag: 'BACKUP', data: {'itemId': newItemId});
          }
        } catch (e, st) {
          logE('Post-import enrichment error', tag: 'BACKUP', error: e, stackTrace: st, data: {'itemId': newItemId});
          try {
            await _wishItemRepository.update(newItemId, {'enrich_status': 'failed'});
          } catch (_) {}
        }
      });
    } catch (e) {
      // non-fatal; import should succeed regardless
      appLog('Failed to schedule enrichment', tag: 'BACKUP', data: {'itemId': newItemId, 'err': e.toString()});
    }
  }

  double? _parsePrice(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.replaceAll(RegExp(r'[^0-9.,-]'), '').replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(s);
    }
    return null;
  }

  bool _isCloudinaryUrl(String url) {
    try {
      final host = Uri.parse(url).host.toLowerCase();
      return host.contains('res.cloudinary.com');
    } catch (_) {
      return false;
    }
  }
}
