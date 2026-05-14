import '../../app/models/admin_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/admin_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

class AdminSidebarItem {
  const AdminSidebarItem({
    required this.index,
    required this.label,
  });

  final int index;
  final String label;
}

class AdminViewState {
  const AdminViewState({
    this.selectedSidebarIndex = 0,
    this.dashboard = defaultAdminDashboard,
    this.orders = const [],
    this.products = const [],
    this.customers = const [],
    this.importAuditLogs = const [],
    this.vouchers = const [],
    this.testimonials = const [],
    this.contents = const [],
    this.ingredients = const [],
    this.inventoryTransactions = const [],
    this.recipes = const [],
    this.productCostReports = const [],
    this.reviews = const [],
    this.revenueSummary = defaultRevenueSummary,
    this.revenueRange = '7d',
    this.bestSellers = const [],
    this.customerSegments = const [],
    this.revenueForecast = defaultRevenueForecast,
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.orderSearch = '',
    this.productSearch = '',
    this.customerSearch = '',
    this.ingredientSearch = '',
    this.orderSort = 'latest',
    this.productSort = 'name',
    this.customerSort = 'name',
    this.ingredientSort = 'name',
  });

  final int selectedSidebarIndex;
  final AdminDashboardModel dashboard;
  final List<AdminOrderModel> orders;
  final List<AdminProductModel> products;
  final List<AdminCustomerModel> customers;
  final List<AdminImportAuditLogModel> importAuditLogs;
  final List<AdminVoucherModel> vouchers;
  final List<AdminTestimonialModel> testimonials;
  final List<AdminContentDocumentModel> contents;
  final List<AdminIngredientModel> ingredients;
  final List<AdminInventoryTransactionModel> inventoryTransactions;
  final List<AdminRecipeModel> recipes;
  final List<AdminProductCostReportModel> productCostReports;
  final List<AdminProductReviewModel> reviews;
  final AdminRevenueSummaryModel revenueSummary;
  final String revenueRange;
  final List<AdminBestSellerModel> bestSellers;
  final List<AdminCustomerSegmentModel> customerSegments;
  final AdminRevenueForecastModel revenueForecast;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final String orderSearch;
  final String productSearch;
  final String customerSearch;
  final String ingredientSearch;
  final String orderSort;
  final String productSort;
  final String customerSort;
  final String ingredientSort;

