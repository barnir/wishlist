import 'package:cloud_firestore/cloud_firestore.dart';

/// Typed representation of a user profile stored in `users` collection.
/// Only includes fields currently read / written in services. Extend safely.
class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? phoneNumber; // Some code uses `phone` others `phone_number`
  final String? photoUrl;
  final bool isPrivate;
  final bool? registrationComplete;
  final String? bio;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.photoUrl,
  this.isPrivate = false,
  this.registrationComplete,
  this.bio,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
  DateTime? parseTs(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) {
        try { return DateTime.parse(v); } catch (_) { return null; }
      }
      return null;
    }
    return UserProfile(
      id: map['id'] as String,
  // Fallback to legacy 'name' field if 'display_name' absent
  displayName: (map['display_name'] ?? map['name']) as String?,
      email: map['email'] as String?,
      phoneNumber: (map['phone_number'] ?? map['phone']) as String?,
      photoUrl: map['photo_url'] as String?,
      isPrivate: map['is_private'] as bool? ?? false,
  registrationComplete: map['registration_complete'] as bool?,
  bio: map['bio'] as String?,
  createdAt: parseTs(map['created_at']),
  updatedAt: parseTs(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'display_name': displayName,
        'email': email,
        'phone_number': phoneNumber,
        'photo_url': photoUrl,
        'is_private': isPrivate,
  'registration_complete': registrationComplete,
  'bio': bio,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? phoneNumber,
    String? photoUrl,
    bool? isPrivate,
  bool? registrationComplete,
  String? bio,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
        id: id ?? this.id,
        displayName: displayName ?? this.displayName,
        email: email ?? this.email,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        photoUrl: photoUrl ?? this.photoUrl,
        isPrivate: isPrivate ?? this.isPrivate,
  registrationComplete: registrationComplete ?? this.registrationComplete,
  bio: bio ?? this.bio,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
