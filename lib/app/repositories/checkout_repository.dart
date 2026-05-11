import '../models/cart_models.dart';
import '../models/checkout_models.dart';
import '../network/api_exception.dart';
import '../network/base_api_repository.dart';

abstract class CheckoutRepository {
  Future<CartSyncResult> getCart();
  Future<CartSyncResult> replaceCart(List<CartItem> items);
  Future<CartSyncResult> mergeCart(List<CartItem> guestItems);
  Future<CheckoutValidationModel> validateCheckout(CheckoutRequestModel request);
  Future<CheckoutResult> placeOrder(CheckoutRequestModel request);
  Future<List<OrderSummaryModel>> getMyOrders();
  Future<OrderDetailModel> getOrderDetail(String orderId);
  Future<OrderDetailModel> confirmBankTransfer(String orderId);
  Future<OrderDetailModel> cancelOrder(String orderId);
  Future<OrderDetailModel> requestRefund(String orderId);
}

class ApiCheckoutRepository extends BaseApiRepository
    implements CheckoutRepository {
  ApiCheckoutRepository(super.apiClient);

  @override
  Future<CartSyncResult> getCart() async {
    final response = await apiClient.get<CartSyncResult>(
      '/checkout/cart',
      requiresAuth: true,
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        CartSyncResult.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<CartSyncResult> replaceCart(List<CartItem> items) async {
    final response = await apiClient.put<CartSyncResult>(
      '/checkout/cart',
      requiresAuth: true,
      body: {
        'items': items
            .map(
              (item) => {
                'productId': item.productId,
                'title': item.title,
                'priceValue': item.priceValue,
                'quantity': item.quantity,
                'category': item.category,
                'imageUrl': item.imageUrl,
                'price': item.price,
                'variantKey': item.variantKey,
                'variantLabel': item.variantLabel,
                'boxItems': item.boxItems
                    .map((entry) => entry.toJson())
                    .toList(growable: false),
              },
            )
            .toList(growable: false),
      },
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        CartSyncResult.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<CartSyncResult> mergeCart(List<CartItem> guestItems) async {
    final response = await apiClient.post<CartSyncResult>(
      '/checkout/cart/merge',
      requiresAuth: true,
      body: {
        'items': guestItems
            .map(
              (item) => {
                'productId': item.productId,
                'title': item.title,
                'priceValue': item.priceValue,
                'quantity': item.quantity,
                'category': item.category,
                'imageUrl': item.imageUrl,
                'price': item.price,
                'variantKey': item.variantKey,
                'variantLabel': item.variantLabel,
                'boxItems': item.boxItems
                    .map((entry) => entry.toJson())
                    .toList(growable: false),
              },
            )
            .toList(growable: false),
      },
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        CartSyncResult.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<CheckoutValidationModel> validateCheckout(
    CheckoutRequestModel request,
  ) async {
    final response = await apiClient.post<CheckoutValidationModel>(
      '/checkout/validate',
      requiresAuth: true,
      body: request.toJson(),
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        CheckoutValidationModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<CheckoutResult> placeOrder(CheckoutRequestModel request) async {
    final response = await apiClient.post<CheckoutResult>(
      '/checkout/place',
      requiresAuth: true,
      body: request.toJson(),
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        CheckoutResult.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<List<OrderSummaryModel>> getMyOrders() async {
    final response = await apiClient.get<List<OrderSummaryModel>>(
      '/checkout/orders/mine',
      requiresAuth: true,
      decoder: (json) => readList(
        _unwrapListPayload(json),
        OrderSummaryModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<OrderDetailModel> getOrderDetail(String orderId) async {
    final response = await apiClient.get<OrderDetailModel>(
      '/checkout/orders/$orderId',
      requiresAuth: true,
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        OrderDetailModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<OrderDetailModel> confirmBankTransfer(String orderId) async {
    final response = await apiClient.post<OrderDetailModel>(
      '/checkout/orders/$orderId/confirm-bank-transfer',
      requiresAuth: true,
      body: const <String, dynamic>{},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        OrderDetailModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<OrderDetailModel> cancelOrder(String orderId) async {
    final response = await apiClient.post<OrderDetailModel>(
      '/checkout/orders/$orderId/cancel',
      requiresAuth: true,
      body: const <String, dynamic>{},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        OrderDetailModel.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<OrderDetailModel> requestRefund(String orderId) async {
    final response = await apiClient.post<OrderDetailModel>(
      '/checkout/orders/$orderId/refund-request',
      requiresAuth: true,
      body: const <String, dynamic>{},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        OrderDetailModel.fromJson,
      ),
    );
    return response.data;
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    throw const ApiException(
      message: 'Invalid checkout response payload',
      code: 'invalid_checkout_payload',
    );
  }

  Object? _unwrapListPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['items'];
      return data ?? json;
    }
    return json;
  }
}