  AdminViewState copyWith({
    int? selectedSidebarIndex,
    AdminDashboardModel? dashboard,
    List<AdminOrderModel>? orders,
    List<AdminProductModel>? products,
    List<AdminCustomerModel>? customers,
    List<AdminImportAuditLogModel>? importAuditLogs,
    List<AdminVoucherModel>? vouchers,
    List<AdminTestimonialModel>? testimonials,
    List<AdminContentDocumentModel>? contents,
    List<AdminIngredientModel>? ingredients,
    List<AdminInventoryTransactionModel>? inventoryTransactions,
    List<AdminRecipeModel>? recipes,
    List<AdminProductCostReportModel>? productCostReports,
    List<AdminProductReviewModel>? reviews,
    AdminRevenueSummaryModel? revenueSummary,
    String? revenueRange,
    List<AdminBestSellerModel>? bestSellers,
    List<AdminCustomerSegmentModel>? customerSegments,
    AdminRevenueForecastModel? revenueForecast,
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    String? orderSearch,
    String? productSearch,
    String? customerSearch,
    String? ingredientSearch,
    String? orderSort,
    String? productSort,
    String? customerSort,
    String? ingredientSort,
    bool clearErrorMessage = false,
  }) {
    return AdminViewState(
      selectedSidebarIndex: selectedSidebarIndex ?? this.selectedSidebarIndex,
      dashboard: dashboard ?? this.dashboard,
      orders: orders ?? this.orders,
      products: products ?? this.products,
      customers: customers ?? this.customers,
      importAuditLogs: importAuditLogs ?? this.importAuditLogs,
      vouchers: vouchers ?? this.vouchers,
      testimonials: testimonials ?? this.testimonials,
      contents: contents ?? this.contents,
      ingredients: ingredients ?? this.ingredients,
      inventoryTransactions:
          inventoryTransactions ?? this.inventoryTransactions,
      recipes: recipes ?? this.recipes,
      productCostReports: productCostReports ?? this.productCostReports,
      reviews: reviews ?? this.reviews,
      revenueSummary: revenueSummary ?? this.revenueSummary,
      revenueRange: revenueRange ?? this.revenueRange,
      bestSellers: bestSellers ?? this.bestSellers,
      customerSegments: customerSegments ?? this.customerSegments,
      revenueForecast: revenueForecast ?? this.revenueForecast,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      orderSearch: orderSearch ?? this.orderSearch,
      productSearch: productSearch ?? this.productSearch,
      customerSearch: customerSearch ?? this.customerSearch,
      ingredientSearch: ingredientSearch ?? this.ingredientSearch,
      orderSort: orderSort ?? this.orderSort,
      productSort: productSort ?? this.productSort,
      customerSort: customerSort ?? this.customerSort,
      ingredientSort: ingredientSort ?? this.ingredientSort,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AdminViewState &&
        other.selectedSidebarIndex == selectedSidebarIndex &&
        other.dashboard == dashboard &&
        _sameOrders(other.orders, orders) &&
        _sameProducts(other.products, products) &&
        _sameCustomers(other.customers, customers) &&
        _sameImportAuditLogs(other.importAuditLogs, importAuditLogs) &&
        _sameVouchers(other.vouchers, vouchers) &&
        _sameTestimonials(other.testimonials, testimonials) &&
        _sameContents(other.contents, contents) &&
        _sameIngredients(other.ingredients, ingredients) &&
        _sameInventoryTransactions(
          other.inventoryTransactions,
          inventoryTransactions,
        ) &&
        _sameRecipes(other.recipes, recipes) &&
        _sameProductCostReports(other.productCostReports, productCostReports) &&
        _sameReviews(other.reviews, reviews) &&
        other.revenueSummary == revenueSummary &&
        other.revenueRange == revenueRange &&
        other.bestSellers.length == bestSellers.length &&
        other.customerSegments.length == customerSegments.length &&
        other.revenueForecast == revenueForecast &&
        other.isLoading == isLoading &&
        other.isUpdating == isUpdating &&
        other.errorMessage == errorMessage &&
        other.orderSearch == orderSearch &&
        other.productSearch == productSearch &&
        other.customerSearch == customerSearch &&
        other.ingredientSearch == ingredientSearch &&
        other.orderSort == orderSort &&
        other.productSort == productSort &&
        other.customerSort == customerSort &&
        other.ingredientSort == ingredientSort;
  }

  @override
  int get hashCode => Object.hashAll([
        selectedSidebarIndex,
        dashboard,
        Object.hashAll(orders),
        Object.hashAll(products),
        Object.hashAll(customers),
        Object.hashAll(importAuditLogs),
        Object.hashAll(vouchers),
        Object.hashAll(testimonials),
        Object.hashAll(contents),
        Object.hashAll(ingredients),
        Object.hashAll(inventoryTransactions),
        Object.hashAll(recipes),
        Object.hashAll(productCostReports),
        Object.hashAll(reviews),
        revenueSummary,
        revenueRange,
        bestSellers.length,
        customerSegments.length,
        revenueForecast,
        isLoading,
        isUpdating,
        errorMessage,
        orderSearch,
        productSearch,
        customerSearch,
        ingredientSearch,
        orderSort,
        productSort,
        customerSort,
        ingredientSort,
      ]);
}

class AdminState extends ScreenController<AdminViewState, Never> {
  AdminState({
    AdminRepository? repository,
  })  : _repository = repository ?? AppServices.instance.adminRepository,
        super(const AdminViewState());

  final AdminRepository _repository;
  bool _hasLoaded = false;

  int get selectedSidebarIndex => state.selectedSidebarIndex;
  AdminDashboardModel get dashboard => state.dashboard;
  List<AdminOrderModel> get orders => state.orders;
  List<AdminProductModel> get products => state.products;
  List<AdminCustomerModel> get customers => state.customers;
  List<AdminImportAuditLogModel> get importAuditLogs => state.importAuditLogs;
  List<AdminVoucherModel> get vouchers => state.vouchers;
  List<AdminTestimonialModel> get testimonials => state.testimonials;
  List<AdminContentDocumentModel> get contents => state.contents;
  List<AdminIngredientModel> get ingredients => state.ingredients;
  List<AdminInventoryTransactionModel> get inventoryTransactions =>
      state.inventoryTransactions;
  List<AdminRecipeModel> get recipes => state.recipes;
  List<AdminProductCostReportModel> get productCostReports =>
      state.productCostReports;
  List<AdminProductReviewModel> get reviews => state.reviews;
  AdminRevenueSummaryModel get revenueSummary => state.revenueSummary;
  String get revenueRange => state.revenueRange;
  List<AdminBestSellerModel> get bestSellers => state.bestSellers;
  List<AdminCustomerSegmentModel> get customerSegments => state.customerSegments;
  AdminRevenueForecastModel get revenueForecast => state.revenueForecast;
  bool get isLoading => state.isLoading;
  bool get isUpdating => state.isUpdating;
  String? get errorMessage => state.errorMessage;
  String get orderSearch => state.orderSearch;
  String get productSearch => state.productSearch;
  String get customerSearch => state.customerSearch;
  String get ingredientSearch => state.ingredientSearch;
  String get orderSort => state.orderSort;
  String get productSort => state.productSort;
  String get customerSort => state.customerSort;
  String get ingredientSort => state.ingredientSort;
  bool get canAccessAdmin => _hasAnyPermission(const ['admin:access']);
  bool get canViewReports => _hasAnyPermission(const ['reports:view']);
  bool get canViewOrders =>
      _hasAnyPermission(const ['orders:view', 'orders:manage']);
  bool get canManageOrders => _hasAnyPermission(const ['orders:manage']);
  bool get canViewProducts =>
      _hasAnyPermission(const ['products:view', 'products:manage']);
  bool get canManageProducts => _hasAnyPermission(const ['products:manage']);
  bool get canViewCustomers =>
      _hasAnyPermission(const ['customers:view', 'customers:manage']);
  bool get canManageCustomers => _hasAnyPermission(const ['customers:manage']);
  bool get canViewInventory =>
      _hasAnyPermission(const ['inventory:view', 'inventory:manage']);
  bool get canManageInventory => _hasAnyPermission(const ['inventory:manage']);
  bool get canViewRecipes =>
      _hasAnyPermission(const ['recipes:view', 'recipes:manage']);
  bool get canManageRecipes => _hasAnyPermission(const ['recipes:manage']);
  bool get canViewVouchers =>
      _hasAnyPermission(const ['vouchers:view', 'vouchers:manage']);
  bool get canManageVouchers => _hasAnyPermission(const ['vouchers:manage']);
  bool get canViewTestimonials =>
      _hasAnyPermission(const ['testimonials:view', 'testimonials:manage']);
  bool get canManageTestimonials =>
      _hasAnyPermission(const ['testimonials:manage']);
  bool get canViewContents =>
      _hasAnyPermission(const ['content:view', 'content:manage']);
  bool get canManageContents => _hasAnyPermission(const ['content:manage']);
  bool get canViewImportAudit => _hasAnyPermission(const ['imports:view']);

