class WishlistItem {
  final String id;
  final String name;
  final String link;
  final double price;
  final String imageUrl;
  final String category;

  WishlistItem({
    required this.id,
    required this.name,
    required this.link,
    required this.price,
    required this.imageUrl,
    required this.category,
  });

    factory WishlistItem.fromJson(Map<String, dynamic> json, String id) {
    return WishlistItem(
      id: id,
      name: json['name'],
      link: json['link'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'link': link,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}