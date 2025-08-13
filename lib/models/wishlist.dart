class Wishlist {
  final String id;
  final String name;
  final String ownerId;
  final bool isPrivate;
  final DateTime createdAt;
  final String? imageUrl;

  Wishlist({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.isPrivate,
    required this.createdAt,
    this.imageUrl,
  });

  factory Wishlist.fromMap(Map<String, dynamic> data) {
    return Wishlist(
      id: data['id'] as String,
      name: data['name'] as String,
      ownerId: data['owner_id'] as String,
      isPrivate: data['is_private'] as bool,
      createdAt: DateTime.parse(data['created_at'] as String),
      imageUrl: data['image_url'] as String?,
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
}
