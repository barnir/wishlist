class WishItemStatus {
  final String id;
  final String wishItemId;
  final String userId; // Quem marcou o status
  final ItemPurchaseStatus status;
  final bool visibleToOwner; // Se o dono pode ver que foi comprado
  final String? notes; // Notas privadas do amigo
  final DateTime createdAt;
  final DateTime? updatedAt;

  WishItemStatus({
    required this.id,
    required this.wishItemId,
    required this.userId,
    required this.status,
    this.visibleToOwner = false,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory WishItemStatus.fromMap(Map<String, dynamic> map) {
    return WishItemStatus(
      id: map['id'] as String,
      wishItemId: map['wish_item_id'] as String,
      userId: map['user_id'] as String,
      status: ItemPurchaseStatus.fromString(map['status'] as String),
      visibleToOwner: map['visible_to_owner'] as bool? ?? false,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'wish_item_id': wishItemId,
      'user_id': userId,
      'status': status.value,
      'visible_to_owner': visibleToOwner,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  WishItemStatus copyWith({
    String? id,
    String? wishItemId,
    String? userId,
    ItemPurchaseStatus? status,
    bool? visibleToOwner,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WishItemStatus(
      id: id ?? this.id,
      wishItemId: wishItemId ?? this.wishItemId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      visibleToOwner: visibleToOwner ?? this.visibleToOwner,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ItemPurchaseStatus {
  willBuy('will_buy'),
  purchased('purchased');

  const ItemPurchaseStatus(this.value);
  final String value;

  static ItemPurchaseStatus fromString(String value) {
    return ItemPurchaseStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => ItemPurchaseStatus.willBuy,
    );
  }

  String get displayName {
    switch (this) {
      case ItemPurchaseStatus.willBuy:
        return 'Vou comprar';
      case ItemPurchaseStatus.purchased:
        return 'Comprado';
    }
  }

  String get shortDisplayName {
    switch (this) {
      case ItemPurchaseStatus.willBuy:
        return 'Reservado';
      case ItemPurchaseStatus.purchased:
        return 'Comprado';
    }
  }
}

// Classe para agregar informações de status para um item
class WishItemWithStatus {
  final Map<String, dynamic> wishItem;
  final List<WishItemStatus> friendStatuses;
  final WishItemStatus? myStatus;

  WishItemWithStatus({
    required this.wishItem,
    required this.friendStatuses,
    this.myStatus,
  });

  // Se algum amigo marcou como comprado E visível para o dono
  bool get isVisiblyPurchased {
    return friendStatuses.any((status) => 
        status.status == ItemPurchaseStatus.purchased && 
        status.visibleToOwner);
  }

  // Se algum amigo (que não sou eu) marcou algum status
  bool get hasFriendActivity {
    return friendStatuses.isNotEmpty;
  }

  // Se eu marquei algum status
  bool get hasMyStatus {
    return myStatus != null;
  }

  // Status prioritário para mostrar na UI
  WishItemStatus? get priorityStatus {
    // 1. Meu status tem prioridade
    if (myStatus != null) return myStatus;
    
    // 2. Status comprado tem prioridade sobre "vou comprar"
    final purchased = friendStatuses
        .where((s) => s.status == ItemPurchaseStatus.purchased)
        .toList();
    if (purchased.isNotEmpty) return purchased.first;
    
    // 3. Qualquer outro status
    if (friendStatuses.isNotEmpty) return friendStatuses.first;
    
    return null;
  }

  // Número de amigos interessados no item
  int get friendInterestCount {
    return friendStatuses.length;
  }
}