  List<AdminSidebarItem> get sidebarItems {
    final items = <AdminSidebarItem>[];
    if (canViewReports || canAccessAdmin) {
      items.add(const AdminSidebarItem(index: 0, label: 'Tổng quan'));
    }
    if (canViewOrders) {
      items.add(const AdminSidebarItem(index: 1, label: 'Đơn hàng'));
    }
    if (canViewProducts) {
      items.add(const AdminSidebarItem(index: 2, label: 'Sản phẩm'));
    }
    if (canViewCustomers) {
      items.add(const AdminSidebarItem(index: 3, label: 'Khách hàng'));
    }
    if (canViewInventory) {
      items.add(const AdminSidebarItem(index: 4, label: 'Nguyên liệu'));
    }
    if (canViewRecipes) {
      items.add(const AdminSidebarItem(index: 5, label: 'Công thức'));
    }
    if (canViewVouchers) {
      items.add(const AdminSidebarItem(index: 6, label: 'Voucher'));
    }
    if (canViewTestimonials) {
      items.add(const AdminSidebarItem(index: 7, label: 'Đánh giá'));
    }
    if (canViewContents) {
      items.add(const AdminSidebarItem(index: 8, label: 'Nội dung'));
    }
    if (canViewReports) {
      items.add(const AdminSidebarItem(index: 9, label: 'Doanh số'));
    }
    if (canViewReports) {
      items.add(const AdminSidebarItem(index: 10, label: 'Reviews'));
    }
    if (canViewReports) {
      items.add(const AdminSidebarItem(index: 11, label: 'Smart Analytics'));
    }
    return items;
  }

  List<AdminOrderModel> get filteredOrders {
    final query = orderSearch.trim().toLowerCase();
    var items = orders.where((item) {
      if (query.isEmpty) return true;
      return item.orderId.toLowerCase().contains(query) ||
          item.customerName.toLowerCase().contains(query) ||
          item.customerEmail.toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query);
    }).toList(growable: false);
    if (orderSort == 'total_desc') {
      items = [...items]..sort((a, b) => b.total.compareTo(a.total));
    } else {
      items = [...items]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return items;
  }

  List<AdminProductModel> get filteredProducts {
    final query = productSearch.trim().toLowerCase();
    var items = products.where((item) {
      if (query.isEmpty) return true;
      return item.title.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          '${item.id}'.contains(query);
    }).toList(growable: false);
    if (productSort == 'price_desc') {
      items = [...items]..sort((a, b) => b.priceValue.compareTo(a.priceValue));
    } else if (productSort == 'price_asc') {
      items = [...items]..sort((a, b) => a.priceValue.compareTo(b.priceValue));
    } else {
      items = [...items]..sort((a, b) => a.title.compareTo(b.title));
    }
    return items;
  }

  List<AdminCustomerModel> get filteredCustomers {
    final query = customerSearch.trim().toLowerCase();
    var items = customers.where((item) {
      if (query.isEmpty) return true;
      return item.fullName.toLowerCase().contains(query) ||
          item.email.toLowerCase().contains(query) ||
          (item.phone ?? '').toLowerCase().contains(query);
    }).toList(growable: false);
    if (customerSort == 'orders_desc') {
      items = [...items]..sort((a, b) => b.orderCount.compareTo(a.orderCount));
    } else {
      items = [...items]..sort((a, b) => a.fullName.compareTo(b.fullName));
    }
    return items;
  }

