import '../../app/models/admin_models.dart';
import '../../app/models/checkout_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/admin_repository.dart';
import '../../app/repositories/checkout_repository.dart';
import '../../app/repositories/voucher_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

enum CheckoutEffect { login, success }

class CheckoutViewState {
  const CheckoutViewState({
    this.selectedPaymentMethod = CheckoutPaymentMethod.cod,
    this.isSubmitting = false,
    this.isValidating = false,
    this.submitMessage,
    this.isSubmitSuccess = false,
    this.lastOrder,
    this.appliedVoucherCode,
    this.previewDiscountAmount = 0,
    this.previewDeliveryFee = 0,
    this.previewTotal = 0,
    this.availableCustomers = const [],
    this.selectedCustomerId,
    this.selectedAddressIndex,
    this.validation,
  });

  final String selectedPaymentMethod;
  final bool isSubmitting;
  final bool isValidating;
  final String? submitMessage;
  final bool isSubmitSuccess;
  final CheckoutResult? lastOrder;
  final String? appliedVoucherCode;
  final int previewDiscountAmount;
  final int previewDeliveryFee;
  final int previewTotal;
  final List<AdminCustomerModel> availableCustomers;
  final String? selectedCustomerId;
  final int? selectedAddressIndex;
  final CheckoutValidationModel? validation;

  CheckoutViewState copyWith({
    String? selectedPaymentMethod,
    bool? isSubmitting,
    bool? isValidating,
    String? submitMessage,
    bool? isSubmitSuccess,
    CheckoutResult? lastOrder,
    String? appliedVoucherCode,
    int? previewDiscountAmount,
    int? previewDeliveryFee,
    int? previewTotal,
    List<AdminCustomerModel>? availableCustomers,
    String? selectedCustomerId,
    int? selectedAddressIndex,
    CheckoutValidationModel? validation,
    bool clearSubmitMessage = false,
    bool clearAppliedVoucher = false,
    bool clearSelectedCustomer = false,
    bool clearSelectedAddress = false,
    bool clearValidation = false,
  }) {
    return CheckoutViewState(
      selectedPaymentMethod:
          selectedPaymentMethod ?? this.selectedPaymentMethod,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isValidating: isValidating ?? this.isValidating,
      submitMessage:
          clearSubmitMessage ? null : (submitMessage ?? this.submitMessage),
      isSubmitSuccess: isSubmitSuccess ?? this.isSubmitSuccess,
      lastOrder: lastOrder ?? this.lastOrder,
      appliedVoucherCode: clearAppliedVoucher
          ? null
          : (appliedVoucherCode ?? this.appliedVoucherCode),
      previewDiscountAmount:
          previewDiscountAmount ?? this.previewDiscountAmount,
      previewDeliveryFee: previewDeliveryFee ?? this.previewDeliveryFee,
      previewTotal: previewTotal ?? this.previewTotal,
      availableCustomers: availableCustomers ?? this.availableCustomers,
      selectedCustomerId: clearSelectedCustomer
          ? null
          : (selectedCustomerId ?? this.selectedCustomerId),
      selectedAddressIndex: clearSelectedAddress
          ? null
          : (selectedAddressIndex ?? this.selectedAddressIndex),
      validation: clearValidation ? null : (validation ?? this.validation),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CheckoutViewState &&
        other.selectedPaymentMethod == selectedPaymentMethod &&
        other.isSubmitting == isSubmitting &&
        other.isValidating == isValidating &&
        other.submitMessage == submitMessage &&
        other.isSubmitSuccess == isSubmitSuccess &&
        other.lastOrder == lastOrder &&
        other.appliedVoucherCode == appliedVoucherCode &&
        other.previewDiscountAmount == previewDiscountAmount &&
        other.previewDeliveryFee == previewDeliveryFee &&
        other.previewTotal == previewTotal &&
        _sameCustomers(other.availableCustomers, availableCustomers) &&
        other.selectedCustomerId == selectedCustomerId &&
        other.selectedAddressIndex == selectedAddressIndex &&
        other.validation == validation;
  }

  @override
  int get hashCode => Object.hash(
        selectedPaymentMethod,
        isSubmitting,
        isValidating,
        submitMessage,
        isSubmitSuccess,
        lastOrder,
        appliedVoucherCode,
        previewDiscountAmount,
        previewDeliveryFee,
        previewTotal,
        Object.hashAll(availableCustomers),
        selectedCustomerId,
        selectedAddressIndex,
        validation,
      );
}

class CheckoutState extends ScreenController<CheckoutViewState, CheckoutEffect> {
  CheckoutState({
    CheckoutRepository? repository,
    VoucherRepository? voucherRepository,
    AdminRepository? adminRepository,
  })  : _repository = repository ?? AppServices.instance.checkoutRepository,
        _voucherRepository =
            voucherRepository ?? AppServices.instance.voucherRepository,
        _adminRepository = adminRepository ?? AppServices.instance.adminRepository,
        super(const CheckoutViewState());

