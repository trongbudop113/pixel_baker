import '../../app/models/menu_models.dart';
import '../../app/repositories/menu_repository.dart';
import '../../app/state/screen_controller.dart';
import '../../app/services/wishlist_session.dart';
import '../../app/models/cart_models.dart';

class MooncakeBoxDraftItem {
  const MooncakeBoxDraftItem({
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.weightCode,
    required this.weightLabel,
    required this.eggCount,
    required this.eggLabel,
    required this.priceValue,
    required this.price,
  });

  final int productId;
  final String title;
  final String imageUrl;
  final String weightCode;
  final String weightLabel;
  final int eggCount;
  final String eggLabel;
  final int priceValue;
  final String price;

  String get variantLabel => '$weightLabel • $eggLabel';

  CartBoxItem toCartBoxItem() {
    return CartBoxItem(
      productId: productId,
      title: title,
      variantLabel: variantLabel,
      price: price,
      priceValue: priceValue,
      imageUrl: imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MooncakeBoxDraftItem &&
        other.productId == productId &&
        other.title == title &&
        other.imageUrl == imageUrl &&
        other.weightCode == weightCode &&
        other.weightLabel == weightLabel &&
        other.eggCount == eggCount &&
        other.eggLabel == eggLabel &&
        other.priceValue == priceValue &&
        other.price == price;
  }

  @override
  int get hashCode => Object.hash(
        productId,
        title,
        imageUrl,
        weightCode,
        weightLabel,
        eggCount,
        eggLabel,
        priceValue,
        price,
      );
}

class MenuViewState {
  const MenuViewState({
    this.pageResponse = defaultMenuPageResponse,
    this.selectedFilterIndex = 0,
    this.focusedCategory,
    this.searchQuery = '',
    this.sortKey = 'featured',
    this.priceRangeKey = 'all',
    this.minimumRating = 0,
    this.favoritesOnly = false,
    this.isLoading = false,
    this.errorMessage,
    this.activeMooncakeBoxCode,
    this.mooncakeBoxItems = const [],
  });

  final MenuPageResponse pageResponse;
  final int selectedFilterIndex;
  final String? focusedCategory;
  final String searchQuery;
  final String sortKey;
  final String priceRangeKey;
  final double minimumRating;
  final bool favoritesOnly;
  final bool isLoading;
  final String? errorMessage;
  final String? activeMooncakeBoxCode;
  final List<MooncakeBoxDraftItem> mooncakeBoxItems;

  MenuViewState copyWith({
    MenuPageResponse? pageResponse,
    int? selectedFilterIndex,
    String? focusedCategory,
    String? searchQuery,
    String? sortKey,
    String? priceRangeKey,
    double? minimumRating,
    bool? favoritesOnly,
    bool? isLoading,
    String? errorMessage,
    String? activeMooncakeBoxCode,
    List<MooncakeBoxDraftItem>? mooncakeBoxItems,
    bool clearFocusedCategory = false,
    bool clearErrorMessage = false,
    bool clearMooncakeBox = false,
  }) {
    return MenuViewState(
      pageResponse: pageResponse ?? this.pageResponse,
      selectedFilterIndex: selectedFilterIndex ?? this.selectedFilterIndex,
      focusedCategory:
          clearFocusedCategory ? null : focusedCategory ?? this.focusedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      sortKey: sortKey ?? this.sortKey,
      priceRangeKey: priceRangeKey ?? this.priceRangeKey,
      minimumRating: minimumRating ?? this.minimumRating,
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      activeMooncakeBoxCode:
          clearMooncakeBox ? null : activeMooncakeBoxCode ?? this.activeMooncakeBoxCode,
      mooncakeBoxItems: clearMooncakeBox
          ? const []
          : mooncakeBoxItems ?? this.mooncakeBoxItems,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MenuViewState &&
        other.pageResponse == pageResponse &&
        other.selectedFilterIndex == selectedFilterIndex &&
        other.focusedCategory == focusedCategory &&
        other.searchQuery == searchQuery &&
        other.sortKey == sortKey &&
        other.priceRangeKey == priceRangeKey &&
        other.minimumRating == minimumRating &&
        other.favoritesOnly == favoritesOnly &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.activeMooncakeBoxCode == activeMooncakeBoxCode &&
        _listEquals(other.mooncakeBoxItems, mooncakeBoxItems);
  }

  @override
  int get hashCode => Object.hash(
        pageResponse,
        selectedFilterIndex,
        focusedCategory,
        searchQuery,
        sortKey,
        priceRangeKey,
        minimumRating,
        favoritesOnly,
        isLoading,
        errorMessage,
        activeMooncakeBoxCode,
        Object.hashAll(mooncakeBoxItems),
      );
}

class MenuState extends ScreenController<MenuViewState, Never> {
  MenuState({
    required MenuRepository repository,
    required WishlistSession wishlistSession,
  })  : _repository = repository,
        _wishlistSession = wishlistSession,
        super(const MenuViewState());

