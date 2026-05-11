import '../../app/models/voucher_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/voucher_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

enum VoucherEffect { login }

class VoucherViewState {
  const VoucherViewState({
    this.vouchers = defaultVouchers,
    this.selectedVoucherIndex = 0,
    this.isLoading = false,
    this.isSubmitting = false,
    this.message,
    this.isSuccess = false,
  });

  final List<VoucherModel> vouchers;
  final int selectedVoucherIndex;
  final bool isLoading;
  final bool isSubmitting;
  final String? message;
  final bool isSuccess;

  VoucherViewState copyWith({
    List<VoucherModel>? vouchers,
    int? selectedVoucherIndex,
    bool? isLoading,
    bool? isSubmitting,
    String? message,
    bool? isSuccess,
    bool clearMessage = false,
  }) {
    return VoucherViewState(
      vouchers: vouchers ?? this.vouchers,
      selectedVoucherIndex: selectedVoucherIndex ?? this.selectedVoucherIndex,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      message: clearMessage ? null : (message ?? this.message),
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VoucherViewState &&
        other.vouchers == vouchers &&
        other.selectedVoucherIndex == selectedVoucherIndex &&
        other.isLoading == isLoading &&
        other.isSubmitting == isSubmitting &&
        other.message == message &&
        other.isSuccess == isSuccess;
  }

  @override
  int get hashCode => Object.hash(
        vouchers,
        selectedVoucherIndex,
        isLoading,
        isSubmitting,
        message,
        isSuccess,
      );
}

class VoucherState extends ScreenController<VoucherViewState, VoucherEffect> {
  VoucherState({
    VoucherRepository? repository,
  })  : _repository = repository ?? AppServices.instance.voucherRepository,
        super(const VoucherViewState());

  final VoucherRepository _repository;
  bool _hasLoaded = false;

  List<VoucherModel> get vouchers => state.vouchers;
  int get selectedVoucherIndex => state.selectedVoucherIndex;
  bool get isLoading => state.isLoading;
  bool get isSubmitting => state.isSubmitting;
  String? get message => state.message;
  bool get isSuccess => state.isSuccess;

  Future<void> load() async {
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;

    update((current) => current.copyWith(isLoading: true, clearMessage: true));
    try {
      final vouchers = await _repository.fetchVouchers();
      update((current) => current.copyWith(
            vouchers: vouchers,
            isLoading: false,
            selectedVoucherIndex: _safeIndex(
              current.selectedVoucherIndex,
              vouchers.length,
            ),
            clearMessage: true,
          ));
    } catch (_) {
      _hasLoaded = false;
      update((current) => current.copyWith(
            isLoading: false,
            message: 'Không thể tải danh sách voucher.',
            isSuccess: false,
          ));
    }
  }

  void selectVoucher(int index) {
    if (index < 0 || index >= vouchers.length) {
      return;
    }
    update((current) => current.copyWith(selectedVoucherIndex: index));
  }

  Future<void> collectSelectedVoucher() async {
    if (vouchers.isEmpty) {
      return;
    }
    if (!AppServices.instance.authSession.isAuthenticated) {
      update((current) => current.copyWith(
            message: 'Vui lòng đăng nhập để thu thập voucher.',
            isSuccess: false,
          ));
      emit(VoucherEffect.login);
      return;
    }
    if (state.isSubmitting) {
      return;
    }

    final voucher = vouchers[selectedVoucherIndex];
    if (voucher.used) {
      update((current) => current.copyWith(
            message: 'Voucher này đã được sử dụng.',
            isSuccess: false,
          ));
      return;
    }
    if (voucher.collected) {
      update((current) => current.copyWith(
            message: 'Voucher này đã được thu thập.',
            isSuccess: true,
          ));
      return;
    }

    update((current) => current.copyWith(
          isSubmitting: true,
          clearMessage: true,
          isSuccess: false,
        ));

    try {
      final message = await _repository.collectVoucher(voucher.code);
      final updated = List<VoucherModel>.from(vouchers);
      updated[selectedVoucherIndex] = voucher.copyWith(collected: true);
      update((current) => current.copyWith(
            vouchers: updated,
            isSubmitting: false,
            message: message,
            isSuccess: true,
          ));
    } on ApiException catch (error) {
      if (error.isUnauthorized) {
        AppServices.instance.authSession.clear();
        emit(VoucherEffect.login);
      }
      update((current) => current.copyWith(
            isSubmitting: false,
            message: error.message,
            isSuccess: false,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isSubmitting: false,
            message: 'Không thể thu thập voucher.',
            isSuccess: false,
          ));
    }
  }

  int _safeIndex(int currentIndex, int length) {
    if (length <= 0) {
      return 0;
    }
    if (currentIndex < 0) {
      return 0;
    }
    if (currentIndex >= length) {
      return length - 1;
    }
    return currentIndex;
  }
}
