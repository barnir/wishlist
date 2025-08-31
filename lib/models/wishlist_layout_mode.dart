enum WishlistLayoutMode { list, grid }

extension WishlistLayoutModeX on WishlistLayoutMode {
  String get iconSemanticLabel {
    switch (this) {
      case WishlistLayoutMode.list:
        return 'Mudar para grelha';
      case WishlistLayoutMode.grid:
        return 'Mudar para lista';
    }
  }

  String get tooltip {
    switch (this) {
      case WishlistLayoutMode.list:
        return 'Vista em grelha';
      case WishlistLayoutMode.grid:
        return 'Vista em lista';
    }
  }

  WishlistLayoutMode get toggled =>
      this == WishlistLayoutMode.list ? WishlistLayoutMode.grid : WishlistLayoutMode.list;
}
