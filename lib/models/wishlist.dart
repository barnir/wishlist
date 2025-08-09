import 'package:cloud_firestore/cloud_firestore.dart';

class Wishlist {
  final String id;
  final String name;
  final String ownerId;
  final bool private;
  final DateTime createdAt;
  final String? imageUrl;

  Wishlist({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.private,
    required this.createdAt,
    this.imageUrl,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json, String id) {
    return Wishlist(
      id: id,
      name: json['name'],
      ownerId: json['ownerId'],
      private: json['private'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      // Adicionado para ler o imageUrl com segurança
      imageUrl: json.containsKey('imageUrl') ? json['imageUrl'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ownerId': ownerId,
      'private': private,
      'createdAt': createdAt,
      // Adicionado para salvar o imageUrl
      'imageUrl': imageUrl,
    };
  }
}
