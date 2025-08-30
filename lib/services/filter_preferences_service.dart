import 'package:shared_preferences/shared_preferences.dart';
import '../models/sort_options.dart';

/// Persists last used wishlist filters (category + sort) per user and per wishlist.
/// If [wishlistId] is provided the preference is scoped; otherwise falls back to global keys.
class FilterPreferencesService {
  static const _keyCategory = 'filters.lastCategory';
  static const _keySort = 'filters.lastSort';

  static SharedPreferences? _cachedPrefs;
  static Future<SharedPreferences> _prefs() async =>
      _cachedPrefs ??= await SharedPreferences.getInstance();

  String _scoped(String base, String? wishlistId) => wishlistId == null ? base : '$base.$wishlistId';

  Future<void> save(String? category, SortOptions sort, {String? wishlistId}) async {
  final prefs = await _prefs();
    final categoryKey = _scoped(_keyCategory, wishlistId);
    final sortKey = _scoped(_keySort, wishlistId);

    if (category == null) {
      await prefs.remove(categoryKey);
    } else {
      await prefs.setString(categoryKey, category);
    }
    await prefs.setString(sortKey, sort.name);
  }

  Future<(String?, SortOptions)?> load({String? wishlistId}) async {
  final prefs = await _prefs();
    final sortKey = _scoped(_keySort, wishlistId);
    final categoryKey = _scoped(_keyCategory, wishlistId);

    final sortName = prefs.getString(sortKey);
    if (sortName == null) return null;
    final category = prefs.getString(categoryKey);
    final sort = SortOptions.values.firstWhere(
      (e) => e.name == sortName,
      orElse: () => SortOptions.nameAsc,
    );
    return (category, sort);
  }
}