  List<AdminIngredientModel> get filteredIngredients {
    final query = ingredientSearch.trim().toLowerCase();
    var items = ingredients.where((item) {
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query) ||
          item.status.toLowerCase().contains(query);
    }).toList(growable: false);
    if (ingredientSort == 'stock_asc') {
      items = [...items]
        ..sort((a, b) => a.availableQuantity.compareTo(b.availableQuantity));
    } else if (ingredientSort == 'stock_desc') {
      items = [...items]
        ..sort((a, b) => b.availableQuantity.compareTo(a.availableQuantity));
    } else {
      items = [...items]..sort((a, b) => a.name.compareTo(b.name));
    }
    return items;
  }

  Future<void> load() async {
    if (_hasLoaded) return;
    await forceReload();
  }

  Future<void> forceReload() async {
    _hasLoaded = true;
    update((current) => current.copyWith(isLoading: true, clearErrorMessage: true));
    final errors = <String>[];

    final dashboard = canViewReports || canAccessAdmin
        ? await _loadSection(
            loader: _repository.fetchDashboard,
            fallback: state.dashboard,
            errors: errors,
            label: 'dashboard',
          )
        : state.dashboard;
    final orders = canViewOrders
        ? await _loadSection(
            loader: _repository.fetchOrders,
            fallback: state.orders,
            errors: errors,
            label: 'orders',
          )
        : state.orders;
    final products = canViewProducts
        ? await _loadSection(
            loader: _repository.fetchProducts,
            fallback: state.products,
            errors: errors,
            label: 'products',
          )
        : state.products;
    final customers = canViewCustomers
        ? await _loadSection(
            loader: _repository.fetchCustomers,
            fallback: state.customers,
            errors: errors,
            label: 'customers',
          )
        : state.customers;
    final importAuditLogs = canViewImportAudit
        ? await _loadSection(
            loader: _repository.fetchImportAuditLogs,
            fallback: state.importAuditLogs,
            errors: errors,
            label: 'import-audit-logs',
          )
        : state.importAuditLogs;
    final vouchers = canViewVouchers
        ? await _loadSection(
            loader: _repository.fetchVouchers,
            fallback: state.vouchers,
            errors: errors,
            label: 'vouchers',
          )
        : state.vouchers;
    final testimonials = canViewTestimonials
        ? await _loadSection(
            loader: _repository.fetchTestimonials,
            fallback: state.testimonials,
            errors: errors,
            label: 'testimonials',
          )
        : state.testimonials;
    final contents = canViewContents
        ? await _loadSection(
            loader: _repository.fetchContents,
            fallback: state.contents,
            errors: errors,
            label: 'contents',
          )
        : state.contents;
    final ingredients = canViewInventory
        ? await _loadSection(
            loader: _repository.fetchIngredients,
            fallback: state.ingredients,
            errors: errors,
            label: 'ingredients',
          )
        : state.ingredients;
    final inventoryTransactions = canViewInventory
        ? await _loadSection(
            loader: _repository.fetchInventoryTransactions,
            fallback: state.inventoryTransactions,
            errors: errors,
            label: 'inventory-transactions',
          )
        : state.inventoryTransactions;
    final recipes = canViewRecipes
        ? await _loadSection(
            loader: _repository.fetchRecipes,
            fallback: state.recipes,
            errors: errors,
            label: 'recipes',
          )
        : state.recipes;
    final productCostReports = canViewReports
        ? await _loadSection(
            loader: _repository.fetchProductCostReports,
            fallback: state.productCostReports,
            errors: errors,
            label: 'product-cost-reports',
          )
        : state.productCostReports;
    final reviews = canViewReports
        ? await _loadSection(
            loader: _repository.fetchReviews,
            fallback: state.reviews,
            errors: errors,
            label: 'reviews',
          )
        : state.reviews;
    final revenueSummary = canViewReports
        ? await _loadSection(
            loader: () => _repository.fetchRevenueSummary(state.revenueRange),
            fallback: state.revenueSummary,
            errors: errors,
            label: 'revenue-summary',
          )
        : state.revenueSummary;
    final bestSellers = canViewReports
        ? await _loadSection(
            loader: _repository.fetchBestSellers,
            fallback: state.bestSellers,
            errors: errors,
            label: 'best-sellers',
          )
        : state.bestSellers;
    final customerSegments = canViewReports
        ? await _loadSection(
            loader: _repository.fetchCustomerSegments,
            fallback: state.customerSegments,
            errors: errors,
            label: 'customer-segments',
          )
        : state.customerSegments;
    final revenueForecast = canViewReports
        ? await _loadSection(
            loader: _repository.fetchRevenueForecast,
            fallback: state.revenueForecast,
            errors: errors,
            label: 'revenue-forecast',
          )
        : state.revenueForecast;

    if (errors.length >= 12) {
      _hasLoaded = false;
    }

    update((current) => current.copyWith(
          selectedSidebarIndex: sidebarItems.any(
            (item) => item.index == current.selectedSidebarIndex,
          )
              ? current.selectedSidebarIndex
              : (sidebarItems.isEmpty ? 0 : sidebarItems.first.index),
          dashboard: dashboard,
          orders: orders,
          products: products,
          customers: customers,
          importAuditLogs: importAuditLogs,
          vouchers: vouchers,
          testimonials: testimonials,
          contents: contents,
          ingredients: ingredients,
          inventoryTransactions: inventoryTransactions,
          recipes: recipes,
          productCostReports: productCostReports,
          reviews: reviews,
          revenueSummary: revenueSummary,
          bestSellers: bestSellers,
          customerSegments: customerSegments,
          revenueForecast: revenueForecast,
          isLoading: false,
          errorMessage: errors.isEmpty
              ? null
              : 'Một số mục admin chưa tải được: ${errors.join(', ')}',
          clearErrorMessage: errors.isEmpty,
        ));
  }

