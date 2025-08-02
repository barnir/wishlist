class WishItem {
  final String id;          // ID do documento Firestore
  final String title;
  final String? link;
  final String? description;
  final String category;
  final double? price;

  WishItem({
    required this.id,
    required this.title,
    this.link,
    this.description,
    required this.category,
    this.price,
  });

  // Converte o WishItem para Map (para salvar no Firestore)
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'link': link,
      'description': description,
      'category': category,
      'price': price,
    };
  }

  // Cria WishItem a partir de Map vindo do Firestore
  factory WishItem.fromMap(String id, Map<String, dynamic> map) {
    return WishItem(
      id: id,
      title: map['title'] ?? '',
      link: map['link'] as String?,
      description: map['description'] as String?,
      category: map['category'] ?? 'Outro',
      price: (map['price'] != null) ? (map['price'] as num).toDouble() : null,
    );
  }
}
