class WishItem {
  final String id;
  final String name;
  final String? link;
  final String? description;
  final double? price;
  final String? imageUrl;
  final String category;
  final DateTime createdAt;

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

  factory WishItem.fromMap(Map<String, dynamic> data) {
    return WishItem(
      id: data['id'] as String,
      name: data['name'] ?? '',
      link: data['link'] as String?,
      description: data['description'] as String?,
      price: (data['price'] as num?)?.toDouble(),
      imageUrl: data['image_url'] as String?,
      category: data['category'] ?? 'Outros',
      createdAt: DateTime.parse(data['created_at'] as String),
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
      'created_at': createdAt.toIso8601String(),
    };
  }
}