  final MenuRepository _repository;
  final WishlistSession _wishlistSession;

  // Memoize filteredProducts — recompute only when state changes
  List<MenuProduct>? _filteredCache;
  MenuViewState? _filteredCacheKey;

  int get selectedFilterIndex => state.selectedFilterIndex;
  String? get focusedCategory => state.focusedCategory;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  String get searchQuery => state.searchQuery;
  String get sortKey => state.sortKey;
  String get priceRangeKey => state.priceRangeKey;
  double get minimumRating => state.minimumRating;
  bool get favoritesOnly => state.favoritesOnly;
  MenuPageResponse get pageResponse => state.pageResponse;
  List<MenuProduct> get products => pageResponse.products;
  List<MenuFilterOption> get filters => pageResponse.filters;
  bool get isMooncakeTabSelected =>
      _mapCategory(_selectedCategoryValue()) == 'mooncake' ||
      _mapCategory(focusedCategory) == 'mooncake';
  String? get activeMooncakeBoxCode => state.activeMooncakeBoxCode;
  List<MooncakeBoxDraftItem> get mooncakeBoxItems => state.mooncakeBoxItems;
  bool get isMooncakeBoxMode => activeMooncakeBoxCode != null;

  MooncakeProductConfig? get mooncakeConfig {
    for (final product in products) {
      if (product.mooncakeConfig != null) {
        return product.mooncakeConfig;
      }
    }
    return null;
  }

  MooncakeBoxOption? get activeMooncakeBoxOption {
    final code = activeMooncakeBoxCode;
    final config = mooncakeConfig;
    if (code == null || config == null) {
      return null;
    }
    for (final box in config.boxOptions) {
      if (box.code == code) {
        return box;
      }
    }
    return null;
  }

  int get mooncakeBoxCapacity => activeMooncakeBoxOption?.cakeCount ?? 0;
  int get remainingMooncakeBoxSlots =>
      (mooncakeBoxCapacity - mooncakeBoxItems.length).clamp(0, mooncakeBoxCapacity);
  bool get canSubmitMooncakeBox =>
      isMooncakeBoxMode && mooncakeBoxItems.length == mooncakeBoxCapacity;
  int get mooncakeBoxSubtotal {
    final packagePrice = activeMooncakeBoxOption?.packagePriceValue ?? 0;
    final itemsTotal = mooncakeBoxItems.fold<int>(
      0,
      (sum, item) => sum + item.priceValue,
    );
    return packagePrice + itemsTotal;
  }

  List<MenuProduct> get filteredProducts {
    if (_filteredCache != null && _filteredCacheKey == state) {
      return _filteredCache!;
    }
    _filteredCacheKey = state;
    _filteredCache = _computeFilteredProducts();
    return _filteredCache!;
  }

