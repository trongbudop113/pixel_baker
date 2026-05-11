import '../models/admin_models.dart';
import '../models/menu_models.dart';
import '../network/base_api_repository.dart';

abstract class AdminRepository {
  Future<AdminDashboardModel> fetchDashboard();
  Future<List<AdminImportAuditLogModel>> fetchImportAuditLogs();
  Future<List<AdminOrderModel>> fetchOrders();
  Future<AdminOrderAdvanceCheckModel> fetchOrderAdvanceCheck(String orderId);
  Future<List<AdminOrderExcelRow>> fetchOrderExcelRows();
  Future<AdminBulkImportResultModel> importOrderExcelRows(List<AdminOrderExcelRow> rows);
  Future<AdminOrderModel> updateOrderStatus(String orderId, String status);
  Future<String> bulkUpdateOrders(List<String> orderIds, String status);
  Future<List<AdminProductModel>> fetchProducts();
  Future<List<AdminProductExcelRow>> fetchProductExcelRows();
  Future<AdminBulkImportResultModel> importProductExcelRows(List<AdminProductExcelRow> rows);
  Future<AdminProductModel> updateProductStock(int productId, String stockStatus);
  Future<String> bulkUpdateProductStocks(List<int> productIds, String stockStatus);
  Future<MenuProductDetail> fetchProductDetail(int productId);
  Future<MenuProductDetail> createProduct(AdminProductDraft draft);
  Future<MenuProductDetail> updateProduct(int productId, AdminProductDraft draft);
  Future<void> deleteProduct(int productId);
  Future<List<AdminCustomerModel>> fetchCustomers();
  Future<List<AdminCustomerExcelRow>> fetchCustomerExcelRows();
  Future<AdminBulkImportResultModel> importCustomerExcelRows(List<AdminCustomerExcelRow> rows);
  Future<AdminCustomerModel> fetchCustomer(String customerId);
  Future<AdminCustomerModel> updateCustomer(String customerId, AdminCustomerDraft draft);
  Future<List<AdminVoucherModel>> fetchVouchers();
  Future<List<AdminVoucherExcelRow>> fetchVoucherExcelRows();
  Future<AdminBulkImportResultModel> importVoucherExcelRows(List<AdminVoucherExcelRow> rows);
  Future<AdminVoucherModel> createVoucher(AdminVoucherDraft draft);
  Future<AdminVoucherModel> updateVoucher(String code, AdminVoucherDraft draft);
  Future<void> deleteVoucher(String code);
  Future<List<AdminTestimonialModel>> fetchTestimonials();
  Future<AdminTestimonialModel> updateTestimonialVisibility(String id, bool isVisible);
  Future<void> deleteTestimonial(String id);
  Future<List<AdminContentDocumentModel>> fetchContents();
  Future<AdminContentDocumentModel> fetchContent(String key);
  Future<AdminContentDocumentModel> updateContent(String key, String jsonContent);
  Future<List<AdminIngredientModel>> fetchIngredients();
  Future<List<AdminInventoryTransactionModel>> fetchInventoryTransactions();
  Future<List<AdminProductCostReportModel>> fetchProductCostReports();
  Future<List<AdminIngredientExcelRow>> fetchIngredientExcelRows();
  Future<AdminBulkImportResultModel> importIngredientExcelRows(List<AdminIngredientExcelRow> rows);
  Future<AdminIngredientModel> fetchIngredient(String ingredientId);
  Future<AdminIngredientModel> createIngredient(AdminIngredientDraft draft);
  Future<AdminIngredientModel> updateIngredientInfo(String ingredientId, AdminIngredientDraft draft);
  Future<void> deleteIngredient(String ingredientId);
  Future<List<AdminRecipeModel>> fetchRecipes();
  Future<List<AdminRecipeExcelRow>> fetchRecipeExcelRows();
  Future<AdminBulkImportResultModel> importRecipeExcelRows(List<AdminRecipeExcelRow> rows);
  Future<AdminRecipeModel> fetchRecipe(String recipeId);
  Future<AdminRecipeOptionsModel> fetchRecipeOptions({String? recipeId});
  Future<AdminRecipeModel> createRecipe(AdminRecipeDraft draft);
  Future<AdminRecipeModel> updateRecipe(String recipeId, AdminRecipeDraft draft);
  Future<AdminRecipeModel> copyRecipe(String recipeId, int productId);
  Future<void> deleteRecipe(String recipeId);
  Future<AdminIngredientModel> updateIngredient(
    String ingredientId, {
    int quantityDelta = 0,
    int? lowStockThreshold,
  });
}