  void selectSidebar(int index) {
    final isVisible = sidebarItems.any((item) => item.index == index);
    if (!isVisible) {
      final fallback = sidebarItems.isEmpty ? 0 : sidebarItems.first.index;
      update((current) => current.copyWith(selectedSidebarIndex: fallback));
      return;
    }
    update((current) => current.copyWith(selectedSidebarIndex: index));
  }
  void setOrderSearch(String value) => update((current) => current.copyWith(orderSearch: value));
  void setProductSearch(String value) => update((current) => current.copyWith(productSearch: value));
  void setCustomerSearch(String value) => update((current) => current.copyWith(customerSearch: value));
  void setIngredientSearch(String value) => update((current) => current.copyWith(ingredientSearch: value));
  void setOrderSort(String value) => update((current) => current.copyWith(orderSort: value));
  void setProductSort(String value) => update((current) => current.copyWith(productSort: value));
  void setCustomerSort(String value) => update((current) => current.copyWith(customerSort: value));
  void setIngredientSort(String value) => update((current) => current.copyWith(ingredientSort: value));

  Future<void> advanceOrderStatus(AdminOrderModel order) async {
    final nextStatus = switch (order.status.toLowerCase()) {
      'mới' => 'Xử lý',
      'pending' => 'Xử lý',
      'xử lý' => 'Đang giao',
      'đang giao' => 'Hoàn tất',
      _ => 'Hoàn tất',
    };
    await _updateOrder(order.orderId, nextStatus);
  }

  Future<AdminOrderAdvanceCheckModel> getOrderAdvanceCheck(AdminOrderModel order) {
    return _repository.fetchOrderAdvanceCheck(order.orderId);
  }

  Future<void> toggleProductStock(AdminProductModel product) async {
    final nextStatus =
        product.stockStatus.toLowerCase() == 'còn hàng' ? 'Tạm ẩn' : 'Còn hàng';
    update((current) => current.copyWith(isUpdating: true, clearErrorMessage: true));
    try {
      final updated = await _repository.updateProductStock(product.id, nextStatus);
      final updatedProducts = [
        for (final item in state.products)
          if (item.id == updated.id) updated else item,
      ];
      update((current) => current.copyWith(
            products: updatedProducts,
            isUpdating: false,
            clearErrorMessage: true,
          ));
    } on ApiException catch (error) {
      update((current) => current.copyWith(isUpdating: false, errorMessage: error.message));
    } catch (_) {
      update((current) => current.copyWith(
            isUpdating: false,
            errorMessage: 'Không thể cập nhật sản phẩm.',
          ));
    }
  }

  Future<void> deleteProduct(AdminProductModel product) async {
    await _wrapUpdate(
      action: () async {
        await _repository.deleteProduct(product.id);
        update((current) => current.copyWith(
              products: [
                for (final item in current.products)
                  if (item.id != product.id) item,
              ],
            ));
        await _refreshDashboardOnly();
      },
      fallbackMessage: 'Không thể xóa sản phẩm.',
    );
  }

  Future<void> reloadRecipes() async {
    try {
      final recipes = await _repository.fetchRecipes();
      final productCostReports = await _repository.fetchProductCostReports();
      update((current) => current.copyWith(
            recipes: recipes,
            productCostReports: productCostReports,
            clearErrorMessage: true,
          ));
    } on ApiException catch (error) {
      update((current) => current.copyWith(errorMessage: error.message));
    } catch (_) {
      update((current) => current.copyWith(errorMessage: 'Không thể tải danh sách công thức.'));
    }
  }

  Future<void> deleteRecipe(AdminRecipeModel recipe) async {
    await _wrapUpdate(
      action: () async {
        await _repository.deleteRecipe(recipe.id);
        update((current) => current.copyWith(
              recipes: [
                for (final item in current.recipes)
                  if (item.id != recipe.id) item,
              ],
            ));
        await _refreshCostReportsOnly();
      },
      fallbackMessage: 'Không thể xóa công thức.',
    );
  }