  List<MenuProduct> _computeFilteredProducts() {
    final selectedCategory = _selectedCategoryValue();
    List<MenuProduct> list;
    if (selectedCategory == null || selectedCategory == 'all') {
      list = List<MenuProduct>.from(products);
    } else {
      list = products.where((e) => _mapCategory(e.category) == _mapCategory(selectedCategory)).toList();
    }

    if (focusedCategory != null && focusedCategory!.isNotEmpty) {
      final focus = _mapCategory(focusedCategory!);
      final matched = <MenuProduct>[];
      final others = <MenuProduct>[];
      for (final item in list) {
        if (_mapCategory(item.category) == focus) {
          matched.add(item);
        } else {
          others.add(item);
        }
      }
      list = [...matched, ...others];
    }

    final keyword = searchQuery.trim().toLowerCase();
    if (keyword.isNotEmpty) {
      final searchTerms = keyword
          .split(RegExp(r'\s+'))
          .where((item) => item.trim().isNotEmpty)
          .toList(growable: false);
      list = list.where((item) {
        final haystack =
            '${item.title} ${item.category} ${item.description}'.toLowerCase();
        return searchTerms.every(haystack.contains);
      }).toList(growable: false);
    }

    if (minimumRating > 0) {
      list = list
          .where((item) => item.averageRating >= minimumRating)
          .toList(growable: false);
    }

    switch (priceRangeKey) {
      case 'under_100k':
        list = list
            .where((item) => item.priceValue > 0 && item.priceValue < 100000)
            .toList(growable: false);
        break;
      case '100k_200k':
        list = list
            .where((item) => item.priceValue >= 100000 && item.priceValue <= 200000)
            .toList(growable: false);
        break;
      case 'over_200k':
        list = list
            .where((item) => item.priceValue > 200000)
            .toList(growable: false);
        break;
    }

    if (favoritesOnly) {
      list = list
          .where((item) => _wishlistSession.contains(item.id))
          .toList(growable: false);
    }

    final sorted = [...list];
    switch (sortKey) {
      case 'price_asc':
        sorted.sort((a, b) => a.priceValue.compareTo(b.priceValue));
        break;
      case 'price_desc':
        sorted.sort((a, b) => b.priceValue.compareTo(a.priceValue));
        break;
      case 'rating_desc':
        sorted.sort((a, b) {
          final ratingCompare = b.averageRating.compareTo(a.averageRating);
          if (ratingCompare != 0) return ratingCompare;
          return b.reviewCount.compareTo(a.reviewCount);
        });
        break;
      default:
        sorted.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
        break;
    }
    return sorted;
  }

  String? _selectedCategoryValue() {
    if (filters.isEmpty) {
      return null;
    }
    final index = selectedFilterIndex.clamp(0, filters.length - 1);
    return filters[index].category;
  }

  void selectFilter(int index) {
    if (index < 0 || index >= filters.length) {
      return;
    }
    final isMooncake = _mapCategory(filters[index].category) == 'mooncake';
    update(
      (current) => current.copyWith(
        selectedFilterIndex: index,
        clearMooncakeBox: !isMooncake,
      ),
    );
  }

  void setSearchQuery(String value) {
    update((current) => current.copyWith(searchQuery: value));
  }

  void setSortKey(String value) {
    update((current) => current.copyWith(sortKey: value));
  }

  void setPriceRangeKey(String value) {
    update((current) => current.copyWith(priceRangeKey: value));
  }

  void setMinimumRating(double value) {
    update((current) => current.copyWith(minimumRating: value));
  }

  void toggleFavoritesOnly() {
    update((current) => current.copyWith(favoritesOnly: !current.favoritesOnly));
  }

  void setFavoritesOnly(bool value) {
    update((current) => current.copyWith(favoritesOnly: value));
  }

  void clearSearchFilters() {
    update(
      (current) => current.copyWith(
        searchQuery: '',
        sortKey: 'featured',
        priceRangeKey: 'all',
        minimumRating: 0,
        favoritesOnly: false,
      ),
    );
  }

