import '../../app/models/auth_models.dart';
import '../../app/models/checkout_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/auth_repository.dart';
import '../../app/repositories/checkout_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

enum ProfileEffect { login }

class ProfileViewState {
  const ProfileViewState({
    this.selectedTabIndex = 0,
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.addressMessage,
    this.passwordMessage,
    this.isAddressSuccess = false,
    this.isPasswordSuccess = false,
    this.isUpdatingAddress = false,
    this.isUpdatingPassword = false,
    this.orders = const [],
  });

  final int selectedTabIndex;
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;
  final String? addressMessage;
  final String? passwordMessage;
  final bool isAddressSuccess;
  final bool isPasswordSuccess;
  final bool isUpdatingAddress;
  final bool isUpdatingPassword;
  final List<OrderSummaryModel> orders;

  ProfileViewState copyWith({
    int? selectedTabIndex,
    AuthUser? user,
    bool? isLoading,
    String? errorMessage,
    String? addressMessage,
    String? passwordMessage,
    bool? isAddressSuccess,
    bool? isPasswordSuccess,
    bool? isUpdatingAddress,
    bool? isUpdatingPassword,
    List<OrderSummaryModel>? orders,
    bool clearErrorMessage = false,
    bool clearAddressMessage = false,
    bool clearPasswordMessage = false,
  }) {
    return ProfileViewState(
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      addressMessage:
          clearAddressMessage ? null : (addressMessage ?? this.addressMessage),
      passwordMessage:
          clearPasswordMessage
              ? null
              : (passwordMessage ?? this.passwordMessage),
      isAddressSuccess: isAddressSuccess ?? this.isAddressSuccess,
      isPasswordSuccess: isPasswordSuccess ?? this.isPasswordSuccess,
      isUpdatingAddress: isUpdatingAddress ?? this.isUpdatingAddress,
      isUpdatingPassword: isUpdatingPassword ?? this.isUpdatingPassword,
      orders: orders ?? this.orders,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProfileViewState &&
        other.selectedTabIndex == selectedTabIndex &&
        other.user == user &&
        other.isLoading == isLoading &&
        other.errorMessage == errorMessage &&
        other.addressMessage == addressMessage &&
        other.passwordMessage == passwordMessage &&
        other.isAddressSuccess == isAddressSuccess &&
        other.isPasswordSuccess == isPasswordSuccess &&
        other.isUpdatingAddress == isUpdatingAddress &&
        other.isUpdatingPassword == isUpdatingPassword &&
        _sameOrders(other.orders, orders);
  }

  @override
  int get hashCode =>
      Object.hash(
        selectedTabIndex,
        user,
        isLoading,
        errorMessage,
        addressMessage,
        passwordMessage,
        isAddressSuccess,
        isPasswordSuccess,
        isUpdatingAddress,
        isUpdatingPassword,
        Object.hashAll(orders),
      );
}

class ProfileState extends ScreenController<ProfileViewState, ProfileEffect> {
  ProfileState({
    AuthRepository? authRepository,
    CheckoutRepository? checkoutRepository,
  })  : _authRepository = authRepository ?? AppServices.instance.authRepository,
        _checkoutRepository =
            checkoutRepository ?? AppServices.instance.checkoutRepository,
        super(
          ProfileViewState(
            user: AppServices.instance.authSession.currentUser,
          ),
        );

  final AuthRepository _authRepository;
  final CheckoutRepository _checkoutRepository;
  bool _hasLoaded = false;

  int get selectedTabIndex => state.selectedTabIndex;
  AuthUser? get user => state.user;
  bool get isLoading => state.isLoading;
  String? get errorMessage => state.errorMessage;
  String? get addressMessage => state.addressMessage;
  String? get passwordMessage => state.passwordMessage;
  bool get isAddressSuccess => state.isAddressSuccess;
  bool get isPasswordSuccess => state.isPasswordSuccess;
  bool get isUpdatingAddress => state.isUpdatingAddress;
  bool get isUpdatingPassword => state.isUpdatingPassword;
  List<OrderSummaryModel> get orders => state.orders;

