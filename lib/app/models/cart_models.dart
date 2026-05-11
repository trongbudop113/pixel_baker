import 'menu_models.dart';

class CartBoxItem {
  const CartBoxItem({
    required this.productId,
    required this.title,
    required this.variantLabel,
    required this.price,
    required this.priceValue,
    this.imageUrl,
  });

  final int productId;
  final String title;
  final String variantLabel;
  final String price;
  final int priceValue;
  final String? imageUrl;

  factory CartBoxItem.fromJson(Map<String, dynamic> json) {
    return CartBoxItem(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      variantLabel: (json['variantLabel'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'variantLabel': variantLabel,
      'price': price,
      'priceValue': priceValue,
      'imageUrl': imageUrl,
    };
  }
}

class CartItem {
  const CartItem({
    required this.productId,
    required this.title,
    required this.price,
    required this.priceValue,
    required this.category,
    required this.imageUrl,
    required this.quantity,
    this.variantKey,
    this.variantLabel,
    this.boxItems = const [],
  });

  final int productId;
  final String title;
  final String price;
  final int priceValue;
  final String category;
  final String imageUrl;
  final int quantity;
  final String? variantKey;
  final String? variantLabel;
  final List<CartBoxItem> boxItems;

  factory CartItem.fromMenuProduct(
    MenuProduct product, {
    int quantity = 1,
  }) {
    return CartItem(
      productId: product.id,
      title: product.title,
      price: product.price,
      priceValue: product.priceValue,
      category: product.category,
      imageUrl: product.images.isEmpty ? '' : product.images.first,
      quantity: quantity < 1 ? 1 : quantity,
      variantKey: null,
      variantLabel: null,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      variantKey: json['variantKey']?.toString(),
      variantLabel: json['variantLabel']?.toString(),
      boxItems: ((json['boxItems'] as List?) ?? const [])
          .map((item) => CartBoxItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'priceValue': priceValue,
      'category': category,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'variantKey': variantKey,
      'variantLabel': variantLabel,
      'boxItems': boxItems.map((item) => item.toJson()).toList(growable: false),
    };
  }

  CartItem copyWith({
    int? quantity,
  }) {
    return CartItem(
      productId: productId,
      title: title,
      price: price,
      priceValue: priceValue,
      category: category,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      variantKey: variantKey,
      variantLabel: variantLabel,
      boxItems: boxItems,
    );
  }

  int get lineTotal => priceValue * quantity;

  String get identityKey => '$productId::${variantKey ?? "default"}';
}
