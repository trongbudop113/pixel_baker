import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WishlistSession extends ChangeNotifier {
  static const _favoritesKey = 'wishlist.product_ids';

  SharedPreferences? _preferences;
  Set<int> _productIds = <int>{};

  Set<int> get productIds => Set<int>.unmodifiable(_productIds);
  int get itemCount => _productIds.length;

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _restore();
  }

  bool contains(int productId) => _productIds.contains(productId);

  void toggle(int productId) {
    if (_productIds.contains(productId)) {
      _productIds.remove(productId);
    } else {
      _productIds.add(productId);
    }
    notifyListeners();
    _persist();
  }

  Future<void> _restore() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    final raw = preferences.getString(_favoritesKey);
    if (raw == null || raw.trim().isEmpty) {
      _productIds = <int>{};
      notifyListeners();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _productIds = decoded
            .map((item) => item is num ? item.toInt() : int.tryParse('$item'))
            .whereType<int>()
            .toSet();
      }
    } catch (_) {
      _productIds = <int>{};
      await preferences.remove(_favoritesKey);
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    await preferences.setString(
      _favoritesKey,
      jsonEncode(_productIds.toList(growable: false)),
    );
  }
}