  Future<void> loadMenuPage() async {
    if (state.isLoading) {
      return;
    }

    update(
      (current) => current.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );

    try {
      final pageResponse = await _repository.fetchMenuPage();
      update(
        (current) => current.copyWith(
          pageResponse: pageResponse,
          selectedFilterIndex: _safeFilterIndex(
            current.selectedFilterIndex,
            pageResponse.filters.length,
          ),
          isLoading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      update(
        (current) => current.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> forceRefresh() async {
    if (state.isLoading) return;
    update((current) => current.copyWith(isLoading: true, clearErrorMessage: true));
    try {
      final pageResponse = await _repository.forceRefreshMenuPage();
      update(
        (current) => current.copyWith(
          pageResponse: pageResponse,
          selectedFilterIndex: _safeFilterIndex(
            current.selectedFilterIndex,
            pageResponse.filters.length,
          ),
          isLoading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (error) {
      update((current) => current.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  int _safeFilterIndex(int currentIndex, int filterCount) {
    if (filterCount <= 0) {
      return 0;
    }
    if (currentIndex < 0) {
      return 0;
    }
    if (currentIndex >= filterCount) {
      return filterCount - 1;
    }
    return currentIndex;
  }

  void applyCategoryFocus(String? rawCategory) {
    final normalized = rawCategory?.trim();
    final nextCategory =
        normalized == null || normalized.isEmpty ? null : normalized;

    final mapped = _mapCategory(nextCategory);
    var nextFilterIndex = 0;
    for (var i = 0; i < filters.length; i++) {
      if (_mapCategory(filters[i].category) == mapped) {
        nextFilterIndex = i;
        break;
      }
    }

    update((current) {
      return current.copyWith(
        selectedFilterIndex: nextFilterIndex,
        focusedCategory: nextCategory,
        clearFocusedCategory: nextCategory == null,
        clearMooncakeBox: mapped != 'mooncake',
      );
    });
  }

  void startMooncakeBoxPurchase(String boxCode) {
    update(
      (current) => current.copyWith(
        activeMooncakeBoxCode: boxCode,
        mooncakeBoxItems: const [],
      ),
    );
  }

  void clearMooncakeBoxPurchase() {
    update((current) => current.copyWith(clearMooncakeBox: true));
  }

  void removeMooncakeBoxItemAt(int index) {
    if (index < 0 || index >= mooncakeBoxItems.length) {
      return;
    }
    final nextItems = [...mooncakeBoxItems]..removeAt(index);
    update((current) => current.copyWith(mooncakeBoxItems: nextItems));
  }

  bool addMooncakeItemToBox(
    MenuProduct product, {
    required MooncakeWeightOption weight,
    required MooncakeEggOption egg,
  }) {
    if (!isMooncakeBoxMode || remainingMooncakeBoxSlots <= 0) {
      return false;
    }
    final nextItems = [
      ...mooncakeBoxItems,
      MooncakeBoxDraftItem(
        productId: product.id,
        title: product.title,
        imageUrl: product.images.isEmpty ? '' : product.images.first,
        weightCode: weight.code,
        weightLabel: weight.label,
        eggCount: egg.count,
        eggLabel: egg.label,
        priceValue: egg.priceValue,
        price: egg.price,
      ),
    ];
    update((current) => current.copyWith(mooncakeBoxItems: nextItems));
    return true;
  }

  CartItem? buildMooncakeBoxCartItem() {
    final box = activeMooncakeBoxOption;
    if (box == null || mooncakeBoxItems.length != box.cakeCount) {
      return null;
    }
    final variantLabel = mooncakeBoxItems
        .asMap()
        .entries
        .map((entry) => 'Bánh ${entry.key + 1}: ${entry.value.title} (${entry.value.variantLabel})')
        .join('\n');
    final imageUrl = box.imageUrl.isNotEmpty
        ? box.imageUrl
        : (mooncakeBoxItems.isEmpty ? '' : mooncakeBoxItems.first.imageUrl);
    return CartItem(
      productId: mooncakeBoxItems.first.productId,
      title: box.label,
      price: _formatCurrency(mooncakeBoxSubtotal),
      priceValue: mooncakeBoxSubtotal,
      category: 'Bánh trung thu',
      imageUrl: imageUrl,
      quantity: 1,
      variantKey:
          'mooncake-box:${box.code}:${mooncakeBoxItems.map((item) => '${item.productId}-${item.weightCode}-${item.eggCount}').join('|')}',
      variantLabel: variantLabel,
      boxItems: mooncakeBoxItems.map((item) => item.toCartBoxItem()).toList(growable: false),
    );
  }

  void updateProductSnapshot(MenuProduct product) {
    final nextProducts = [
      for (final item in products)
        if (item.id == product.id) product else item,
    ];
    update((current) => current.copyWith(
          pageResponse: MenuPageResponse(
            intro: current.pageResponse.intro,
            filters: current.pageResponse.filters,
            productsSectionTitle: current.pageResponse.productsSectionTitle,
            products: nextProducts,
            combo: current.pageResponse.combo,
            faqs: current.pageResponse.faqs,
            footer: current.pageResponse.footer,
          ),
        ));
  }

  String _mapCategory(String? value) {
    final v = (value ?? '').toLowerCase();
    if (v.isEmpty || v == 'all') return 'all';
    if (v.contains('cupcake')) return 'cupcake';
    if (v.contains('cookie')) return 'cookie';
    if (v.contains('tart')) return 'tart';
    if (v.contains('combo')) return 'combo';
    if (v.contains('mooncake') || v.contains('trung thu')) return 'mooncake';
    if (v.contains('pia') || v.contains('pía')) return 'pia';
    if (v.contains('kem')) return 'cake';
    if (v.contains('cake') ||
        v.contains('sinhnhat') ||
        v.contains('sinh_nhat') ||
        v.contains('birthday')) {
      return 'cake';
    }
    return v;
  }

  String _formatCurrency(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reversedIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
