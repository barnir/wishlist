class Friendship {
  final String id;
  final String userId;
  final String friendId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Friendship({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Friendship.fromMap(Map<String, dynamic> map) {
    return Friendship(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      friendId: map['friend_id'] as String,
      status: FriendshipStatus.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'friend_id': friendId,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Friendship copyWith({
    String? id,
    String? userId,
    String? friendId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Friendship(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  blocked('blocked');

  const FriendshipStatus(this.value);
  final String value;

  static FriendshipStatus fromString(String value) {
    return FriendshipStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => FriendshipStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case FriendshipStatus.pending:
        return 'Pendente';
      case FriendshipStatus.accepted:
        return 'Aceite';
      case FriendshipStatus.rejected:
        return 'Rejeitado';
      case FriendshipStatus.blocked:
        return 'Bloqueado';
    }
  }
}