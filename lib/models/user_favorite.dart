import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for user favorites system.
/// 
/// Represents a simple unidirectional relationship where one user
/// marks another user as a favorite.
class UserFavorite {
  final String id;
  final String userId;        // Who marked the favorite
  final String favoriteUserId; // Who was marked as favorite
  final DateTime createdAt;

  UserFavorite({
    required this.id,
    required this.userId,
    required this.favoriteUserId,
    required this.createdAt,
  });

  factory UserFavorite.fromMap(Map<String, dynamic> map) {
    // Handle Firestore Timestamp conversion
    DateTime createdAt;
    final createdAtField = map['created_at'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is String) {
      createdAt = DateTime.parse(createdAtField);
    } else {
      createdAt = DateTime.now(); // Fallback
    }

    return UserFavorite(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      favoriteUserId: map['favorite_user_id'] as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'favorite_user_id': favoriteUserId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserFavorite copyWith({
    String? id,
    String? userId,
    String? favoriteUserId,
    DateTime? createdAt,
  }) {
    return UserFavorite(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      favoriteUserId: favoriteUserId ?? this.favoriteUserId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Extended model with profile information
class UserFavoriteWithProfile extends UserFavorite {
  final String? displayName;
  final String? phoneNumber;
  final bool isPrivate;
  final String? email;
  final String? bio;

  UserFavoriteWithProfile({
    required super.id,
    required super.userId,
    required super.favoriteUserId,
    required super.createdAt,
    this.displayName,
    this.phoneNumber,
    this.isPrivate = false,
  this.email,
  this.bio,
  });

  factory UserFavoriteWithProfile.fromMap(Map<String, dynamic> map) {
    // Handle Firestore Timestamp conversion
    DateTime createdAt;
    final createdAtField = map['created_at'];
    if (createdAtField is Timestamp) {
      createdAt = createdAtField.toDate();
    } else if (createdAtField is String) {
      createdAt = DateTime.parse(createdAtField);
    } else {
      createdAt = DateTime.now(); // Fallback
    }

    return UserFavoriteWithProfile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      favoriteUserId: map['favorite_user_id'] as String,
      createdAt: createdAt,
      displayName: map['display_name'] as String?,
      phoneNumber: map['phone_number'] as String?,
      isPrivate: map['is_private'] as bool? ?? false,
  email: map['email'] as String?,
  bio: map['bio'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'display_name': displayName,
      'phone_number': phoneNumber,
      'is_private': isPrivate,
  'email': email,
  'bio': bio,
    });
    return map;
  }
}