class MenuPageResponse {
  const MenuPageResponse({
    required this.intro,
    required this.filters,
    required this.productsSectionTitle,
    required this.products,
    required this.combo,
    required this.faqs,
    required this.footer,
  });

  final MenuIntroSection intro;
  final List<MenuFilterOption> filters;
  final String productsSectionTitle;
  final List<MenuProduct> products;
  final MenuComboSection combo;
  final List<MenuFaqItem> faqs;
  final MenuFooterSection footer;

  factory MenuPageResponse.fromJson(Map<String, dynamic> json) {
    return MenuPageResponse(
      intro: MenuIntroSection.fromJson(
        Map<String, dynamic>.from(json['intro'] as Map),
      ),
      filters: (json['filters'] as List<dynamic>? ?? const [])
          .map((item) => MenuFilterOption.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      productsSectionTitle: (json['productsSectionTitle'] ?? '').toString(),
      products: (json['products'] as List<dynamic>? ?? const [])
          .map((item) => MenuProduct.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      combo: MenuComboSection.fromJson(
        Map<String, dynamic>.from(json['combo'] as Map),
      ),
      faqs: (json['faqs'] as List<dynamic>? ?? const [])
          .map((item) => MenuFaqItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      footer: MenuFooterSection.fromJson(
        Map<String, dynamic>.from(json['footer'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'intro': intro.toJson(),
      'filters': filters.map((item) => item.toJson()).toList(),
      'productsSectionTitle': productsSectionTitle,
      'products': products.map((item) => item.toJson()).toList(),
      'combo': combo.toJson(),
      'faqs': faqs.map((item) => item.toJson()).toList(),
      'footer': footer.toJson(),
    };
  }
}

class MenuIntroSection {
  const MenuIntroSection({
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  factory MenuIntroSection.fromJson(Map<String, dynamic> json) {
    return MenuIntroSection(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}

class MenuFilterOption {
  const MenuFilterOption({
    required this.label,
    required this.category,
    this.imageUrl,
  });

  final String label;
  final String category;
  final String? imageUrl;

  factory MenuFilterOption.fromJson(Map<String, dynamic> json) {
    return MenuFilterOption(
      label: (json['label'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'category': category,
      'imageUrl': imageUrl,
    };
  }
}

class MenuProduct {
  const MenuProduct({
    required this.id,
    required this.title,
    required this.price,
    required this.priceValue,
    required this.category,
    required this.description,
    required this.images,
    this.ingredientsText = '',
    this.optionGroups = const [],
    this.averageRating = 0,
    this.reviewCount = 0,
    this.mooncakeConfig,
  });

  final int id;
  final String title;
  final String price;
  final int priceValue;
  final String category;
  final String description;
  final List<String> images;
  final String ingredientsText;
  final List<ProductOptionGroup> optionGroups;
  final double averageRating;
  final int reviewCount;
  final MooncakeProductConfig? mooncakeConfig;

  factory MenuProduct.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    return MenuProduct(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      images: rawImages is List
          ? rawImages.map((item) => item.toString()).toList(growable: false)
          : const [],
      ingredientsText: (json['ingredientsText'] ?? '').toString(),
      optionGroups: ((json['optionGroups'] as List?) ?? const [])
          .map((item) => ProductOptionGroup.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      mooncakeConfig: json['mooncakeConfig'] is Map<String, dynamic>
          ? MooncakeProductConfig.fromJson(
              Map<String, dynamic>.from(json['mooncakeConfig'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'priceValue': priceValue,
      'category': category,
      'description': description,
      'images': images,
      'ingredientsText': ingredientsText,
      'optionGroups': optionGroups.map((item) => item.toJson()).toList(),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'mooncakeConfig': mooncakeConfig?.toJson(),
    };
  }
}

class ProductOptionGroup {
  const ProductOptionGroup({
    required this.id,
    required this.label,
    required this.options,
  });

  final String id;
  final String label;
  final List<ProductOptionItem> options;

  factory ProductOptionGroup.fromJson(Map<String, dynamic> json) {
    return ProductOptionGroup(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      options: ((json['options'] as List?) ?? const [])
          .map((item) => ProductOptionItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'options': options.map((item) => item.toJson()).toList(),
    };
  }
}

class ProductOptionItem {
  const ProductOptionItem({
    required this.id,
    required this.label,
    this.priceDelta = 0,
    this.isDefault = false,
  });

  final String id;
  final String label;
  final int priceDelta;
  final bool isDefault;

  factory ProductOptionItem.fromJson(Map<String, dynamic> json) {
    return ProductOptionItem(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      priceDelta: (json['priceDelta'] as num?)?.toInt() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'priceDelta': priceDelta,
      'isDefault': isDefault,
    };
  }
}

class MooncakeProductConfig {
  const MooncakeProductConfig({
    required this.weightOptions,
    required this.boxOptions,
  });

  final List<MooncakeWeightOption> weightOptions;
  final List<MooncakeBoxOption> boxOptions;

  factory MooncakeProductConfig.fromJson(Map<String, dynamic> json) {
    return MooncakeProductConfig(
      weightOptions: ((json['weightOptions'] as List?) ?? const [])
          .map((item) => MooncakeWeightOption.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      boxOptions: ((json['boxOptions'] as List?) ?? const [])
          .map((item) => MooncakeBoxOption.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightOptions': weightOptions.map((item) => item.toJson()).toList(),
      'boxOptions': boxOptions.map((item) => item.toJson()).toList(),
    };
  }
}

class MooncakeWeightOption {
  const MooncakeWeightOption({
    required this.code,
    required this.label,
    required this.eggOptions,
  });

  final String code;
  final String label;
  final List<MooncakeEggOption> eggOptions;

  factory MooncakeWeightOption.fromJson(Map<String, dynamic> json) {
    return MooncakeWeightOption(
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      eggOptions: ((json['eggOptions'] as List?) ?? const [])
          .map((item) => MooncakeEggOption.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'eggOptions': eggOptions.map((item) => item.toJson()).toList(),
    };
  }
}

class MooncakeEggOption {
  const MooncakeEggOption({
    required this.count,
    required this.label,
    required this.priceValue,
    required this.price,
  });

  final int count;
  final String label;
  final int priceValue;
  final String price;

  factory MooncakeEggOption.fromJson(Map<String, dynamic> json) {
    return MooncakeEggOption(
      count: (json['count'] as num?)?.toInt() ?? 0,
      label: (json['label'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      price: (json['price'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'label': label,
      'priceValue': priceValue,
      'price': price,
    };
  }
}

class MooncakeBoxOption {
  const MooncakeBoxOption({
    required this.code,
    required this.label,
    required this.cakeCount,
    required this.imageUrl,
    required this.packagePriceValue,
    required this.packagePrice,
  });

  final String code;
  final String label;
  final int cakeCount;
  final String imageUrl;
  final int packagePriceValue;
  final String packagePrice;

  factory MooncakeBoxOption.fromJson(Map<String, dynamic> json) {
    return MooncakeBoxOption(
      code: (json['code'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      cakeCount: (json['cakeCount'] as num?)?.toInt() ?? 0,
      imageUrl: (json['imageUrl'] ?? '').toString(),
      packagePriceValue: (json['packagePriceValue'] as num?)?.toInt() ?? 0,
      packagePrice: (json['packagePrice'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'label': label,
      'cakeCount': cakeCount,
      'imageUrl': imageUrl,
      'packagePriceValue': packagePriceValue,
      'packagePrice': packagePrice,
    };
  }
}

class MenuReviewItem {
  const MenuReviewItem({
    required this.author,
    required this.content,
    this.rating = 5,
    this.mediaUrls = const [],
    this.createdAt,
    this.userId,
  });

  final String author;
  final String content;
  final int rating;
  final List<String> mediaUrls;
  final String? createdAt;
  final String? userId;

  factory MenuReviewItem.fromJson(Map<String, dynamic> json) {
    return MenuReviewItem(
      author: (json['author'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      mediaUrls: ((json['mediaUrls'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      createdAt: json['createdAt']?.toString(),
      userId: json['userId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'author': author,
      'content': content,
      'rating': rating,
      'mediaUrls': mediaUrls,
      'createdAt': createdAt,
      'userId': userId,
    };
  }
}

class MenuReviewDraft {
  const MenuReviewDraft({
    required this.rating,
    required this.content,
    this.mediaUrls = const [],
  });

  final int rating;
  final String content;
  final List<String> mediaUrls;

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      'content': content,
      'mediaUrls': mediaUrls,
    };
  }
}

class MenuProductDetail extends MenuProduct {
  const MenuProductDetail({
    required super.id,
    required super.title,
    required super.price,
    required super.priceValue,
    required super.category,
    required super.description,
    required super.images,
    required this.sku,
    required this.stockStatus,
    required this.weight,
    required this.storageNote,
    required this.deliveryNote,
    required this.detailBullets,
    required this.reviews,
    required this.relatedProducts,
    super.averageRating = 0,
    super.reviewCount = 0,
    super.ingredientsText,
    super.optionGroups,
    super.mooncakeConfig,
  });

  final String sku;
  final String stockStatus;
  final String weight;
  final String storageNote;
  final String deliveryNote;
  final List<String> detailBullets;
  final List<MenuReviewItem> reviews;
  final List<MenuProduct> relatedProducts;

  factory MenuProductDetail.fromJson(Map<String, dynamic> json) {
    return MenuProductDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      images: ((json['images'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      ingredientsText: (json['ingredientsText'] ?? '').toString(),
      optionGroups: ((json['optionGroups'] as List?) ?? const [])
          .map((item) => ProductOptionGroup.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      sku: (json['sku'] ?? '').toString(),
      stockStatus: (json['stockStatus'] ?? '').toString(),
      weight: (json['weight'] ?? '').toString(),
      storageNote: (json['storageNote'] ?? '').toString(),
      deliveryNote: (json['deliveryNote'] ?? '').toString(),
      detailBullets: ((json['detailBullets'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      reviews: ((json['reviews'] as List?) ?? const [])
          .map((item) => MenuReviewItem.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      relatedProducts: ((json['relatedProducts'] as List?) ?? const [])
          .map((item) => MenuProduct.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      mooncakeConfig: json['mooncakeConfig'] is Map<String, dynamic>
          ? MooncakeProductConfig.fromJson(
              Map<String, dynamic>.from(json['mooncakeConfig'] as Map),
            )
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      ...super.toJson(),
      'sku': sku,
      'stockStatus': stockStatus,
      'weight': weight,
      'storageNote': storageNote,
      'deliveryNote': deliveryNote,
      'detailBullets': detailBullets,
      'reviews': reviews.map((item) => item.toJson()).toList(),
      'relatedProducts': relatedProducts.map((item) => item.toJson()).toList(),
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'mooncakeConfig': mooncakeConfig?.toJson(),
    };
  }
}

class MenuComboSection {
  const MenuComboSection({
    required this.title,
    required this.description,
    required this.actionLabel,
  });

  final String title;
  final String description;
  final String actionLabel;

  factory MenuComboSection.fromJson(Map<String, dynamic> json) {
    return MenuComboSection(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      actionLabel: (json['actionLabel'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'actionLabel': actionLabel,
    };
  }
}

class MenuFaqItem {
  const MenuFaqItem({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  factory MenuFaqItem.fromJson(Map<String, dynamic> json) {
    return MenuFaqItem(
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
    };
  }
}

class MenuFooterSection {
  const MenuFooterSection({
    required this.tagline,
  });

  final String tagline;

  factory MenuFooterSection.fromJson(Map<String, dynamic> json) {
    return MenuFooterSection(
      tagline: (json['tagline'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tagline': tagline,
    };
  }
}
