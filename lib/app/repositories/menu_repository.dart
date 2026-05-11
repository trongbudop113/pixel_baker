import '../models/menu_models.dart';
import '../network/base_api_repository.dart';

abstract class MenuRepository {
  Future<MenuPageResponse> fetchMenuPage();

  Future<List<MenuProduct>> fetchProducts();

  Future<MenuProductDetail?> fetchProductDetailById(int id);

  Future<MenuProduct?> fetchProductById(int id);

  Future<MenuProductDetail> submitReview(int productId, MenuReviewDraft draft);

  MenuProduct? findCachedProductById(int id);
}

class ApiMenuRepository extends BaseApiRepository implements MenuRepository {
  ApiMenuRepository(super.apiClient);

  MenuPageResponse? _cachedMenuPage;
  List<MenuProduct>? _cachedProducts;

  @override
  Future<MenuPageResponse> fetchMenuPage() async {
    if (_cachedMenuPage != null) {
      return _cachedMenuPage!;
    }

    if (!apiClient.config.hasBaseUrl) {
      return _cacheMenuPage(defaultMenuPageResponse);
    }

    try {
      final response = await apiClient.get<MenuPageResponse>(
        '/menu',
        decoder: (json) => readItem(
          _unwrapItemPayload(json),
          MenuPageResponse.fromJson,
        ),
      );
      return _cacheMenuPage(response.data);
    } catch (_) {
      return _cacheMenuPage(defaultMenuPageResponse);
    }
  }

  @override
  Future<List<MenuProduct>> fetchProducts() async {
    final page = await fetchMenuPage();
    return _cacheProducts(page.products);
  }

  @override
  Future<MenuProductDetail?> fetchProductDetailById(int id) async {
    if (!apiClient.config.hasBaseUrl) {
      return _fallbackProductDetail(id);
    }

    try {
      final response = await apiClient.get<MenuProductDetail>(
        '/menu/products/$id',
        decoder: (json) => readItem(
          _unwrapItemPayload(json),
          MenuProductDetail.fromJson,
        ),
      );
      final detail = response.data;
      _upsertCachedProduct(detail);
      return detail;
    } catch (_) {
      return _fallbackProductDetail(id);
    }
  }

  @override
  Future<MenuProduct?> fetchProductById(int id) async {
    final cached = findCachedProductById(id);
    if (cached != null) {
      return cached;
    }

    if (!apiClient.config.hasBaseUrl) {
      return defaultMenuPageResponse.products.where((item) => item.id == id).firstOrNull;
    }

    try {
      final detail = await fetchProductDetailById(id);
      return detail;
    } catch (_) {
      return defaultMenuPageResponse.products.where((item) => item.id == id).firstOrNull;
    }
  }

  @override
  Future<MenuProductDetail> submitReview(int productId, MenuReviewDraft draft) async {
    final response = await apiClient.post<MenuProductDetail>(
      '/menu/products/$productId/reviews',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        MenuProductDetail.fromJson,
      ),
    );
    final detail = response.data;
    _upsertCachedProduct(detail);
    return detail;
  }

  @override
  MenuProduct? findCachedProductById(int id) {
    final source = _cachedProducts ?? _cachedMenuPage?.products ?? defaultMenuPageResponse.products;
    for (final product in source) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    return json;
  }

  MenuPageResponse _cacheMenuPage(MenuPageResponse response) {
    _cachedMenuPage = response;
    _cacheProducts(response.products);
    return response;
  }

  List<MenuProduct> _cacheProducts(List<MenuProduct> products) {
    _cachedProducts = List<MenuProduct>.unmodifiable(products);
    return _cachedProducts!;
  }

  void _upsertCachedProduct(MenuProduct product) {
    final current = [...?_cachedProducts];
    final existingIndex = current.indexWhere((item) => item.id == product.id);
    if (existingIndex >= 0) {
      current[existingIndex] = product;
    } else {
      current.add(product);
    }
    _cachedProducts = List<MenuProduct>.unmodifiable(current);
  }

  MenuProductDetail? _fallbackProductDetail(int id) {
    final product = defaultMenuPageResponse.products.where((item) => item.id == id).firstOrNull;
    if (product == null) {
      return null;
    }
    final relatedProducts = defaultMenuPageResponse.products
        .where((item) => item.id != product.id && item.category == product.category)
        .take(3)
        .toList(growable: false);
    return MenuProductDetail(
      id: product.id,
      title: product.title,
      price: product.price,
      priceValue: product.priceValue,
      category: product.category,
      description: product.description,
      images: product.images,
      sku: 'BK-${product.category.toUpperCase()}-${product.id.toString().padLeft(2, '0')}',
      stockStatus: 'Còn hàng',
      weight: product.category == 'Combo' ? '1.2kg' : '420g',
      storageNote: product.category == 'Cookie'
          ? 'Đậy kín, dùng ngon trong 5 ngày'
          : '2-4°C, dùng ngon trong 48h',
      deliveryNote: 'Nội thành 2 giờ',
      detailBullets: [
        product.description,
        'Bộ ảnh sản phẩm gồm ${product.images.length} góc chụp.',
        'Giá niêm yết ${product.price}.',
      ],
      reviews: const [
        MenuReviewItem(
          author: 'Minh Anh',
          content: 'Bánh đẹp và ngon, giao đúng giờ.',
        ),
      ],
      relatedProducts: relatedProducts,
      averageRating: product.averageRating,
      reviewCount: product.reviewCount,
      mooncakeConfig: product.mooncakeConfig,
    );
  }
}

