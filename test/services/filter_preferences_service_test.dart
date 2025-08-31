import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wishlist_app/services/filter_preferences_service.dart';
import 'package:wishlist_app/models/wishlist_layout_mode.dart';
import 'package:wishlist_app/models/sort_options.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save/load layout mode scoped e global', () async {
    final service = FilterPreferencesService();
    expect(await service.loadLayout(), isNull);

    await service.saveLayout(WishlistLayoutMode.grid);
    expect(await service.loadLayout(), WishlistLayoutMode.grid);

    await service.saveLayout(WishlistLayoutMode.list, wishlistId: 'wl1');
    expect(await service.loadLayout(wishlistId: 'wl1'), WishlistLayoutMode.list);
    // Global permanece grid
    expect(await service.loadLayout(), WishlistLayoutMode.grid);
  });

  test('save/load category + sort scoped', () async {
    final service = FilterPreferencesService();
    expect(await service.load(wishlistId: 'abc'), isNull);

    await service.save('Tech', SortOptions.priceDesc, wishlistId: 'abc');
    final loaded = await service.load(wishlistId: 'abc');
    expect(loaded, isNotNull);
    expect(loaded!.$1, 'Tech');
    expect(loaded.$2, SortOptions.priceDesc);

    // Remover categoria
    await service.save(null, SortOptions.nameAsc, wishlistId: 'abc');
    final loaded2 = await service.load(wishlistId: 'abc');
    expect(loaded2!.$1, isNull);
    expect(loaded2.$2, SortOptions.nameAsc);
  });
}