  Future<void> copyRecipe(AdminRecipeModel recipe, int productId) async {
    await _wrapUpdate(
      action: () async {
        await _repository.copyRecipe(recipe.id, productId);
        final recipes = await _repository.fetchRecipes();
        final productCostReports = await _repository.fetchProductCostReports();
        update((current) => current.copyWith(
              recipes: recipes,
              productCostReports: productCostReports,
            ));
      },
      fallbackMessage: 'Không thể sao chép công thức.',
    );
  }

  Future<void> refreshProductsSection() async {
    await _wrapUpdate(
      action: () async {
        final dashboard = await _repository.fetchDashboard();
        final products = await _repository.fetchProducts();
        update((current) => current.copyWith(
              dashboard: dashboard,
              products: products,
            ));
      },
      fallbackMessage: 'Không thể tải lại danh sách sản phẩm.',
    );
  }

  Future<void> refreshIngredientsSection() async {
    await _wrapUpdate(
      action: () async {
        final dashboard = await _repository.fetchDashboard();
        final ingredients = await _repository.fetchIngredients();
        final inventoryTransactions = await _repository.fetchInventoryTransactions();
        update((current) => current.copyWith(
              dashboard: dashboard,
              ingredients: ingredients,
              inventoryTransactions: inventoryTransactions,
            ));
      },
      fallbackMessage: 'Không thể tải lại danh sách nguyên liệu.',
    );
  }

  Future<void> restockIngredient(AdminIngredientModel ingredient, {int quantity = 5}) async {
    await _updateIngredient(ingredient.id, quantityDelta: quantity);
  }

  Future<void> consumeIngredient(AdminIngredientModel ingredient, {int quantity = 1}) async {
    await _updateIngredient(ingredient.id, quantityDelta: -quantity);
  }

  Future<void> deleteIngredient(AdminIngredientModel ingredient) async {
    await _wrapUpdate(
      action: () async {
        await _repository.deleteIngredient(ingredient.id);
        update((current) => current.copyWith(
              ingredients: [
                for (final item in current.ingredients)
                  if (item.id != ingredient.id) item,
              ],
            ));
        await _refreshDashboardOnly();
      },
      fallbackMessage: 'Không thể xóa nguyên liệu.',
    );
  }

  Future<void> createVoucher(AdminVoucherDraft draft) async {
    await _wrapUpdate(
      action: () async {
        final created = await _repository.createVoucher(draft);
        update((current) => current.copyWith(
              vouchers: [...current.vouchers, created],
            ));
      },
      fallbackMessage: 'Không thể tạo voucher.',
    );
  }

  Future<void> updateVoucher(String code, AdminVoucherDraft draft) async {
    await _wrapUpdate(
      action: () async {
        final updated = await _repository.updateVoucher(code, draft);
        update((current) => current.copyWith(
              vouchers: [
                for (final item in current.vouchers)
                  if (item.code == code) updated else item,
              ],
            ));
      },
      fallbackMessage: 'Không thể cập nhật voucher.',
    );
  }

  Future<void> deleteVoucher(AdminVoucherModel voucher) async {
    await _wrapUpdate(
      action: () async {
        await _repository.deleteVoucher(voucher.code);
        update((current) => current.copyWith(
              vouchers: [
                for (final item in current.vouchers)
                  if (item.code != voucher.code) item,
              ],
            ));
      },
      fallbackMessage: 'Không thể xóa voucher.',
    );
  }

  Future<void> toggleTestimonial(AdminTestimonialModel testimonial) async {
    await _wrapUpdate(
      action: () async {
        final updated = await _repository.updateTestimonialVisibility(
          testimonial.id,
          !testimonial.isVisible,
        );
        update((current) => current.copyWith(
              testimonials: [
                for (final item in current.testimonials)
                  if (item.id == updated.id) updated else item,
              ],
            ));
      },
      fallbackMessage: 'Không thể cập nhật đánh giá.',
    );
  }

  Future<void> deleteTestimonial(AdminTestimonialModel testimonial) async {
    await _wrapUpdate(
      action: () async {
        await _repository.deleteTestimonial(testimonial.id);
        update((current) => current.copyWith(
              testimonials: [
                for (final item in current.testimonials)
                  if (item.id != testimonial.id) item,
              ],
            ));
      },
      fallbackMessage: 'Không thể xóa đánh giá.',
    );
  }

  Future<AdminContentDocumentModel?> refreshContent(String key) async {
    try {
      final content = await _repository.fetchContent(key);
      update((current) => current.copyWith(
            contents: [
              for (final item in current.contents)
                if (item.key == key) content else item,
            ],
            clearErrorMessage: true,
          ));
      return content;
    } on ApiException catch (error) {
      update((current) => current.copyWith(errorMessage: error.message));
      return null;
    } catch (_) {
      update((current) => current.copyWith(errorMessage: 'Không thể tải nội dung trang.'));
      return null;
    }
  }

  Future<void> updateContent(String key, String jsonContent) async {
    await _wrapUpdate(
      action: () async {
        final updated = await _repository.updateContent(key, jsonContent);
        update((current) => current.copyWith(
              contents: [
                for (final item in current.contents)
                  if (item.key == key) updated else item,
              ],
            ));
      },
      fallbackMessage: 'Không thể cập nhật nội dung.',
    );
  }

