import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/cart_models.dart';
import '../models/home_models.dart';
import '../models/menu_models.dart';

class CartSession extends ChangeNotifier {
  static const _cartItemsKey = 'cart.items';

  SharedPreferences? _preferences;
  List<CartItem> _items = const [];
  Future<List<CartItem>> Function()? _loadRemoteItems;
  Future<List<CartItem>> Function(List<CartItem> guestItems)? _mergeRemoteItems;
  Future<List<CartItem>> Function(List<CartItem> items)? _replaceRemoteItems;
  bool Function()? _canSyncRemotely;

  List<CartItem> get items => List<CartItem>.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  int get itemCount =>
      _items.fold<int>(0, (sum, item) => sum + item.quantity);
  int get subtotal =>
      _items.fold<int>(0, (sum, item) => sum + item.lineTotal);

  int quantityForProduct(int productId) {
    return _items
        .where((item) => item.productId == productId)
        .fold<int>(0, (sum, item) => sum + item.quantity);
  }

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _restore();
  }

  void configureSync({
    Future<List<CartItem>> Function()? loadRemoteItems,
    Future<List<CartItem>> Function(List<CartItem> guestItems)? mergeRemoteItems,
    Future<List<CartItem>> Function(List<CartItem> items)? replaceRemoteItems,
    bool Function()? canSyncRemotely,
  }) {
    _loadRemoteItems = loadRemoteItems;
    _mergeRemoteItems = mergeRemoteItems;
    _replaceRemoteItems = replaceRemoteItems;
    _canSyncRemotely = canSyncRemotely;
  }

  void addProduct(MenuProduct product, {int quantity = 1}) {
    addCartItem(
      CartItem.fromMenuProduct(product, quantity: quantity < 1 ? 1 : quantity),
    );
  }

  void addCartItem(CartItem item) {
    final normalizedQuantity = item.quantity < 1 ? 1 : item.quantity;
    final normalizedItem = item.copyWith(quantity: normalizedQuantity);
    final index = _items.indexWhere(
      (current) => current.identityKey == normalizedItem.identityKey,
    );
    if (index == -1) {
      _items = [
        ..._items,
        normalizedItem,
      ];
    } else {
      final current = _items[index];
      final updated = current.copyWith(
        quantity: current.quantity + normalizedQuantity,
      );
      _items = [
        ..._items.take(index),
        updated,
        ..._items.skip(index + 1),
      ];
    }
    notifyListeners();
    unawaited(_persist());
    if (_canSyncRemotely?.call() == true) {
      unawaited(syncRemoteSnapshot());
    }
  }

  void addProductWithVariant(
    MenuProduct product, {
    required String variantKey,
    required String variantLabel,
    required int priceValue,
    required String price,
    int quantity = 1,
    String? imageUrl,
  }) {
    final normalizedQuantity = quantity < 1 ? 1 : quantity;
    addCartItem(
      CartItem(
        productId: product.id,
        title: product.title,
        price: price,
        priceValue: priceValue,
        category: product.category,
        imageUrl: imageUrl ?? (product.images.isEmpty ? '' : product.images.first),
        quantity: normalizedQuantity,
        variantKey: variantKey,
        variantLabel: variantLabel,
      ),
    );
  }

  void addFeaturedProduct(
    HomeFeaturedProduct product, {
    int quantity = 1,
  }) {
    final normalizedQuantity = quantity < 1 ? 1 : quantity;
    addCartItem(
      CartItem(
        productId: product.productId,
        title: product.title,
        price: product.price,
        priceValue: _parsePriceValue(product.price),
        category: 'featured',
        imageUrl: product.imageUrl,
        quantity: normalizedQuantity,
      ),
    );
  }

  void removeProduct(int productId, {String? variantKey}) {
    if (variantKey == null) {
      _items = _items.where((item) => item.productId != productId).toList();
    } else {
      _items = _items
          .where(
            (item) =>
                !(item.productId == productId && item.variantKey == variantKey),
          )
          .toList();
    }
    notifyListeners();
    unawaited(_persist());
    if (_canSyncRemotely?.call() == true) {
      unawaited(syncRemoteSnapshot());
    }
  }

  void removeItem(CartItem item) {
    _items = _items
        .where((current) => current.identityKey != item.identityKey)
        .toList(growable: false);
    notifyListeners();
    unawaited(_persist());
    if (_canSyncRemotely?.call() == true) {
      unawaited(syncRemoteSnapshot());
    }
  }

  void incrementItem(CartItem item) {
    _updateItemQuantity(item.identityKey, item.quantity + 1);
  }

  void decrementItem(CartItem item) {
    final nextQuantity = item.quantity - 1;
    if (nextQuantity < 1) {
      return;
    }
    _updateItemQuantity(item.identityKey, nextQuantity);
  }

  void clear() {
    _items = const [];
    notifyListeners();
    unawaited(_clearPersisted());
    if (_canSyncRemotely?.call() == true) {
      unawaited(syncRemoteSnapshot());
    }
  }

  Future<void> replaceAll(List<CartItem> items) async {
    _items = List<CartItem>.unmodifiable(items);
    notifyListeners();
    await _persist();
  }

  Future<void> syncAfterLogin() async {
    final mergeRemoteItems = _mergeRemoteItems;
    final loadRemoteItems = _loadRemoteItems;
    if (mergeRemoteItems == null && loadRemoteItems == null) {
      return;
    }

    final localItems = List<CartItem>.from(_items);
    final merged = localItems.isNotEmpty && mergeRemoteItems != null
        ? await mergeRemoteItems(localItems)
        : await (loadRemoteItems?.call() ?? Future.value(localItems));
    await replaceAll(merged);
  }

  Future<void> loadRemoteSnapshot() async {
    final loadRemoteItems = _loadRemoteItems;
    if (loadRemoteItems == null) {
      return;
    }
    final remoteItems = await loadRemoteItems();
    await replaceAll(remoteItems);
  }

  Future<void> syncRemoteSnapshot() async {
    final replaceRemoteItems = _replaceRemoteItems;
    if (replaceRemoteItems == null) {
      return;
    }
    final remoteItems = await replaceRemoteItems(List<CartItem>.from(_items));
    await replaceAll(remoteItems);
  }

  Future<void> _restore() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    final raw = preferences.getString(_cartItemsKey);
    if (raw == null || raw.trim().isEmpty) {
      _items = const [];
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _items = decoded
            .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
            .toList(growable: false);
      } else {
        _items = const [];
      }
    } catch (_) {
      _items = const [];
      await _clearPersisted();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    if (_items.isEmpty) {
      await _clearPersisted();
      return;
    }

    await preferences.setString(
      _cartItemsKey,
      jsonEncode(_items.map((item) => item.toJson()).toList(growable: false)),
    );
  }

  Future<void> _clearPersisted() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    await preferences.remove(_cartItemsKey);
  }

  int _parsePriceValue(String price) {
    final digits = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  void _updateItemQuantity(String identityKey, int quantity) {
    final index = _items.indexWhere((item) => item.identityKey == identityKey);
    if (index == -1) {
      return;
    }
    final safeQuantity = quantity < 1 ? 1 : quantity;
    _items = [
      ..._items.take(index),
      _items[index].copyWith(quantity: safeQuantity),
      ..._items.skip(index + 1),
    ];
    notifyListeners();
    unawaited(_persist());
    if (_canSyncRemotely?.call() == true) {
      unawaited(syncRemoteSnapshot());
    }
  }
}
