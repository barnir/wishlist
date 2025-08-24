enum SortOptions { priceAsc, priceDesc, nameAsc, nameDesc }

extension SortOptionsExtension on SortOptions {
  String get displayName {
    switch (this) {
      case SortOptions.nameAsc:
        return 'Nome (A-Z)';
      case SortOptions.nameDesc:
        return 'Nome (Z-A)';
      case SortOptions.priceAsc:
        return 'Preço (Menor-Maior)';
      case SortOptions.priceDesc:
        return 'Preço (Maior-Menor)';
    }
  }
}