const MenuPageResponse defaultMenuPageResponse = MenuPageResponse(
  intro: MenuIntroSection(
    title: 'Chọn bánh theo phong cách của bạn',
    description: 'Từ cupcake, cookie đến combo tiết kiệm mỗi ngày.',
  ),
  filters: [
    MenuFilterOption(label: 'Tất cả', category: 'all'),
    MenuFilterOption(label: 'Cupcake', category: 'Cupcake'),
    MenuFilterOption(label: 'Cookie', category: 'Cookie'),
    MenuFilterOption(label: 'Bánh kem', category: 'Bánh kem'),
    MenuFilterOption(label: 'Bánh pía', category: 'Bánh pía'),
    MenuFilterOption(label: 'Bánh trung thu', category: 'mooncake'),
  ],
  productsSectionTitle: 'Món bán chạy',
  products: [
    MenuProduct(
      id: 1,
      title: 'Bánh dâu pixel',
      price: '55.000đ',
      priceValue: 55000,
      category: 'Cupcake',
      description: 'Bánh mềm, kem ít ngọt, topping dâu tươi.',
      images: [
        'https://images.unsplash.com/photo-1621177921600-13666f61db2d?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 2,
      title: 'Cookie choco',
      price: '48.000đ',
      priceValue: 48000,
      category: 'Cookie',
      description: 'Cookie giòn bên ngoài, mềm bên trong, vị cacao đậm.',
      images: [
        'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1495214783159-3503fd1b572d?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 3,
      title: 'Tart lá xanh',
      price: '58.000đ',
      priceValue: 58000,
      category: 'Tart',
      description: 'Tart mát nhẹ, cân bằng vị trái cây và kem.',
      images: [
        'https://images.unsplash.com/photo-1464306076886-da185f6a9d05?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1486427944299-d1955d23e34d?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 4,
      title: 'Cupcake vanilla',
      price: '45.000đ',
      priceValue: 45000,
      category: 'Cupcake',
      description: 'Cupcake vanilla mềm mịn, lớp kem béo nhẹ.',
      images: [
        'https://images.unsplash.com/photo-1505253213348-cd54c92b37f6?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1519869325930-281384150729?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1576618148400-f54bed99fcfd?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 5,
      title: 'Bánh chuối nướng',
      price: '52.000đ',
      priceValue: 52000,
      category: 'Cake',
      description: 'Bánh chuối nướng thơm dịu, dùng ngon khi ấm.',
      images: [
        'https://images.unsplash.com/photo-1607920591413-4ec007e70023?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1612203985729-70726954388c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1599785209796-786432b228bc?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 6,
      title: 'Set mini party',
      price: '149.000đ',
      priceValue: 149000,
      category: 'Combo',
      description: 'Set tiệc mini nhiều vị, phù hợp nhóm 4-6 người.',
      images: [
        'https://images.unsplash.com/photo-1535141192574-5d4897c12636?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1461009683693-342af2f2d6ce?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 7,
      title: 'Bánh kem dâu lưới',
      price: '289.000đ',
      priceValue: 289000,
      category: 'Bánh kem',
      description: 'Bánh kem tươi trang trí lưới kem và dâu tươi.',
      images: [
        'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1535141192574-5d4897c12636?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 8,
      title: 'Bánh pía sầu riêng mini',
      price: '95.000đ',
      priceValue: 95000,
      category: 'Bánh pía',
      description: 'Bánh pía mini nhân sầu riêng và đậu xanh.',
      images: [
        'https://images.unsplash.com/photo-1519676867240-f03562e64548?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1519915028121-7d3463d20b13?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
    MenuProduct(
      id: 9,
      title: 'Bánh trung thu thập cẩm đặc biệt',
      price: '68.000đ',
      priceValue: 68000,
      category: 'Bánh trung thu',
      description: 'Bánh trung thu có tùy chọn gram, số trứng và hộp quà.',
      mooncakeConfig: MooncakeProductConfig(
        weightOptions: [
          MooncakeWeightOption(
            code: '150g',
            label: '150g',
            eggOptions: [
              MooncakeEggOption(
                count: 0,
                label: '0 trứng',
                priceValue: 68000,
                price: '68.000đ',
              ),
              MooncakeEggOption(
                count: 1,
                label: '1 trứng',
                priceValue: 76000,
                price: '76.000đ',
              ),
            ],
          ),
          MooncakeWeightOption(
            code: '200g',
            label: '200g',
            eggOptions: [
              MooncakeEggOption(
                count: 0,
                label: '0 trứng',
                priceValue: 86000,
                price: '86.000đ',
              ),
              MooncakeEggOption(
                count: 1,
                label: '1 trứng',
                priceValue: 94000,
                price: '94.000đ',
              ),
              MooncakeEggOption(
                count: 2,
                label: '2 trứng',
                priceValue: 102000,
                price: '102.000đ',
              ),
            ],
          ),
          MooncakeWeightOption(
            code: '250g',
            label: '250g',
            eggOptions: [
              MooncakeEggOption(
                count: 0,
                label: '0 trứng',
                priceValue: 98000,
                price: '98.000đ',
              ),
              MooncakeEggOption(
                count: 1,
                label: '1 trứng',
                priceValue: 106000,
                price: '106.000đ',
              ),
              MooncakeEggOption(
                count: 2,
                label: '2 trứng',
                priceValue: 114000,
                price: '114.000đ',
              ),
            ],
          ),
        ],
        boxOptions: [
          MooncakeBoxOption(
            code: 'box-2',
            label: 'Hộp 2 bánh',
            cakeCount: 2,
            imageUrl: 'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&w=1200&q=80',
            packagePriceValue: 30000,
            packagePrice: '30.000đ',
          ),
          MooncakeBoxOption(
            code: 'box-4',
            label: 'Hộp 4 bánh',
            cakeCount: 4,
            imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',
            packagePriceValue: 50000,
            packagePrice: '50.000đ',
          ),
          MooncakeBoxOption(
            code: 'box-6',
            label: 'Hộp 6 bánh',
            cakeCount: 6,
            imageUrl: 'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?auto=format&fit=crop&w=1200&q=80',
            packagePriceValue: 75000,
            packagePrice: '75.000đ',
          ),
        ],
      ),
      images: [
        'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1519671482749-fd09be7ccebf?auto=format&fit=crop&w=1200&q=80',
        'https://images.unsplash.com/photo-1549465220-1a8b9238cd48?auto=format&fit=crop&w=1200&q=80',
      ],
    ),
  ],
  combo: MenuComboSection(
    title: 'Combo nổi bật',
    description: 'Combo 4 bánh bất kỳ + 2 cookie, giảm 12% khi đặt online.',
    actionLabel: 'Đặt combo',
  ),
  faqs: [
    MenuFaqItem(
      question: 'Có nhận đặt bánh theo mẫu không?',
      answer: 'Có, trước 24-48 giờ.',
    ),
    MenuFaqItem(
      question: 'Có giao theo khung giờ không?',
      answer: 'Có, chọn giờ khi đặt đơn.',
    ),
  ],
  footer: MenuFooterSection(
    tagline: 'PIXEL BAKERY  |  MENU',
  ),
);

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
