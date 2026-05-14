import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores up to [_maxItems] recently viewed product IDs (most recent first).
class RecentlyViewedSession extends ValueNotifier<List<int>> {
  RecentlyViewedSession() : super(const []);

  static const _key = 'recently_viewed.product_ids';
  static const _maxItems = 10;

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getStringList(_key) ?? [];
    value = raw.map((e) => int.tryParse(e) ?? -1).where((e) => e >= 0).toList();
  }

  void add(int productId) {
    final updated = List<int>.from(value)..remove(productId);
    updated.insert(0, productId);
    value = updated.length > _maxItems ? updated.sublist(0, _maxItems) : updated;
    _persist();
  }

  void clear() {
    value = [];
    _persist();
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(_key, value.map((e) => '$e').toList());
  }
}
