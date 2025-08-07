import 'package:cloud_firestore/cloud_firestore.dart';

class WishItem {
  final String id;
  final String name;
  final String? link;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String category;
  final Timestamp createdAt;

  WishItem({
    required this.id,
    required this.name,
    this.link,
    this.description,
    this.price,
    this.imageUrl,
    required this.category,
    required this.createdAt,
  });

  factory WishItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return WishItem(
      id: doc.id,
      name: data['name'] ?? '',
      link: data['link'] as String?,
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      imageUrl: data['imageUrl'] as String?,
      category: data['category'] ?? 'Outros',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'link': link,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'createdAt': createdAt,
    };
  }
}