  Future<void> _updateOrder(String orderId, String status) async {
    await _wrapUpdate(
      action: () async {
        final updated = await _repository.updateOrderStatus(orderId, status);
        final updatedOrders = [
          for (final item in state.orders)
            if (item.orderId == updated.orderId) updated else item,
        ];
        update((current) => current.copyWith(orders: updatedOrders));
      },
      fallbackMessage: 'Không thể cập nhật đơn hàng.',
    );
  }

  Future<void> bulkAdvanceFilteredOrders() async {
    final orderIds = filteredOrders.map((item) => item.orderId).toList(growable: false);
    if (orderIds.isEmpty) {
      return;
    }
    await _wrapUpdate(
      action: () async {
        await _repository.bulkUpdateOrders(orderIds, 'Xử lý');
        final orders = await _repository.fetchOrders();
        update((current) => current.copyWith(orders: orders));
      },
      fallbackMessage: 'Không thể cập nhật hàng loạt đơn hàng.',
    );
  }

  Future<void> bulkHideFilteredProducts() async {
    final productIds = filteredProducts.map((item) => item.id).toList(growable: false);
    if (productIds.isEmpty) {
      return;
    }
    await _wrapUpdate(
      action: () async {
        await _repository.bulkUpdateProductStocks(productIds, 'Tạm ẩn');
        final products = await _repository.fetchProducts();
        update((current) => current.copyWith(products: products));
      },
      fallbackMessage: 'Không thể cập nhật hàng loạt sản phẩm.',
    );
  }

  Future<void> _updateIngredient(String ingredientId, {required int quantityDelta}) async {
    await _wrapUpdate(
      action: () async {
        final updated = await _repository.updateIngredient(
          ingredientId,
          quantityDelta: quantityDelta,
        );
        final updatedIngredients = [
          for (final item in state.ingredients)
            if (item.id == updated.id) updated else item,
        ];
        final inventoryTransactions =
            await _repository.fetchInventoryTransactions();
        update((current) => current.copyWith(
              ingredients: updatedIngredients,
              inventoryTransactions: inventoryTransactions,
            ));
        await _refreshDashboardOnly();
      },
      fallbackMessage: 'Không thể cập nhật nguyên liệu.',
    );
  }

  Future<void> _refreshDashboardOnly() async {
    final dashboard = await _repository.fetchDashboard();
    update((current) => current.copyWith(dashboard: dashboard));
  }

  Future<void> _refreshCostReportsOnly() async {
    final productCostReports = await _repository.fetchProductCostReports();
    update((current) => current.copyWith(productCostReports: productCostReports));
  }

  Future<void> deleteReview(int productId, String createdAt) async {
    await _wrapUpdate(
      action: () async {
        await _repository.deleteReview(productId, createdAt);
        final updated = state.reviews
            .where((r) => !(r.productId == productId && r.createdAt == createdAt))
            .toList(growable: false);
        update((current) => current.copyWith(reviews: updated));
      },
      fallbackMessage: 'Không thể xóa review.',
    );
  }

  Future<void> refreshRevenueSummary({String? range}) async {
    final effectiveRange = range ?? state.revenueRange;
    if (range != null && range != state.revenueRange) {
      update((current) => current.copyWith(revenueRange: range));
    }
    try {
      final summary = await _repository.fetchRevenueSummary(effectiveRange);
      update((current) => current.copyWith(revenueSummary: summary));
    } catch (_) {
      // silent fail — keep existing data
    }
  }

  Future<void> _wrapUpdate({
    required Future<void> Function() action,
    required String fallbackMessage,
  }) async {
    update((current) => current.copyWith(isUpdating: true, clearErrorMessage: true));
    try {
      await action();
      update((current) => current.copyWith(isUpdating: false, clearErrorMessage: true));
    } on ApiException catch (error) {
      update((current) => current.copyWith(isUpdating: false, errorMessage: error.message));
    } catch (_) {
      update((current) => current.copyWith(isUpdating: false, errorMessage: fallbackMessage));
    }
  }

  Future<T> _loadSection<T>({
    required Future<T> Function() loader,
    required T fallback,
    required List<String> errors,
    required String label,
  }) async {
    try {
      return await loader();
    } on ApiException {
      errors.add(label);
      return fallback;
    } catch (_) {
      errors.add(label);
      return fallback;
    }
  }

  bool _hasAnyPermission(List<String> permissions) {
    final user = AppServices.instance.authSession.currentUser;
    if (user == null) {
      return false;
    }
    return user.hasAnyPermission(permissions);
  }
}

bool _sameOrders(List<AdminOrderModel> left, List<AdminOrderModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.orderId != b.orderId ||
        a.customerName != b.customerName ||
        a.customerEmail != b.customerEmail ||
        a.total != b.total ||
        a.status != b.status ||
        a.itemCount != b.itemCount ||
        a.paymentMethod != b.paymentMethod ||
        a.createdAt != b.createdAt) {
      return false;
    }
  }
  return true;
}

