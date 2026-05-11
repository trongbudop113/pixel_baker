import 'ui_accent.dart';

class HomePageResponse {
  const HomePageResponse({
    required this.hero,
    required this.highlights,
    required this.featuredProducts,
    required this.story,
    required this.categories,
    required this.testimonials,
    required this.faqs,
    required this.promo,
    required this.footer,
  });

  final HomeHeroSection hero;
  final List<HomeInfoHighlight> highlights;
  final List<HomeFeaturedProduct> featuredProducts;
  final HomeStorySection story;
  final List<HomeCategory> categories;
  final List<HomeTestimonial> testimonials;
  final List<HomeFaq> faqs;
  final HomePromoBanner promo;
  final HomeFooterSection footer;

  factory HomePageResponse.fromJson(Map<String, dynamic> json) {
    return HomePageResponse(
      hero: HomeHeroSection.fromJson(
        Map<String, dynamic>.from(json['hero'] as Map),
      ),
      highlights: (json['highlights'] as List<dynamic>? ?? const [])
          .map((item) => HomeInfoHighlight.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      featuredProducts: (json['featuredProducts'] as List<dynamic>? ?? const [])
          .map((item) => HomeFeaturedProduct.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      story: HomeStorySection.fromJson(
        Map<String, dynamic>.from(json['story'] as Map),
      ),
      categories: (json['categories'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeCategory.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      testimonials: (json['testimonials'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeTestimonial.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      faqs: (json['faqs'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeFaq.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
      promo: HomePromoBanner.fromJson(
        Map<String, dynamic>.from(json['promo'] as Map),
      ),
      footer: HomeFooterSection.fromJson(
        Map<String, dynamic>.from(json['footer'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hero': hero.toJson(),
      'highlights': highlights.map((item) => item.toJson()).toList(),
      'featuredProducts':
          featuredProducts.map((item) => item.toJson()).toList(),
      'story': story.toJson(),
      'categories': categories.map((item) => item.toJson()).toList(),
      'testimonials': testimonials.map((item) => item.toJson()).toList(),
      'faqs': faqs.map((item) => item.toJson()).toList(),
      'promo': promo.toJson(),
      'footer': footer.toJson(),
    };
  }
}

class HomeHeroSection {
  const HomeHeroSection({
    required this.title,
    required this.description,
    required this.primaryAction,
    required this.secondaryAction,
  });

  final String title;
  final String description;
  final HomeActionLink primaryAction;
  final HomeActionLink secondaryAction;

  factory HomeHeroSection.fromJson(Map<String, dynamic> json) {
    return HomeHeroSection(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      primaryAction: HomeActionLink.fromJson(
        Map<String, dynamic>.from(json['primaryAction'] as Map),
      ),
      secondaryAction: HomeActionLink.fromJson(
        Map<String, dynamic>.from(json['secondaryAction'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'primaryAction': primaryAction.toJson(),
      'secondaryAction': secondaryAction.toJson(),
    };
  }
}

class HomeActionLink {
  const HomeActionLink({
    required this.label,
    this.routeName,
    this.routePath,
    this.queryParameters = const {},
  });

  final String label;
  final String? routeName;
  final String? routePath;
  final Map<String, String> queryParameters;

  factory HomeActionLink.fromJson(Map<String, dynamic> json) {
    final label = (json['label'] ?? '').toString();
    final routeName = _normalizeLegacyRouteName(
      label: label,
      routeName: json['routeName']?.toString(),
    );
    final rawQuery = json['queryParameters'];
    final query = <String, String>{};
    if (rawQuery is Map) {
      for (final entry in rawQuery.entries) {
        query[entry.key.toString()] = entry.value.toString();
      }
    }

    return HomeActionLink(
      label: label,
      routeName: routeName,
      routePath: json['routePath']?.toString(),
      queryParameters: query,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'routeName': routeName,
      'routePath': routePath,
      'queryParameters': queryParameters,
    };
  }
}

String? _normalizeLegacyRouteName({
  required String label,
  required String? routeName,
}) {
  if (label == 'Chính sách giao hàng' &&
      (routeName == 'login' || routeName == null || routeName.isEmpty)) {
    return 'deliveryPolicy';
  }
  if (label == 'Chính sách thanh toán' &&
      (routeName == 'admin' || routeName == null || routeName.isEmpty)) {
    return 'paymentPolicy';
  }
  return routeName;
}

class HomeInfoHighlight {
  const HomeInfoHighlight({
    required this.title,
    required this.description,
    required this.accent,
  });

  final String title;
  final String description;
  final UiAccent accent;

  factory HomeInfoHighlight.fromJson(Map<String, dynamic> json) {
    return HomeInfoHighlight(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      accent: UiAccentJson.fromValue((json['accent'] ?? 'gray').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'accent': accent.value,
    };
  }
}

class HomeFeaturedProduct {
  const HomeFeaturedProduct({
    required this.productId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.titleAccent,
    required this.priceAccent,
    this.averageRating = 0,
    this.reviewCount = 0,
  });

  final int productId;
  final String title;
  final String price;
  final String imageUrl;
  final UiAccent titleAccent;
  final UiAccent priceAccent;
  final double averageRating;
  final int reviewCount;

  factory HomeFeaturedProduct.fromJson(Map<String, dynamic> json) {
    return HomeFeaturedProduct(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      price: (json['price'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? '').toString(),
      titleAccent:
          UiAccentJson.fromValue((json['titleAccent'] ?? 'gray').toString()),
      priceAccent:
          UiAccentJson.fromValue((json['priceAccent'] ?? 'gray').toString()),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
      'titleAccent': titleAccent.value,
      'priceAccent': priceAccent.value,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}

class HomeStorySection {
  const HomeStorySection({
    required this.title,
    required this.description,
    required this.badgeText,
  });

  final String title;
  final String description;
  final String badgeText;

  factory HomeStorySection.fromJson(Map<String, dynamic> json) {
    return HomeStorySection(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      badgeText: (json['badgeText'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'badgeText': badgeText,
    };
  }
}

class HomeCategory {
  const HomeCategory({
    required this.label,
    required this.routeCategory,
    required this.accent,
  });

  final String label;
  final String routeCategory;
  final UiAccent accent;

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    return HomeCategory(
      label: (json['label'] ?? '').toString(),
      routeCategory: (json['routeCategory'] ?? '').toString(),
      accent: UiAccentJson.fromValue((json['accent'] ?? 'gray').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'routeCategory': routeCategory,
      'accent': accent.value,
    };
  }
}

class HomeTestimonial {
  const HomeTestimonial({
    this.id,
    required this.content,
    required this.author,
    required this.accent,
    this.createdAt,
  });

  final String? id;
  final String content;
  final String author;
  final UiAccent accent;
  final DateTime? createdAt;

  factory HomeTestimonial.fromJson(Map<String, dynamic> json) {
    return HomeTestimonial(
      id: json['id']?.toString(),
      content: (json['content'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      accent: UiAccentJson.fromValue((json['accent'] ?? 'gray').toString()),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'author': author,
      'accent': accent.value,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class HomeFaq {
  const HomeFaq({
    required this.question,
    required this.answer,
    required this.accent,
  });

  final String question;
  final String answer;
  final UiAccent accent;

  factory HomeFaq.fromJson(Map<String, dynamic> json) {
    return HomeFaq(
      question: (json['question'] ?? '').toString(),
      answer: (json['answer'] ?? '').toString(),
      accent: UiAccentJson.fromValue((json['accent'] ?? 'gray').toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'answer': answer,
      'accent': accent.value,
    };
  }
}

class HomePromoBanner {
  const HomePromoBanner({
    required this.message,
    required this.action,
  });

  final String message;
  final HomeActionLink action;

  factory HomePromoBanner.fromJson(Map<String, dynamic> json) {
    return HomePromoBanner(
      message: (json['message'] ?? '').toString(),
      action: HomeActionLink.fromJson(
        Map<String, dynamic>.from(json['action'] as Map),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'action': action.toJson(),
    };
  }
}

class HomeFooterSection {
  const HomeFooterSection({
    required this.tagline,
    required this.links,
  });

  final String tagline;
  final List<HomeActionLink> links;

  factory HomeFooterSection.fromJson(Map<String, dynamic> json) {
    return HomeFooterSection(
      tagline: (json['tagline'] ?? '').toString(),
      links: (json['links'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeActionLink.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tagline': tagline,
      'links': links.map((item) => item.toJson()).toList(),
    };
  }
}
