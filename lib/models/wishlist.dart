import 'package:cloud_firestore/cloud_firestore.dart';

class Wishlist {
  final String id;
  final String name;
  final String ownerId;
  final bool isPrivate;
  final DateTime createdAt;
  final String? imageUrl;
  // Client-side computed aggregate (not persisted unless explicitly stored)
  final double? totalValue;

  Wishlist({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.isPrivate,
    required this.createdAt,
    this.imageUrl,
  this.totalValue,
  });

  factory Wishlist.fromMap(Map<String, dynamic> data) {
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

    return Wishlist(
      id: data['id'] as String,
      name: data['name'] as String,
      ownerId: data['owner_id'] as String,
      isPrivate: data['is_private'] as bool,
      createdAt: createdAt,
      imageUrl: data['image_url'] as String?,
  // Firestore docs currently do not store aggregate; ignore if absent
  totalValue: (data['total_value'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'owner_id': ownerId,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
    };
  }

  Wishlist copyWith({
    String? id,
    String? name,
    String? ownerId,
    bool? isPrivate,
    DateTime? createdAt,
    String? imageUrl,
    double? totalValue,
  }) => Wishlist(
        id: id ?? this.id,
        name: name ?? this.name,
        ownerId: ownerId ?? this.ownerId,
        isPrivate: isPrivate ?? this.isPrivate,
        createdAt: createdAt ?? this.createdAt,
        imageUrl: imageUrl ?? this.imageUrl,
        totalValue: totalValue ?? this.totalValue,
      );
}
