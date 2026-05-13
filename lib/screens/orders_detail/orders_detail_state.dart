import '../../app/models/checkout_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/checkout_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

class OrdersDetailViewState {
  const OrdersDetailViewState({
    this.selectedOrderIndex = 0,
    this.searchKeyword = '',
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
    this.actionMessage,
    this.orders = const [],
    this.selectedOrder,
  });

  final int selectedOrderIndex;
  final String searchKeyword;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;
  final String? actionMessage;
  final List<OrderSummaryModel> orders;
  final OrderDetailModel? selectedOrder;

  OrdersDetailViewState copyWith({
    int? selectedOrderIndex,
    String? searchKeyword,
    bool? isLoading,
    bool? isUpdating,
    String? errorMessage,
    String? actionMessage,
    List<OrderSummaryModel>? orders,
    OrderDetailModel? selectedOrder,
    bool clearErrorMessage = false,
    bool clearActionMessage = false,
    bool clearSelectedOrder = false,
  }) {
    return OrdersDetailViewState(
      selectedOrderIndex: selectedOrderIndex ?? this.selectedOrderIndex,
      searchKeyword: searchKeyword ?? this.searchKeyword,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
      orders: orders ?? this.orders,
      selectedOrder:
          clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OrdersDetailViewState &&
        other.selectedOrderIndex == selectedOrderIndex &&
        other.searchKeyword == searchKeyword &&
        other.isLoading == isLoading &&
        other.isUpdating == isUpdating &&
        other.errorMessage == errorMessage &&
        other.actionMessage == actionMessage &&
        _sameOrderSummaries(other.orders, orders) &&
        _sameOrderDetail(other.selectedOrder, selectedOrder);
  }

  @override
  int get hashCode => Object.hash(
        selectedOrderIndex,
        searchKeyword,
        isLoading,
        isUpdating,
        errorMessage,
        actionMessage,
        Object.hashAll(orders),
        selectedOrder?.orderId,
        selectedOrder?.total,
        selectedOrder?.status,
      );
}

class OrdersDetailState
    extends ScreenController<OrdersDetailViewState, Never> {
  OrdersDetailState({
    CheckoutRepository? checkoutRepository,
  })  : _checkoutRepository =
            checkoutRepository ?? AppServices.instance.checkoutRepository,
        super(const OrdersDetailViewState());

  final CheckoutRepository _checkoutRepository;
  final Map<String, OrderDetailModel> _detailCache = <String, OrderDetailModel>{};

  int get selectedOrderIndex => state.selectedOrderIndex;
  String get searchKeyword => state.searchKeyword;
  bool get isLoading => state.isLoading;
  bool get isUpdating => state.isUpdating;
  String? get errorMessage => state.errorMessage;
  String? get actionMessage => state.actionMessage;
  OrderDetailModel? get selectedOrder => state.selectedOrder;

  List<OrderSummaryModel> get filteredOrders {
    final orders = state.orders;
    if (searchKeyword.trim().isEmpty) {
      return orders;
    }
    final query = searchKeyword.trim().toLowerCase();
    return orders.where((order) {
      return order.orderId.toLowerCase().contains(query) ||
          _statusLabel(order.status).toLowerCase().contains(query);
    }).toList(growable: false);
  }

  Future<void> load({String? initialOrderId}) async {
    update((current) => current.copyWith(
          isLoading: true,
          clearErrorMessage: true,
          clearActionMessage: true,
        ));

    try {
      final orders = await _checkoutRepository.getMyOrders();
      if (orders.isEmpty) {
        update((current) => current.copyWith(
              isLoading: false,
              orders: const [],
              selectedOrderIndex: 0,
              clearSelectedOrder: true,
            ));
        return;
      }

      var selectedIndex = 0;
      if (initialOrderId != null && initialOrderId.trim().isNotEmpty) {
        final matchedIndex = orders.indexWhere(
          (order) => order.orderId == initialOrderId.trim(),
        );
        if (matchedIndex >= 0) {
          selectedIndex = matchedIndex;
        }
      }

      update((current) => current.copyWith(
            orders: orders,
            selectedOrderIndex: selectedIndex,
          ));
      await _loadOrderDetail(orders[selectedIndex].orderId);
    } on ApiException catch (error) {
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: error.message,
            orders: const [],
            clearSelectedOrder: true,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: 'Không thể tải đơn hàng.',
            orders: const [],
            clearSelectedOrder: true,
          ));
    }
  }

  Future<void> confirmSelectedBankTransfer() async {
    final current = state.selectedOrder;
    if (current == null) {
      return;
    }
    await _runOrderAction(
      () => _checkoutRepository.confirmBankTransfer(current.orderId),
      successMessage: 'Đã xác nhận chuyển khoản.',
    );
  }

  Future<void> cancelSelectedOrder() async {
    final current = state.selectedOrder;
    if (current == null) {
      return;
    }
    await _runOrderAction(
      () => _checkoutRepository.cancelOrder(current.orderId),
      successMessage: 'Đơn hàng đã được hủy.',
    );
  }

  Future<void> requestRefundForSelectedOrder() async {
    final current = state.selectedOrder;
    if (current == null) {
      return;
    }
    await _runOrderAction(
      () => _checkoutRepository.requestRefund(current.orderId),
      successMessage: 'Đã gửi yêu cầu hoàn tiền.',
    );
  }

  Future<String?> fetchInvoiceHtmlForSelectedOrder() async {
    final current = state.selectedOrder;
    if (current == null) return null;
    try {
      return await _checkoutRepository.fetchInvoiceHtml(current.orderId);
    } catch (_) {
      return null;
    }
  }

  Future<void> selectOrderByFilteredIndex(int index) async {
    final list = filteredOrders;
    if (index < 0 || index >= list.length) {
      return;
    }
    final selectedId = list[index].orderId;
    final sourceIndex =
        state.orders.indexWhere((order) => order.orderId == selectedId);
    if (sourceIndex < 0) {
      return;
    }
    update((current) => current.copyWith(selectedOrderIndex: index));
    await _loadOrderDetail(state.orders[sourceIndex].orderId);
  }

  Future<void> setSearchKeyword(String value) async {
    final currentSelectedId = state.selectedOrder?.orderId;
    update((current) {
      return current.copyWith(
        searchKeyword: value,
        selectedOrderIndex: 0,
      );
    });

    final list = filteredOrders;
    if (list.isEmpty) {
      update((current) => current.copyWith(clearSelectedOrder: true));
      return;
    }

    if (currentSelectedId == null) {
      return;
    }

    final matchedIndex = list.indexWhere((order) => order.orderId == currentSelectedId);
    if (matchedIndex >= 0) {
      update((current) => current.copyWith(selectedOrderIndex: matchedIndex));
      return;
    }

    update((current) => current.copyWith(clearSelectedOrder: true));
  }

  Future<void> _loadOrderDetail(String orderId) async {
    final cached = _detailCache[orderId];
    if (cached != null) {
      update((current) => current.copyWith(
            isLoading: false,
            selectedOrder: cached,
            clearErrorMessage: true,
          ));
      return;
    }

    try {
      final detail = await _checkoutRepository.getOrderDetail(orderId);
      _detailCache[orderId] = detail;
      update((current) => current.copyWith(
            isLoading: false,
            selectedOrder: detail,
            clearErrorMessage: true,
          ));
    } on ApiException catch (error) {
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: error.message,
            clearSelectedOrder: true,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: 'Không thể tải chi tiết đơn hàng.',
            clearSelectedOrder: true,
          ));
    }
  }

  Future<void> _runOrderAction(
    Future<OrderDetailModel> Function() action, {
    required String successMessage,
  }) async {
    update((current) => current.copyWith(
          isUpdating: true,
          clearErrorMessage: true,
          clearActionMessage: true,
        ));
    try {
      final detail = await action();
      _detailCache[detail.orderId] = detail;
      final nextOrders = state.orders
          .map((order) => order.orderId == detail.orderId
              ? OrderSummaryModel(
                  orderId: detail.orderId,
                  status: detail.status,
                  paymentMethod: detail.paymentMethod,
                  paymentStatus: detail.paymentStatus,
                  itemCount: detail.itemCount,
                  subtotal: detail.subtotal,
                  discountAmount: detail.discountAmount,
                  deliveryFee: detail.deliveryFee,
                  total: detail.total,
                  createdAt: detail.createdAt,
                  voucherCode: detail.voucherCode,
                )
              : order)
          .toList(growable: false);
      update((current) => current.copyWith(
            isUpdating: false,
            orders: nextOrders,
            selectedOrder: detail,
            actionMessage: successMessage,
          ));
    } on ApiException catch (error) {
      update((current) => current.copyWith(
            isUpdating: false,
            errorMessage: error.message,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isUpdating: false,
            errorMessage: 'Không thể cập nhật trạng thái đơn hàng.',
          ));
    }
  }
}

