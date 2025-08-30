import 'package:cloud_firestore/cloud_firestore.dart';

class WishItem {
  final String id;
  final String name;
  final String? link;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String category;
  final double? rating;
  final DateTime createdAt;

  WishItem({
    required this.id,
    required this.name,
    this.link,
    this.description,
    this.price,
    this.imageUrl,
    required this.category,
    this.rating,
    required this.createdAt,
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
      createdAt: createdAt,
    );
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
      'created_at': createdAt.toIso8601String(),
    };
  }
}