  final CheckoutRepository _repository;
  final VoucherRepository _voucherRepository;
  final AdminRepository _adminRepository;

  // Extra order fields set directly by UI controllers (no rebuild needed)
  String? orderNote;
  String? deliveryDate;
  String? deliveryTimeSlot;
  int pointsToUse = 0;

  int get userPoints => AppServices.instance.authSession.currentUser?.points ?? 0;

  String get selectedPaymentMethod => state.selectedPaymentMethod;
  bool get isSubmitting => state.isSubmitting;
  bool get isValidating => state.isValidating;
  String? get submitMessage => state.submitMessage;
  bool get isSubmitSuccess => state.isSubmitSuccess;
  CheckoutResult? get lastOrder => state.lastOrder;
  String? get appliedVoucherCode => state.appliedVoucherCode;
  int get subtotal => AppServices.instance.cartSession.subtotal;
  int get previewDiscountAmount => state.previewDiscountAmount;
  int get previewTotal =>
      state.previewTotal == 0 && subtotal == 0 ? 0 : state.previewTotal;
  int get previewDeliveryFee => state.previewDeliveryFee;
  List<AdminCustomerModel> get availableCustomers => state.availableCustomers;
  String? get selectedCustomerId => state.selectedCustomerId;
  CheckoutValidationModel? get validation => state.validation;
  BankTransferInfoModel? get bankTransferInfo =>
      state.validation?.bankTransferInfo ?? state.lastOrder?.bankTransferInfo;
  bool get isAdmin => AppServices.instance.authSession.currentUser?.isAdmin == true;
  AdminCustomerModel? get selectedCustomer {
    if (!isAdmin) {
      return null;
    }
    final selectedId = state.selectedCustomerId;
    if (selectedId == null) {
      return null;
    }
    for (final customer in state.availableCustomers) {
      if (customer.id == selectedId) {
        return customer;
      }
    }
    return null;
  }

  String get displayName => selectedCustomer?.fullName ??
      AppServices.instance.authSession.currentUser?.fullName ??
      'Khách vãng lai';
  String get displayPhone => selectedCustomer?.phone ??
      AppServices.instance.authSession.currentUser?.phone ??
      '0901 234 567';

  List<String> get userAddresses {
    if (isAdmin) return const [];
    return AppServices.instance.authSession.currentUser?.addresses ?? const [];
  }

  String get displayAddress {
    if (isAdmin) {
      return selectedCustomer?.address ?? 'Chưa có địa chỉ mặc định';
    }
    final addresses = userAddresses;
    if (addresses.isEmpty) {
      return AppServices.instance.authSession.currentUser?.address ??
          'Chưa có địa chỉ mặc định';
    }
    final idx = state.selectedAddressIndex;
    if (idx != null && idx >= 0 && idx < addresses.length) {
      return addresses[idx];
    }
    return addresses.first;
  }

  int? get selectedAddressIndex => state.selectedAddressIndex;

  void selectAddress(int? index) {
    update((current) => current.copyWith(selectedAddressIndex: index));
  }