class ApiAdminRepository extends BaseApiRepository implements AdminRepository {
  ApiAdminRepository(super.apiClient);

  @override
  Future<AdminDashboardModel> fetchDashboard() async {
    final response = await apiClient.get<AdminDashboardModel>(
      '/admin/dashboard',
      requiresAuth: true,
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminDashboardModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<List<AdminImportAuditLogModel>> fetchImportAuditLogs() async {
    final response = await apiClient.get<List<AdminImportAuditLogModel>>(
      '/admin/import-audit-logs',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminImportAuditLogModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<List<AdminOrderModel>> fetchOrders() async {
    final response = await apiClient.get<List<AdminOrderModel>>(
      '/admin/orders',
      requiresAuth: true,
      decoder: (json) => readList(_unwrapListPayload(json), AdminOrderModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminOrderAdvanceCheckModel> fetchOrderAdvanceCheck(String orderId) async {
    final response = await apiClient.get<AdminOrderAdvanceCheckModel>(
      '/admin/orders/$orderId/advance-check',
      requiresAuth: true,
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminOrderAdvanceCheckModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<List<AdminOrderExcelRow>> fetchOrderExcelRows() async {
    final response = await apiClient.get<List<AdminOrderExcelRow>>(
      '/admin/orders/excel-rows',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminOrderExcelRow.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminBulkImportResultModel> importOrderExcelRows(
    List<AdminOrderExcelRow> rows,
  ) async {
    final response = await apiClient.post<AdminBulkImportResultModel>(
      '/admin/orders/excel-import',
      requiresAuth: true,
      body: {'items': rows.map((item) => item.toJson()).toList(growable: false)},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminBulkImportResultModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminOrderModel> updateOrderStatus(String orderId, String status) async {
    final response = await apiClient.patch<AdminOrderModel>(
      '/admin/orders/$orderId',
      requiresAuth: true,
      body: {'status': status},
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminOrderModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<String> bulkUpdateOrders(List<String> orderIds, String status) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/admin/orders/bulk-status',
      requiresAuth: true,
      body: {'orderIds': orderIds, 'status': status},
      decoder: (json) => Map<String, dynamic>.from(_unwrapItemPayload(json) as Map),
    );
    return (response.data['message'] ?? '').toString();
  }

  @override
  Future<List<AdminProductModel>> fetchProducts() async {
    final response = await apiClient.get<List<AdminProductModel>>(
      '/admin/products',
      requiresAuth: true,
      decoder: (json) => readList(_unwrapListPayload(json), AdminProductModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminProductModel> updateProductStock(int productId, String stockStatus) async {
    final response = await apiClient.patch<AdminProductModel>(
      '/admin/products/$productId',
      requiresAuth: true,
      body: {'stockStatus': stockStatus},
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminProductModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<String> bulkUpdateProductStocks(List<int> productIds, String stockStatus) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/admin/products/bulk-stock',
      requiresAuth: true,
      body: {'productIds': productIds, 'stockStatus': stockStatus},
      decoder: (json) => Map<String, dynamic>.from(_unwrapItemPayload(json) as Map),
    );
    return (response.data['message'] ?? '').toString();
  }

  @override
  Future<List<AdminProductExcelRow>> fetchProductExcelRows() async {
    final response = await apiClient.get<List<AdminProductExcelRow>>(
      '/admin/products/excel-rows',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminProductExcelRow.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminBulkImportResultModel> importProductExcelRows(
    List<AdminProductExcelRow> rows,
  ) async {
    final response = await apiClient.post<AdminBulkImportResultModel>(
      '/admin/products/excel-import',
      requiresAuth: true,
      body: {
        'items': rows.map((item) => item.toJson()).toList(growable: false),
      },
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminBulkImportResultModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<MenuProductDetail> fetchProductDetail(int productId) async {
    final response = await apiClient.get<MenuProductDetail>(
      '/admin/products/$productId',
      requiresAuth: true,
      decoder: (json) => readItem(_unwrapItemPayload(json), MenuProductDetail.fromJson),
    );
    return response.data;
  }

  @override
  Future<MenuProductDetail> createProduct(AdminProductDraft draft) async {
    final response = await apiClient.post<MenuProductDetail>(
      '/admin/products',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), MenuProductDetail.fromJson),
    );
    return response.data;
  }

  @override
  Future<MenuProductDetail> updateProduct(int productId, AdminProductDraft draft) async {
    final response = await apiClient.put<MenuProductDetail>(
      '/admin/products/$productId',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), MenuProductDetail.fromJson),
    );
    return response.data;
  }

  @override
  Future<void> deleteProduct(int productId) async {
    await apiClient.delete<Object?>(
      '/admin/products/$productId',
      requiresAuth: true,
      decoder: (json) => _unwrapItemPayload(json),
    );
  }

  @override
  Future<List<AdminCustomerModel>> fetchCustomers() async {
    final response = await apiClient.get<List<AdminCustomerModel>>(
      '/admin/customers',
      requiresAuth: true,
      decoder: (json) => readList(_unwrapListPayload(json), AdminCustomerModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<List<AdminCustomerExcelRow>> fetchCustomerExcelRows() async {
    final response = await apiClient.get<List<AdminCustomerExcelRow>>(
      '/admin/customers/excel-rows',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminCustomerExcelRow.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminBulkImportResultModel> importCustomerExcelRows(
    List<AdminCustomerExcelRow> rows,
  ) async {
    final response = await apiClient.post<AdminBulkImportResultModel>(
      '/admin/customers/excel-import',
      requiresAuth: true,
      body: {'items': rows.map((item) => item.toJson()).toList(growable: false)},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminBulkImportResultModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminCustomerModel> fetchCustomer(String customerId) async {
    final response = await apiClient.get<AdminCustomerModel>(
      '/admin/customers/$customerId',
      requiresAuth: true,
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminCustomerModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminCustomerModel> updateCustomer(String customerId, AdminCustomerDraft draft) async {
    final response = await apiClient.put<AdminCustomerModel>(
      '/admin/customers/$customerId',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminCustomerModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<List<AdminVoucherModel>> fetchVouchers() async {
    final response = await apiClient.get<List<AdminVoucherModel>>(
      '/admin/vouchers',
      requiresAuth: true,
      decoder: (json) => readList(_unwrapListPayload(json), AdminVoucherModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<List<AdminVoucherExcelRow>> fetchVoucherExcelRows() async {
    final response = await apiClient.get<List<AdminVoucherExcelRow>>(
      '/admin/vouchers/excel-rows',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminVoucherExcelRow.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminBulkImportResultModel> importVoucherExcelRows(
    List<AdminVoucherExcelRow> rows,
  ) async {
    final response = await apiClient.post<AdminBulkImportResultModel>(
      '/admin/vouchers/excel-import',
      requiresAuth: true,
      body: {'items': rows.map((item) => item.toJson()).toList(growable: false)},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminBulkImportResultModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminVoucherModel> createVoucher(AdminVoucherDraft draft) async {
    final response = await apiClient.post<AdminVoucherModel>(
      '/admin/vouchers',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminVoucherModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminVoucherModel> updateVoucher(String code, AdminVoucherDraft draft) async {
    final response = await apiClient.put<AdminVoucherModel>(
      '/admin/vouchers/$code',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminVoucherModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<void> deleteVoucher(String code) async {
    await apiClient.delete<Object?>(
      '/admin/vouchers/$code',
      requiresAuth: true,
      decoder: (json) => _unwrapItemPayload(json),
    );
  }

  @override
  Future<List<AdminTestimonialModel>> fetchTestimonials() async {
    final response = await apiClient.get<List<AdminTestimonialModel>>(
      '/admin/testimonials',
      requiresAuth: true,
      decoder: (json) =>
          readList(_unwrapListPayload(json), AdminTestimonialModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminTestimonialModel> updateTestimonialVisibility(
    String id,
    bool isVisible,
  ) async {
    final response = await apiClient.patch<AdminTestimonialModel>(
      '/admin/testimonials/$id',
      requiresAuth: true,
      body: {'isVisible': isVisible},
      decoder: (json) =>
          readItem(_unwrapItemPayload(json), AdminTestimonialModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<void> deleteTestimonial(String id) async {
    await apiClient.delete<Object?>(
      '/admin/testimonials/$id',
      requiresAuth: true,
      decoder: (json) => _unwrapItemPayload(json),
    );
  }

  @override
  Future<List<AdminContentDocumentModel>> fetchContents() async {
    try {
      final response = await apiClient.get<List<AdminContentDocumentModel>>(
        '/admin/contents',
        requiresAuth: true,
        decoder: (json) => readList(
          _unwrapListPayload(json),
          AdminContentDocumentModel.fromJson,
        ),
      );
      return response.data;
    } catch (_) {
      final items = <AdminContentDocumentModel>[];
      for (final key in const ['home', 'story', 'contact', 'login', 'register']) {
        try {
          items.add(await fetchContent(key));
        } catch (_) {}
      }
      if (items.isNotEmpty) {
        return items;
      }
      rethrow;
    }
  }

  @override
  Future<AdminContentDocumentModel> fetchContent(String key) async {
    final response = await apiClient.get<AdminContentDocumentModel>(
      '/admin/contents/$key',
      requiresAuth: true,
      decoder: (json) =>
          readItem(_unwrapItemPayload(json), AdminContentDocumentModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminContentDocumentModel> updateContent(String key, String jsonContent) async {
    final response = await apiClient.put<AdminContentDocumentModel>(
      '/admin/contents/$key',
      requiresAuth: true,
      body: {'jsonContent': jsonContent},
      decoder: (json) =>
          readItem(_unwrapItemPayload(json), AdminContentDocumentModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<List<AdminIngredientModel>> fetchIngredients() async {
    final response = await apiClient.get<List<AdminIngredientModel>>(
      '/admin/ingredients',
      requiresAuth: true,
      decoder: (json) => readList(_unwrapListPayload(json), AdminIngredientModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<List<AdminInventoryTransactionModel>> fetchInventoryTransactions() async {
    final response = await apiClient.get<List<AdminInventoryTransactionModel>>(
      '/admin/inventory-transactions',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminInventoryTransactionModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<List<AdminProductCostReportModel>> fetchProductCostReports() async {
    final response = await apiClient.get<List<AdminProductCostReportModel>>(
      '/admin/product-cost-reports',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminProductCostReportModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<List<AdminIngredientExcelRow>> fetchIngredientExcelRows() async {
    final response = await apiClient.get<List<AdminIngredientExcelRow>>(
      '/admin/ingredients/excel-rows',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminIngredientExcelRow.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminBulkImportResultModel> importIngredientExcelRows(
    List<AdminIngredientExcelRow> rows,
  ) async {
    final response = await apiClient.post<AdminBulkImportResultModel>(
      '/admin/ingredients/excel-import',
      requiresAuth: true,
      body: {
        'items': rows.map((item) => item.toJson()).toList(growable: false),
      },
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminBulkImportResultModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminIngredientModel> fetchIngredient(String ingredientId) async {
    final response = await apiClient.get<AdminIngredientModel>(
      '/admin/ingredients/$ingredientId',
      requiresAuth: true,
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminIngredientModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminIngredientModel> createIngredient(AdminIngredientDraft draft) async {
    final response = await apiClient.post<AdminIngredientModel>(
      '/admin/ingredients',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminIngredientModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminIngredientModel> updateIngredientInfo(String ingredientId, AdminIngredientDraft draft) async {
    final response = await apiClient.put<AdminIngredientModel>(
      '/admin/ingredients/$ingredientId',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminIngredientModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<void> deleteIngredient(String ingredientId) async {
    await apiClient.delete<Object?>(
      '/admin/ingredients/$ingredientId',
      requiresAuth: true,
      decoder: (json) => _unwrapItemPayload(json),
    );
  }

  @override
  Future<List<AdminRecipeModel>> fetchRecipes() async {
    final response = await apiClient.get<List<AdminRecipeModel>>(
      '/admin/recipes',
      requiresAuth: true,
      decoder: (json) => readList(_unwrapListPayload(json), AdminRecipeModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<List<AdminRecipeExcelRow>> fetchRecipeExcelRows() async {
    final response = await apiClient.get<List<AdminRecipeExcelRow>>(
      '/admin/recipes/excel-rows',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        AdminRecipeExcelRow.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminBulkImportResultModel> importRecipeExcelRows(
    List<AdminRecipeExcelRow> rows,
  ) async {
    final response = await apiClient.post<AdminBulkImportResultModel>(
      '/admin/recipes/excel-import',
      requiresAuth: true,
      body: {'items': rows.map((item) => item.toJson()).toList(growable: false)},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AdminBulkImportResultModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<AdminRecipeModel> fetchRecipe(String recipeId) async {
    final response = await apiClient.get<AdminRecipeModel>(
      '/admin/recipes/$recipeId',
      requiresAuth: true,
      decoder: (json) =>
          readItem(_unwrapItemPayload(json), AdminRecipeModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminRecipeOptionsModel> fetchRecipeOptions({String? recipeId}) async {
    final response = await apiClient.get<AdminRecipeOptionsModel>(
      '/admin/recipes/options',
      requiresAuth: true,
      queryParameters: {
        if (recipeId != null && recipeId.isNotEmpty) 'recipe_id': recipeId,
      },
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminRecipeOptionsModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminRecipeModel> createRecipe(AdminRecipeDraft draft) async {
    final response = await apiClient.post<AdminRecipeModel>(
      '/admin/recipes',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminRecipeModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminRecipeModel> updateRecipe(String recipeId, AdminRecipeDraft draft) async {
    final response = await apiClient.put<AdminRecipeModel>(
      '/admin/recipes/$recipeId',
      requiresAuth: true,
      body: draft.toJson(),
      decoder: (json) =>
          readItem(_unwrapItemPayload(json), AdminRecipeModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<AdminRecipeModel> copyRecipe(String recipeId, int productId) async {
    final response = await apiClient.post<AdminRecipeModel>(
      '/admin/recipes/$recipeId/copy',
      requiresAuth: true,
      body: {'productId': productId},
      decoder: (json) =>
          readItem(_unwrapItemPayload(json), AdminRecipeModel.fromJson),
    );
    return response.data;
  }

  @override
  Future<void> deleteRecipe(String recipeId) async {
    await apiClient.delete<Object?>(
      '/admin/recipes/$recipeId',
      requiresAuth: true,
      decoder: (json) => _unwrapItemPayload(json),
    );
  }

  @override
  Future<AdminIngredientModel> updateIngredient(
    String ingredientId, {
    int quantityDelta = 0,
    int? lowStockThreshold,
  }) async {
    final response = await apiClient.patch<AdminIngredientModel>(
      '/admin/ingredients/$ingredientId',
      requiresAuth: true,
      body: {
        'quantityDelta': quantityDelta,
        if (lowStockThreshold != null) 'lowStockThreshold': lowStockThreshold,
      },
      decoder: (json) => readItem(_unwrapItemPayload(json), AdminIngredientModel.fromJson),
    );
    return response.data;
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    return json;
  }

  Object? _unwrapListPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['items'];
      return data ?? json;
    }
    return json;
  }
}