bool _sameProducts(List<AdminProductModel> left, List<AdminProductModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.id != b.id ||
        a.title != b.title ||
        a.category != b.category ||
        a.priceValue != b.priceValue ||
        a.stockStatus != b.stockStatus ||
        a.imageUrl != b.imageUrl) {
      return false;
    }
  }
  return true;
}

bool _sameCustomers(List<AdminCustomerModel> left, List<AdminCustomerModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.id != b.id ||
        a.fullName != b.fullName ||
        a.email != b.email ||
        a.phone != b.phone ||
        a.address != b.address ||
        a.orderCount != b.orderCount ||
        a.isAdmin != b.isAdmin) {
      return false;
    }
  }
  return true;
}

bool _sameImportAuditLogs(
  List<AdminImportAuditLogModel> left,
  List<AdminImportAuditLogModel> right,
) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.id != b.id ||
        a.entityType != b.entityType ||
        a.status != b.status ||
        a.createdCount != b.createdCount ||
        a.updatedCount != b.updatedCount ||
        a.errorCount != b.errorCount ||
        a.createdAt != b.createdAt) {
      return false;
    }
  }
  return true;
}

bool _sameVouchers(List<AdminVoucherModel> left, List<AdminVoucherModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.code != b.code ||
        a.title != b.title ||
        a.note != b.note ||
        a.accent != b.accent ||
        a.discountType != b.discountType ||
        a.discountValue != b.discountValue ||
        a.minOrderValue != b.minOrderValue) {
      return false;
    }
  }
  return true;
}

bool _sameTestimonials(List<AdminTestimonialModel> left, List<AdminTestimonialModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.id != b.id ||
        a.content != b.content ||
        a.author != b.author ||
        a.accent != b.accent ||
        a.createdAt != b.createdAt ||
        a.isVisible != b.isVisible) {
      return false;
    }
  }
  return true;
}

bool _sameContents(List<AdminContentDocumentModel> left, List<AdminContentDocumentModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.key != b.key || a.title != b.title || a.jsonContent != b.jsonContent) {
      return false;
    }
  }
  return true;
}

bool _sameIngredients(List<AdminIngredientModel> left, List<AdminIngredientModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.id != b.id ||
        a.name != b.name ||
        a.category != b.category ||
        a.unit != b.unit ||
        a.standardUnit != b.standardUnit ||
        a.conversionFactor != b.conversionFactor ||
        a.unitPrice != b.unitPrice ||
        a.availableQuantity != b.availableQuantity ||
        a.availableNormalizedQuantity != b.availableNormalizedQuantity ||
        a.lowStockThreshold != b.lowStockThreshold ||
        a.lowStockThresholdNormalized != b.lowStockThresholdNormalized ||
        a.status != b.status ||
        a.lastUpdatedAt != b.lastUpdatedAt) {
      return false;
    }
  }
  return true;
}

bool _sameRecipes(List<AdminRecipeModel> left, List<AdminRecipeModel> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.id != b.id ||
        a.productId != b.productId ||
        a.productTitle != b.productTitle ||
        a.recipeType != b.recipeType ||
        a.yieldQuantity != b.yieldQuantity ||
        a.yieldUnit != b.yieldUnit ||
        a.totalCost != b.totalCost ||
        a.costPerUnit != b.costPerUnit ||
        a.grossProfitEstimate != b.grossProfitEstimate ||
        a.grossMarginPercent != b.grossMarginPercent ||
        a.createdAt != b.createdAt ||
        a.ingredients.length != b.ingredients.length) {
      return false;
    }
  }
  return true;
}

bool _sameInventoryTransactions(
  List<AdminInventoryTransactionModel> left,
  List<AdminInventoryTransactionModel> right,
) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.id != b.id ||
        a.ingredientId != b.ingredientId ||
        a.transactionType != b.transactionType ||
        a.quantityDelta != b.quantityDelta ||
        a.normalizedQuantityDelta != b.normalizedQuantityDelta ||
        a.balanceNormalizedQuantity != b.balanceNormalizedQuantity ||
        a.referenceType != b.referenceType ||
        a.referenceId != b.referenceId ||
        a.createdAt != b.createdAt) {
      return false;
    }
  }
  return true;
}

bool _sameReviews(
  List<AdminProductReviewModel> left,
  List<AdminProductReviewModel> right,
) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

bool _sameProductCostReports(
  List<AdminProductCostReportModel> left,
  List<AdminProductCostReportModel> right,
) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    final a = left[i];
    final b = right[i];
    if (a.productId != b.productId ||
        a.productTitle != b.productTitle ||
        a.recipeType != b.recipeType ||
        a.sellingPrice != b.sellingPrice ||
        a.estimatedCost != b.estimatedCost ||
        a.grossProfit != b.grossProfit ||
        a.grossMarginPercent != b.grossMarginPercent) {
      return false;
    }
  }
  return true;
}