  Future<void> initialize() async {
    if (isAdmin && state.availableCustomers.isEmpty) {
      try {
        final customers = await _adminRepository.fetchCustomers();
        final filtered =
            customers.where((item) => !item.isAdmin).toList(growable: false);
        update((current) => current.copyWith(
              availableCustomers: filtered,
              selectedCustomerId: filtered.isEmpty ? null : filtered.first.id,
            ));
      } catch (_) {
        update((current) => current.copyWith(
              submitMessage: 'Không thể tải danh sách khách hàng.',
              isSubmitSuccess: false,
            ));
      }
    }
    _resetPreview();
  }

  void _resetPreview() {
    update((current) => current.copyWith(
          previewDiscountAmount: 0,
          previewDeliveryFee: deliveryFee,
          previewTotal: subtotal + deliveryFee,
        ));
  }

  void selectCustomer(String? customerId) {
    update((current) => current.copyWith(
          selectedCustomerId: customerId,
          clearAppliedVoucher: true,
          clearValidation: true,
          previewDiscountAmount: 0,
          previewDeliveryFee: deliveryFee,
          previewTotal: subtotal + deliveryFee,
        ));
  }

  int get deliveryFee =>
      AppServices.instance.cartSession.items.isEmpty ? 0 : 20000;

  void selectPaymentMethod(String paymentMethod) {
    update((current) => current.copyWith(
          selectedPaymentMethod: paymentMethod,
          clearValidation: true,
        ));
    _resetPreview();
  }

  Future<void> applyVoucherCode(String rawCode) async {
    final authSession = AppServices.instance.authSession;
    final code = rawCode.trim().toUpperCase();
    if (!authSession.isAuthenticated) {
      update((current) => current.copyWith(
            submitMessage: 'Vui lòng đăng nhập để áp dụng voucher.',
            isSubmitSuccess: false,
          ));
      emit(CheckoutEffect.login);
      return;
    }
    if (code.isEmpty) {
      update((current) => current.copyWith(
            submitMessage: 'Vui lòng nhập mã voucher.',
            isSubmitSuccess: false,
          ));
      return;
    }
    if (isAdmin && (selectedCustomerId == null || selectedCustomer == null)) {
      update((current) => current.copyWith(
            submitMessage: 'Vui lòng chọn khách hàng trước khi áp dụng voucher.',
            isSubmitSuccess: false,
          ));
      return;
    }

    try {
      final result = await _voucherRepository.validateVoucher(
        code: code,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        customerUserId: isAdmin ? selectedCustomerId : null,
      );
      update((current) => current.copyWith(
            appliedVoucherCode: result.code,
            submitMessage: result.message,
            isSubmitSuccess: true,
            previewDiscountAmount: result.discountAmount,
            previewDeliveryFee: result.deliveryFeeAfterDiscount,
            previewTotal: result.totalAfterDiscount,
          ));
      await validateBeforeSubmit(showSuccessMessage: false);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        authSession.clear();
        update((current) => current.copyWith(
              submitMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              isSubmitSuccess: false,
            ));
        emit(CheckoutEffect.login);
        return;
      }
      update((current) => current.copyWith(
            submitMessage: error.message,
            isSubmitSuccess: false,
            previewDiscountAmount: 0,
            previewDeliveryFee: deliveryFee,
            previewTotal: subtotal + deliveryFee,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            submitMessage: 'Không thể kiểm tra voucher lúc này.',
            isSubmitSuccess: false,
          ));
    }
  }