  Future<void> load() async {
    if (_hasLoaded || !AppServices.instance.authSession.isAuthenticated) {
      return;
    }
    _hasLoaded = true;

    update((current) => current.copyWith(
          isLoading: true,
          clearErrorMessage: true,
        ));

    try {
      final user = await _authRepository.fetchMe();
      final orders = await _checkoutRepository.getMyOrders();
      update((current) => current.copyWith(
            user: user,
            orders: orders,
            isLoading: false,
            clearErrorMessage: true,
            clearAddressMessage: true,
            clearPasswordMessage: true,
          ));
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        AppServices.instance.authSession.clear();
        emit(ProfileEffect.login);
      }
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: error.message,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isLoading: false,
            errorMessage: 'Không thể tải thông tin hồ sơ.',
          ));
    }
  }

  void selectTab(int index) {
    update((current) => current.copyWith(selectedTabIndex: index));
  }

  void logout() {
    AppServices.instance.authSession.clear();
    emit(ProfileEffect.login);
  }

  Future<void> updateAddress(String rawAddress) async {
    final address = rawAddress.trim();
    if (address.isEmpty) {
      update((current) => current.copyWith(
            addressMessage: 'Vui lòng nhập địa chỉ.',
            isAddressSuccess: false,
            clearPasswordMessage: true,
          ));
      return;
    }

    if (address.length < 5) {
      update((current) => current.copyWith(
            addressMessage: 'Địa chỉ phải có ít nhất 5 ký tự.',
            isAddressSuccess: false,
            clearPasswordMessage: true,
          ));
      return;
    }

    if (state.isUpdatingAddress) {
      return;
    }

    update((current) => current.copyWith(
          isUpdatingAddress: true,
          clearAddressMessage: true,
          isAddressSuccess: false,
        ));

    try {
      final user = await _authRepository.updateAddress(address);
      update((current) => current.copyWith(
            user: user,
            isUpdatingAddress: false,
            addressMessage: 'Cập nhật địa chỉ thành công.',
            isAddressSuccess: true,
          ));
    } on ApiException catch (error) {
      _handleAuthError(error);
      update((current) => current.copyWith(
            isUpdatingAddress: false,
            addressMessage: error.message,
            isAddressSuccess: false,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isUpdatingAddress: false,
            addressMessage: 'Không thể cập nhật địa chỉ.',
            isAddressSuccess: false,
          ));
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      update((current) => current.copyWith(
            passwordMessage: 'Vui lòng nhập đầy đủ thông tin mật khẩu.',
            isPasswordSuccess: false,
          ));
      return;
    }

    if (newPassword.length < 6) {
      update((current) => current.copyWith(
            passwordMessage: 'Mật khẩu mới phải có ít nhất 6 ký tự.',
            isPasswordSuccess: false,
          ));
      return;
    }

    if (newPassword != confirmPassword) {
      update((current) => current.copyWith(
            passwordMessage: 'Mật khẩu nhập lại không khớp.',
            isPasswordSuccess: false,
          ));
      return;
    }

    if (state.isUpdatingPassword) {
      return;
    }

    update((current) => current.copyWith(
          isUpdatingPassword: true,
          clearPasswordMessage: true,
          isPasswordSuccess: false,
        ));

    try {
      final message = await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      update((current) => current.copyWith(
            isUpdatingPassword: false,
            passwordMessage: message,
            isPasswordSuccess: true,
          ));
    } on ApiException catch (error) {
      _handleAuthError(error);
      update((current) => current.copyWith(
            isUpdatingPassword: false,
            passwordMessage: error.message,
            isPasswordSuccess: false,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isUpdatingPassword: false,
            passwordMessage: 'Không thể cập nhật mật khẩu.',
            isPasswordSuccess: false,
          ));
    }
  }

  void _handleAuthError(ApiException error) {
    if (error.isUnauthorized) {
      AppServices.instance.authSession.clear();
      emit(ProfileEffect.login);
    }
  }
}

bool _sameOrders(
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
    final leftOrder = left[index];
    final rightOrder = right[index];
    if (leftOrder.orderId != rightOrder.orderId ||
        leftOrder.status != rightOrder.status ||
        leftOrder.paymentMethod != rightOrder.paymentMethod ||
        leftOrder.itemCount != rightOrder.itemCount ||
        leftOrder.subtotal != rightOrder.subtotal ||
        leftOrder.discountAmount != rightOrder.discountAmount ||
        leftOrder.deliveryFee != rightOrder.deliveryFee ||
        leftOrder.total != rightOrder.total ||
        leftOrder.createdAt != rightOrder.createdAt ||
        leftOrder.voucherCode != rightOrder.voucherCode) {
      return false;
    }
  }
  return true;
}
