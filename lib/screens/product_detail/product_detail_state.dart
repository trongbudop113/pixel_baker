import '../../app/models/cart_models.dart';
import '../../app/repositories/menu_repository.dart';
import '../../app/models/menu_models.dart';
import '../../app/state/screen_controller.dart';

class MooncakeBoxSelection {
  const MooncakeBoxSelection({
    required this.weightCode,
    required this.eggCount,
  });

  final String weightCode;
  final int eggCount;

  MooncakeBoxSelection copyWith({
    String? weightCode,
    int? eggCount,
  }) {
    return MooncakeBoxSelection(
      weightCode: weightCode ?? this.weightCode,
      eggCount: eggCount ?? this.eggCount,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MooncakeBoxSelection &&
        other.weightCode == weightCode &&
        other.eggCount == eggCount;
  }

  @override
  int get hashCode => Object.hash(weightCode, eggCount);
}

class ProductDetailViewState {
  const ProductDetailViewState({
    this.product,
    this.qty = 1,
    this.selectedImage = 0,
    this.isLoading = true,
    this.isSubmittingReview = false,
    this.errorMessage,
    this.selectedWeightCode,
    this.selectedEggCount,
    this.selectedBoxCode,
    this.boxSelections = const [],
  });

  final MenuProductDetail? product;
  final int qty;
  final int selectedImage;
  final bool isLoading;
  final bool isSubmittingReview;
  final String? errorMessage;
  final String? selectedWeightCode;
  final int? selectedEggCount;
  final String? selectedBoxCode;
  final List<MooncakeBoxSelection> boxSelections;

