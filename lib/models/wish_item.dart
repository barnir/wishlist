import 'package:cloud_firestore/cloud_firestore.dart';

// Canonical WishItem model.
// Duplicates (wish_item_fixed.dart / wish_item_corrected.dart) were removed after
// confirming identical structure. Future changes must happen ONLY here to avoid
// divergence. Firestore expected fields: name, link, description, price, image_url,
// category, rating, created_at (Timestamp or ISO8601 String).

class WishItem {
  final String id;
  final String name;
  final String? link;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String category;
  final double? rating;
  final int quantity;
  final DateTime createdAt;
  // Enrichment (link metadata) optional fields (added Sept 2025)
  final String? enrichStatus; // pending | enriched | failed
  final String? enrichMetadataRef; // reference id in link_metadata collection

  WishItem({
    required this.id,
    required this.name,
    this.link,
    this.description,
    this.price,
    this.imageUrl,
    required this.category,
    this.rating,
  this.quantity = 1,
    required this.createdAt,
    this.enrichStatus,
    this.enrichMetadataRef,
  });

  factory WishItem.fromMap(Map<String, dynamic> data) {
    // Handle Firestore Timestamp conversion
    DateTime createdAt;
    final createdAtField = data['created_at'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is String) {
      createdAt = DateTime.parse(createdAtField);
    } else {
      createdAt = DateTime.now(); // Fallback
    }

    return WishItem(
      id: data['id'] as String,
      name: data['name'] ?? '',
      link: data['link'] as String?,
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      imageUrl: data['image_url'] as String?,
      category: data['category'] ?? 'Outros',
      rating: (data['rating'] as num?)?.toDouble(),
      quantity: _parseQuantity(data['quantity']),
      createdAt: createdAt,
  enrichStatus: data['enrich_status'] as String?,
  enrichMetadataRef: data['enrich_metadata_ref'] as String?,
    );
  }

  static int _parseQuantity(dynamic v) {
    if (v == null) return 1;
    if (v is int) return v <= 0 ? 1 : v;
    if (v is num) return v.toInt() <= 0 ? 1 : v.toInt();
    if (v is String) {
      final p = int.tryParse(v.trim());
      if (p == null || p <= 0) return 1;
      return p;
    }
    return 1;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'link': link,
      'description': description,
      'price': price,
      'image_url': imageUrl,
      'category': category,
      'rating': rating,
  'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
  if (enrichStatus != null) 'enrich_status': enrichStatus,
  if (enrichMetadataRef != null) 'enrich_metadata_ref': enrichMetadataRef,
    };
  }
}
