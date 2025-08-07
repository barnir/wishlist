import 'package:cloud_firestore/cloud_firestore.dart';

class Wishlist {
  final String id;
  final String name;
  final String ownerId;
  final bool private;
  final DateTime createdAt;

  Wishlist({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.private,
    required this.createdAt,
  });

  factory Wishlist.fromJson(Map<String, dynamic> json, String id) {
    return Wishlist(
      id: id,
      name: json['name'],
      ownerId: json['ownerId'],
      private: json['private'],
      createdAt: (json['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'ownerId': ownerId,
      'private': private,
      'createdAt': createdAt,
    };
  }
}