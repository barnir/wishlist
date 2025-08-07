class UserProfile {
  final String id;
  final bool isPrivate;

  UserProfile({required this.id, required this.isPrivate});

   factory UserProfile.fromJson(Map<String, dynamic> json, String id) {
    return UserProfile(
      id: id,
      isPrivate: json['private'] ?? false, // Default to false if not present
    );
  }
}