bool _sameOrderSummaries(
  List<OrderSummaryModel> left,
  List<OrderSummaryModel> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.orderId != b.orderId ||
        a.status != b.status ||
        a.paymentMethod != b.paymentMethod ||
        a.paymentStatus != b.paymentStatus ||
        a.itemCount != b.itemCount ||
        a.subtotal != b.subtotal ||
        a.discountAmount != b.discountAmount ||
        a.deliveryFee != b.deliveryFee ||
        a.total != b.total ||
        a.createdAt != b.createdAt ||
        a.voucherCode != b.voucherCode) {
      return false;
    }
  }
  return true;
}

bool _sameOrderDetail(OrderDetailModel? left, OrderDetailModel? right) {
  if (identical(left, right)) {
    return true;
  }
  if (left == null || right == null) {
    return left == right;
  }
  if (left.orderId != right.orderId ||
      left.customerName != right.customerName ||
      left.customerEmail != right.customerEmail ||
      left.customerPhone != right.customerPhone ||
      left.customerAddress != right.customerAddress ||
      left.status != right.status ||
      left.paymentMethod != right.paymentMethod ||
      left.paymentStatus != right.paymentStatus ||
      left.itemCount != right.itemCount ||
      left.subtotal != right.subtotal ||
      left.discountAmount != right.discountAmount ||
      left.deliveryFee != right.deliveryFee ||
      left.total != right.total ||
      left.voucherCode != right.voucherCode ||
      left.createdAt != right.createdAt ||
      left.items.length != right.items.length) {
    return false;
  }
  for (var index = 0; index < left.items.length; index++) {
    final a = left.items[index];
    final b = right.items[index];
    if (a.productId != b.productId ||
        a.title != b.title ||
        a.priceValue != b.priceValue ||
        a.quantity != b.quantity ||
        a.lineTotal != b.lineTotal) {
      return false;
    }
  }
  return true;
}

String _statusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
      return 'đã thanh toán';
    case 'awaiting_transfer':
      return 'chờ chuyển khoản';
    case 'pending_cod':
      return 'chờ thu cod';
    case 'refund_pending':
      return 'chờ hoàn tiền';
    case 'refunded':
      return 'đã hoàn tiền';
    case 'completed':
    case 'delivered':
      return 'đã giao';
    case 'shipping':
      return 'đang giao';
    case 'processing':
      return 'đang xử lý';
    case 'pending':
      return 'chờ xử lý';
    case 'cancelled':
      return 'đã hủy';
    case 'failed':
      return 'thất bại';
    default:
      return status;
  }
}