  ProductDetailViewState copyWith({
    MenuProductDetail? product,
    int? qty,
    int? selectedImage,
    bool? isLoading,
    bool? isSubmittingReview,
    String? errorMessage,
    String? selectedWeightCode,
    int? selectedEggCount,
    String? selectedBoxCode,
    List<MooncakeBoxSelection>? boxSelections,
    bool clearErrorMessage = false,
  }) {
    return ProductDetailViewState(
      product: product ?? this.product,
      qty: qty ?? this.qty,
      selectedImage: selectedImage ?? this.selectedImage,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingReview: isSubmittingReview ?? this.isSubmittingReview,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      selectedWeightCode: selectedWeightCode ?? this.selectedWeightCode,
      selectedEggCount: selectedEggCount ?? this.selectedEggCount,
      selectedBoxCode: selectedBoxCode ?? this.selectedBoxCode,
      boxSelections: boxSelections ?? this.boxSelections,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProductDetailViewState &&
        other.product == product &&
        other.qty == qty &&
        other.selectedImage == selectedImage &&
        other.isLoading == isLoading &&
        other.isSubmittingReview == isSubmittingReview &&
        other.errorMessage == errorMessage &&
        other.selectedWeightCode == selectedWeightCode &&
        other.selectedEggCount == selectedEggCount &&
        other.selectedBoxCode == selectedBoxCode &&
        _listEquals(other.boxSelections, boxSelections);
  }

  @override
  int get hashCode =>
      Object.hash(
        product,
        qty,
        selectedImage,
        isLoading,
        isSubmittingReview,
        errorMessage,
        selectedWeightCode,
        selectedEggCount,
        selectedBoxCode,
        Object.hashAll(boxSelections),
      );
}

class ProductDetailState
    extends ScreenController<ProductDetailViewState, Never> {
  ProductDetailState({
    required MenuRepository repository,
    required int productId,
    int initialQty = 1,
  })  : _repository = repository,
        _productId = productId,
        super(
          ProductDetailViewState(
            qty: initialQty < 1 ? 1 : initialQty,
          ),
        );

  final MenuRepository _repository;
  final int _productId;

  int get qty => state.qty;
  int get selectedImage => state.selectedImage;
  bool get isLoading => state.isLoading;
  bool get isSubmittingReview => state.isSubmittingReview;
  String? get errorMessage => state.errorMessage;
  MenuProductDetail? get product => state.product;
  List<MenuProduct> get relatedProducts => product?.relatedProducts ?? const [];
  List<String> get images => product?.images ?? const [];
  bool get isMooncake => product?.mooncakeConfig != null;
  MooncakeProductConfig? get mooncakeConfig => product?.mooncakeConfig;
  String? get selectedWeightCode => state.selectedWeightCode;
  int? get selectedEggCount => state.selectedEggCount;
  String? get selectedBoxCode => state.selectedBoxCode;
  List<MooncakeBoxSelection> get boxSelections => state.boxSelections;

  MooncakeWeightOption? get selectedWeightOption {
    final config = mooncakeConfig;
    final code = selectedWeightCode;
    if (config == null || code == null) {
      return null;
    }
    for (final item in config.weightOptions) {
      if (item.code == code) {
        return item;
      }
    }
    return config.weightOptions.isEmpty ? null : config.weightOptions.first;
  }

  List<MooncakeEggOption> get availableEggOptions =>
      selectedWeightOption?.eggOptions ?? const [];

  MooncakeEggOption? get selectedEggOption {
    final count = selectedEggCount;
    if (count == null) {
      return availableEggOptions.isEmpty ? null : availableEggOptions.first;
    }
    for (final item in availableEggOptions) {
      if (item.count == count) {
        return item;
      }
    }
    return availableEggOptions.isEmpty ? null : availableEggOptions.first;
  }

  MooncakeBoxOption? get selectedBoxOption {
    final config = mooncakeConfig;
    final code = selectedBoxCode;
    if (config == null || code == null) {
      return null;
    }
    for (final item in config.boxOptions) {
      if (item.code == code) {
        return item;
      }
    }
    return null;
  }

  int get total => isMooncake
      ? (selectedEggOption?.priceValue ?? product?.priceValue ?? 0) * qty
      : (product?.priceValue ?? 0) * qty;

  String get displayPrice =>
      isMooncake ? (selectedEggOption?.price ?? product?.price ?? '') : (product?.price ?? '');

  int get selectedBoxTotal {
    final box = selectedBoxOption;
    if (box == null) {
      return 0;
    }
    var totalPrice = box.packagePriceValue;
    for (final selection in boxSelections) {
      totalPrice += _resolveEggOption(
                selection.weightCode,
                selection.eggCount,
              )
              ?.priceValue ??
          0;
    }
    return totalPrice;
  }

  Future<void> load() async {
    update(
      (current) => current.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );
    try {
      final product = await _repository.fetchProductDetailById(_productId);
      update(
        (current) => current.copyWith(
          product: product,
          isLoading: false,
          selectedImage: 0,
          selectedWeightCode: _defaultWeightCode(product),
          selectedEggCount: _defaultEggCount(product, _defaultWeightCode(product)),
          selectedBoxCode: null,
          boxSelections: const [],
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

  void increaseQty() {
    update((current) => current.copyWith(qty: current.qty + 1));
  }

  void decreaseQty() {
    if (qty <= 1) return;
    update((current) => current.copyWith(qty: current.qty - 1));
  }

  void selectImage(int index) {
    if (index < 0 || index >= images.length || index == selectedImage) return;
    update((current) => current.copyWith(selectedImage: index));
  }

  void selectWeight(String code) {
    final product = state.product;
    if (product == null) {
      return;
    }
    final nextEggCount = _defaultEggCount(product, code);
    update(
      (current) => current.copyWith(
        selectedWeightCode: code,
        selectedEggCount: nextEggCount,
      ),
    );
  }

  void selectEggCount(int count) {
    update((current) => current.copyWith(selectedEggCount: count));
  }

  void prepareBoxSelection(String boxCode) {
    final config = mooncakeConfig;
    if (config == null) {
      return;
    }
    final box = config.boxOptions.where((item) => item.code == boxCode).firstOrNull;
    final defaultWeight = selectedWeightCode ?? _defaultWeightCode(product);
    final defaultEgg = _defaultEggCount(product, defaultWeight);
    if (box == null || defaultWeight == null || defaultEgg == null) {
      return;
    }
    update(
      (current) => current.copyWith(
        selectedBoxCode: boxCode,
        boxSelections: List<MooncakeBoxSelection>.generate(
          box.cakeCount,
          (_) => MooncakeBoxSelection(
            weightCode: defaultWeight,
            eggCount: defaultEgg,
          ),
          growable: false,
        ),
      ),
    );
  }

  void clearBoxSelection() {
    update(
      (current) => current.copyWith(
        selectedBoxCode: null,
        boxSelections: const [],
      ),
    );
  }

  void updateBoxSelection(
    int index, {
    String? weightCode,
    int? eggCount,
  }) {
    if (index < 0 || index >= boxSelections.length) {
      return;
    }
    final current = boxSelections[index];
    final nextWeightCode = weightCode ?? current.weightCode;
    final nextEggCount = eggCount ??
        _resolveEggOption(nextWeightCode, current.eggCount)?.count ??
        _weightOptionByCode(nextWeightCode)?.eggOptions.firstOrNull?.count ??
        current.eggCount;
    final updated = current.copyWith(
      weightCode: nextWeightCode,
      eggCount: nextEggCount,
    );
    final nextSelections = [...boxSelections];
    nextSelections[index] = updated;
    update((state) => state.copyWith(boxSelections: nextSelections));
  }

  CartItem? buildSingleCartItem() {
    final currentProduct = product;
    final weight = selectedWeightOption;
    final egg = selectedEggOption;
    if (currentProduct == null) {
      return null;
    }
    if (!isMooncake || weight == null || egg == null) {
      return CartItem.fromMenuProduct(currentProduct, quantity: qty);
    }
    return CartItem(
      productId: currentProduct.id,
      title: currentProduct.title,
      price: egg.price,
      priceValue: egg.priceValue,
      category: currentProduct.category,
      imageUrl: currentProduct.images.isEmpty ? '' : currentProduct.images.first,
      quantity: qty,
      variantKey: 'single:${weight.code}:${egg.count}',
      variantLabel: '${weight.label} • ${egg.label}',
    );
  }

  CartItem? buildBoxCartItem() {
    final currentProduct = product;
    final box = selectedBoxOption;
    if (currentProduct == null || box == null || boxSelections.length != box.cakeCount) {
      return null;
    }
    final summary = <String>[];
    for (final selection in boxSelections) {
      final weight = _weightOptionByCode(selection.weightCode);
      final egg = _resolveEggOption(selection.weightCode, selection.eggCount);
      if (weight == null || egg == null) {
        return null;
      }
      summary.add('${weight.label} ${egg.label}');
    }
    return CartItem(
      productId: currentProduct.id,
      title: '${currentProduct.title} - ${box.label}',
      price: _formatCurrency(selectedBoxTotal),
      priceValue: selectedBoxTotal,
      category: currentProduct.category,
      imageUrl: box.imageUrl.isNotEmpty
          ? box.imageUrl
          : (currentProduct.images.isEmpty ? '' : currentProduct.images.first),
      quantity: 1,
      variantKey: 'box:${box.code}:${summary.join("|")}',
      variantLabel: summary.join(' • '),
      boxItems: [
        for (final selection in boxSelections)
          (() {
            final weight = _weightOptionByCode(selection.weightCode)!;
            final egg = _resolveEggOption(selection.weightCode, selection.eggCount)!;
            return CartBoxItem(
              productId: currentProduct.id,
              title: currentProduct.title,
              variantLabel: '${weight.label} • ${egg.label}',
              price: egg.price,
              priceValue: egg.priceValue,
              imageUrl: currentProduct.images.isEmpty ? '' : currentProduct.images.first,
            );
          })(),
      ],
    );
  }

  Future<bool> deleteReview(String createdAt) async {
    update(
      (current) => current.copyWith(
        isLoading: true,
        clearErrorMessage: true,
      ),
    );
    try {
      final detail = await _repository.deleteReview(_productId, createdAt);
      update(
        (current) => current.copyWith(
          product: detail,
          isLoading: false,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (error) {
      update(
        (current) => current.copyWith(
          isLoading: false,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<bool> submitReview(MenuReviewDraft draft) async {
    update(
      (current) => current.copyWith(
        isSubmittingReview: true,
        clearErrorMessage: true,
      ),
    );
    try {
      final detail = await _repository.submitReview(_productId, draft);
      update(
        (current) => current.copyWith(
          product: detail,
          isSubmittingReview: false,
          clearErrorMessage: true,
        ),
      );
      return true;
    } catch (error) {
      update(
        (current) => current.copyWith(
          isSubmittingReview: false,
          errorMessage: error.toString(),
        ),
      );
      return false;
    }
  }

  String formatCurrency(int value) => _formatCurrency(value);

  String? _defaultWeightCode(MenuProductDetail? product) {
    final options = product?.mooncakeConfig?.weightOptions;
    if (options == null || options.isEmpty) {
      return null;
    }
    return options.first.code;
  }

  int? _defaultEggCount(MenuProductDetail? product, String? weightCode) {
    if (product == null || weightCode == null) {
      return null;
    }
    return _weightOptionByCode(weightCode)?.eggOptions.firstOrNull?.count;
  }

  MooncakeWeightOption? _weightOptionByCode(String? code) {
    final config = mooncakeConfig;
    if (config == null || code == null) {
      return null;
    }
    for (final option in config.weightOptions) {
      if (option.code == code) {
        return option;
      }
    }
    return null;
  }

  MooncakeEggOption? _resolveEggOption(String? weightCode, int? eggCount) {
    final option = _weightOptionByCode(weightCode);
    if (option == null) {
      return null;
    }
    for (final egg in option.eggOptions) {
      if (egg.count == eggCount) {
        return egg;
      }
    }
    return option.eggOptions.firstOrNull;
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

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
