import 'package:shared_preferences/shared_preferences.dart';

/// Tracks local usage frequency of categories to surface most used first.
class CategoryUsageService {
  static const _keyPrefix = 'cat.usage.'; // stored as cat.usage.<name>
  static const _listKey = 'cat.usage.list';
  static final CategoryUsageService _instance = CategoryUsageService._internal();
  CategoryUsageService._internal();
  factory CategoryUsageService() => _instance;

  Future<void> recordUse(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$category';
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + 1);
    // Maintain a set of seen categories for quick enumeration
    final existing = prefs.getStringList(_listKey) ?? [];
    if (!existing.contains(category)) {
      await prefs.setStringList(_listKey, [...existing, category]);
    }
  }

  Future<Map<String, int>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_listKey) ?? [];
    final map = <String, int>{};
    for (final c in list) {
      map[c] = prefs.getInt('$_keyPrefix$c') ?? 0;
    }
    return map;
  }

  /// Returns categories sorted by descending usage, then alphabetically.
  Future<List<String>> sortByUsage(List<String> categories) async {
    final usage = await loadAll();
    final list = [...categories];
    list.sort((a, b) {
      final ua = usage[a] ?? 0;
      final ub = usage[b] ?? 0;
      if (ua == ub) return a.toLowerCase().compareTo(b.toLowerCase());
      return ub.compareTo(ua);
    });
    return list;
  }
}