  Future<CheckoutValidationModel?> validateBeforeSubmit({
    bool showSuccessMessage = true,
  }) async {
    final authSession = AppServices.instance.authSession;
    final cartSession = AppServices.instance.cartSession;
    final address = displayAddress.trim();

    if (!authSession.isAuthenticated) {
      update((current) => current.copyWith(
            submitMessage: 'Vui lòng đăng nhập trước khi thanh toán.',
            isSubmitSuccess: false,
          ));
      emit(CheckoutEffect.login);
      return null;
    }
    if (cartSession.items.isEmpty) {
      update((current) => current.copyWith(
            submitMessage: 'Giỏ hàng đang trống.',
            isSubmitSuccess: false,
          ));
      return null;
    }
    if (isAdmin && (selectedCustomerId == null || selectedCustomer == null)) {
      update((current) => current.copyWith(
            submitMessage: 'Vui lòng chọn khách hàng để tạo đơn.',
            isSubmitSuccess: false,
          ));
      return null;
    }
    if (address.isEmpty) {
      update((current) => current.copyWith(
            submitMessage:
                'Vui lòng cập nhật địa chỉ nhận hàng trước khi thanh toán.',
            isSubmitSuccess: false,
          ));
      return null;
    }
    if (address.length < 5) {
      update((current) => current.copyWith(
            submitMessage: 'Địa chỉ nhận hàng chưa hợp lệ.',
            isSubmitSuccess: false,
          ));
      return null;
    }

    update((current) => current.copyWith(
          isValidating: true,
          clearSubmitMessage: !showSuccessMessage,
        ));
    try {
      final result = await _repository.validateCheckout(
        CheckoutRequestModel(
          paymentMethod: selectedPaymentMethod,
          deliveryFee: deliveryFee,
          items: cartSession.items,
          voucherCode: appliedVoucherCode,
          customerUserId: isAdmin ? selectedCustomerId : null,
        ),
      );
      update((current) => current.copyWith(
            isValidating: false,
            validation: result,
            submitMessage: showSuccessMessage ? result.message : current.submitMessage,
            isSubmitSuccess: result.canCheckout,
            previewDiscountAmount: result.discountAmount,
            previewDeliveryFee: result.deliveryFee,
            previewTotal: result.total,
          ));
      return result;
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        authSession.clear();
        update((current) => current.copyWith(
              isValidating: false,
              submitMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              isSubmitSuccess: false,
            ));
        emit(CheckoutEffect.login);
        return null;
      }
      update((current) => current.copyWith(
            isValidating: false,
            submitMessage: error.message,
            isSubmitSuccess: false,
            clearValidation: true,
          ));
      return null;
    } catch (_) {
      update((current) => current.copyWith(
            isValidating: false,
            submitMessage: 'Không thể kiểm tra tồn kho và thanh toán lúc này.',
            isSubmitSuccess: false,
            clearValidation: true,
          ));
      return null;
    }
  }

  Future<void> submitOrder() async {
    if (state.isSubmitting) {
      return;
    }

    final validationResult = await validateBeforeSubmit();
    if (validationResult == null || !validationResult.canCheckout) {
      return;
    }

    final authSession = AppServices.instance.authSession;
    final cartSession = AppServices.instance.cartSession;

    update((current) => current.copyWith(
          isSubmitting: true,
          clearSubmitMessage: true,
          isSubmitSuccess: false,
        ));

    try {
      final result = await _repository.placeOrder(
        CheckoutRequestModel(
          paymentMethod: selectedPaymentMethod,
          deliveryFee: deliveryFee,
          items: cartSession.items,
          voucherCode: appliedVoucherCode,
          customerUserId: isAdmin ? selectedCustomerId : null,
          orderNote: orderNote?.trim().isEmpty == true ? null : orderNote?.trim(),
          deliveryDate: deliveryDate?.trim().isEmpty == true ? null : deliveryDate?.trim(),
          deliveryTimeSlot: deliveryTimeSlot,
          pointsToUse: pointsToUse,
        ),
      );
      await cartSession.replaceAll(const []);
      if (authSession.isAuthenticated) {
        await cartSession.syncRemoteSnapshot();
      }
      update((current) => current.copyWith(
            isSubmitting: false,
            submitMessage: result.message,
            isSubmitSuccess: true,
            lastOrder: result,
            clearAppliedVoucher: true,
            previewDiscountAmount: 0,
            previewDeliveryFee: 0,
            previewTotal: 0,
            clearValidation: true,
          ));
      emit(CheckoutEffect.success);
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        authSession.clear();
        update((current) => current.copyWith(
              isSubmitting: false,
              submitMessage: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
              isSubmitSuccess: false,
            ));
        emit(CheckoutEffect.login);
        return;
      }
      update((current) => current.copyWith(
            isSubmitting: false,
            submitMessage: error.message,
            isSubmitSuccess: false,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isSubmitting: false,
            submitMessage: 'Không thể thanh toán lúc này.',
            isSubmitSuccess: false,
          ));
    }
  }
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
