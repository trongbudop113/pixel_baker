import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/admin_models.dart';
import '../../app/models/cart_models.dart';
import '../../app/models/checkout_models.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';
import '../shared/pixel_footer.dart';
import 'checkout_state.dart';

class CheckoutColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
  static const white = Color(0xFFFFFFFF);
  static const lightGray = Color(0xFFF8F8F8);
  static const softBlue = Color(0xFFEAF3FF);
}

Widget _checkoutSummaryThumbnail(String imageUrl, double size) => ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          border: Border.all(color: const Color(0xFFD7DEE8), width: 1.5),
        ),
        child: imageUrl.trim().isEmpty
            ? const Icon(
                Icons.cake_outlined,
                color: CheckoutColors.gray,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.cake_outlined,
                  color: CheckoutColors.gray,
                ),
              ),
      ),
    );

bool _isBoxStyledCheckoutItem(CartItem item) {
  final category = item.category.toLowerCase();
  return item.boxItems.isNotEmpty ||
      category.contains('trung thu') ||
      category.contains('mooncake') ||
      category.contains('pía') ||
      category.contains('pia');
}

int _calculateCheckoutBoxPackagePrice(CartItem item) {
  final childrenTotal = item.boxItems.fold<int>(
    0,
    (sum, entry) => sum + entry.priceValue,
  );
  final packagePrice = item.priceValue - childrenTotal;
  return packagePrice < 0 ? 0 : packagePrice;
}

Widget _checkoutQuantityActions(
  CartItem item, {
  bool compact = false,
}) {
  final cartSession = AppServices.instance.cartSession;
  final iconSize = compact ? 16.0 : 18.0;
  final height = compact ? 30.0 : 34.0;
  final fontSize = compact ? 11.0 : 12.0;
  return Row(
    children: [
      _checkoutQuantityButton(
        icon: Icons.remove_rounded,
        onTap: item.quantity > 1 ? () => cartSession.decrementItem(item) : null,
        size: height,
        iconSize: iconSize,
      ),
      Container(
        width: compact ? 34 : 40,
        height: height,
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: CheckoutColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD7DEE8), width: 1.5),
        ),
        child: Text(
          '${item.quantity}',
          style: TextStyle(
            color: CheckoutColors.blue,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      _checkoutQuantityButton(
        icon: Icons.add_rounded,
        onTap: () => cartSession.incrementItem(item),
        size: height,
        iconSize: iconSize,
      ),
      const SizedBox(width: 8),
      TextButton.icon(
        onPressed: () => cartSession.removeItem(item),
        style: TextButton.styleFrom(
          minimumSize: Size(0, height),
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10),
          foregroundColor: CheckoutColors.red,
        ),
        icon: Icon(Icons.delete_outline_rounded, size: iconSize),
        label: Text(
          'Xóa',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

Widget _checkoutQuantityButton({
  required IconData icon,
  required VoidCallback? onTap,
  required double size,
  required double iconSize,
}) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: onTap == null ? const Color(0xFFF3F4F6) : CheckoutColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD7DEE8), width: 1.5),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: onTap == null ? const Color(0xFFB6BDC8) : CheckoutColors.blue,
        ),
      ),
    );

class ResponsiveCheckoutScreen extends StatefulWidget {
  const ResponsiveCheckoutScreen({super.key, this.showTopHeader = true});

  final bool showTopHeader;

  @override
  State<ResponsiveCheckoutScreen> createState() => _ResponsiveCheckoutScreenState();
}

class _ResponsiveCheckoutScreenState extends State<ResponsiveCheckoutScreen> {
  final CheckoutState _state = CheckoutState();
  final TextEditingController _voucherController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _deliveryDateController = TextEditingController();
  final CheckoutCustomerDropdownController _customerDropdownController =
      CheckoutCustomerDropdownController();

  @override
  void initState() {
    super.initState();
    _state.initialize();
    _syncCustomerDropdown();
    _state.addListener(_syncCustomerDropdown);
    _noteController.addListener(() {
      _state.orderNote = _noteController.text;
    });
    _deliveryDateController.addListener(() {
      _state.deliveryDate = _deliveryDateController.text;
    });
  }

  void _syncCustomerDropdown() {
    _customerDropdownController.setOptions(
      _state.availableCustomers,
      selectedId: _state.selectedCustomerId,
    );
  }

  @override
  void dispose() {
    _state.removeListener(_syncCustomerDropdown);
    _customerDropdownController.dispose();
    _voucherController.dispose();
    _noteController.dispose();
    _deliveryDateController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerEffectListener<CheckoutState, CheckoutEffect>(
      controller: _state,
      listener: (context, effect) {
        if (effect == CheckoutEffect.login) {
          context.goNamed(AppRouteNames.login);
          return;
        }
        if (effect == CheckoutEffect.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_state.submitMessage ?? 'Thanh toán thành công.'),
            ),
          );
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return isMobile
              ? MobileCheckoutLayout(
                  state: _state,
                  voucherController: _voucherController,
                  noteController: _noteController,
                  deliveryDateController: _deliveryDateController,
                  customerDropdownController: _customerDropdownController,
                  showTopHeader: widget.showTopHeader)
              : WebCheckoutLayout(
                  state: _state,
                  voucherController: _voucherController,
                  noteController: _noteController,
                  deliveryDateController: _deliveryDateController,
                  customerDropdownController: _customerDropdownController,
                  showTopHeader: widget.showTopHeader);
        },
      ),
    );
  }
}

class WebCheckoutLayout extends StatefulWidget {
  const WebCheckoutLayout({
    super.key,
    required this.state,
    required this.voucherController,
    required this.noteController,
    required this.deliveryDateController,
    required this.customerDropdownController,
    this.showTopHeader = true,
  });

  final CheckoutState state;
  final TextEditingController voucherController;
  final TextEditingController noteController;
  final TextEditingController deliveryDateController;
  final CheckoutCustomerDropdownController customerDropdownController;
  final bool showTopHeader;

  @override
  State<WebCheckoutLayout> createState() => _WebCheckoutLayoutState();
}

class _WebCheckoutLayoutState extends State<WebCheckoutLayout> {
  String? _selectedTimeSlot;

  CheckoutState get state => widget.state;
  TextEditingController get voucherController => widget.voucherController;
  CheckoutCustomerDropdownController get customerDropdownController =>
      widget.customerDropdownController;
  bool get showTopHeader => widget.showTopHeader;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        state,
        AppServices.instance.cartSession,
        AppServices.instance.authSession,
      ]),
      builder: (context, _) => SizedBox(
        width: 1200,
        height: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: _screenBox(context),
          child: Column(
            children: [
              if (showTopHeader) _webTopHeader(context),
              if (showTopHeader) const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _webLeft(context)),
                        const SizedBox(width: 20),
                        Expanded(child: _webRight()),
                      ],
                    ),
                    if (state.submitMessage != null) ...[
                      const SizedBox(height: 12),
                      _submitBanner(),
                    ],
                    const SizedBox(height: 20),
                    const PixelFooter(label: 'PIXEL BAKERY | THANH TOÁN'),
                  ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _webTopHeader(BuildContext context) => Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: _gradientBox(),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.goNamed(AppRouteNames.home),
              child: _txt('PIXEL BAKERY', CheckoutColors.red, 18, FontWeight.w900),
            ),
            const Spacer(),
            _txt('Thanh toán an toàn', CheckoutColors.blue, 14, FontWeight.w700),
          ],
        ),
      );

  Widget _webLeft(BuildContext context) => Column(
        children: [
          _card(
            title: 'Thông tin khách hàng',
            child: Column(
              children: [
                if (state.isAdmin) ...[
                  _txt('Chọn khách hàng', CheckoutColors.gray, 12, FontWeight.w700),
                  const SizedBox(height: 4),
                  CheckoutCustomerDropdown(
                    controller: customerDropdownController,
                    hintText: 'Chọn khách hàng để tạo đơn',
                    height: 42,
                    fontSize: 13,
                    onChanged: state.selectCustomer,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _labeledInput(
                        'Họ và tên',
                        state.displayName,
                        42,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _labeledInput(
                        'Số điện thoại',
                        state.displayPhone,
                        42,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _addressField(state, 42, 14),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Phương thức giao hàng',
            child: _pickRow('Giao tiêu chuẩn (2h)', '20.000đ', true),
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Phương thức thanh toán',
            child: AnimatedBuilder(
              animation: state,
              builder: (context, _) => Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        state.selectPaymentMethod(CheckoutPaymentMethod.cod),
                    child: _paymentRow(
                      'Thanh toán khi nhận hàng (COD)',
                      state.selectedPaymentMethod == CheckoutPaymentMethod.cod,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => state
                        .selectPaymentMethod(CheckoutPaymentMethod.bankTransfer),
                    child: _paymentRow(
                      'Chuyển khoản ngân hàng',
                      state.selectedPaymentMethod ==
                          CheckoutPaymentMethod.bankTransfer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Thông tin giao hàng',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _txt('Ghi chú đơn hàng', CheckoutColors.gray, 12, FontWeight.w700),
                const SizedBox(height: 4),
                _editableTextArea(
                  controller: widget.noteController,
                  hintText: 'Ghi chú cho người giao hàng...',
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _txt('Ngày giao hàng', CheckoutColors.gray, 12, FontWeight.w700),
                          const SizedBox(height: 4),
                          _editableTextField(
                            controller: widget.deliveryDateController,
                            hintText: 'dd/mm/yyyy',
                            height: 42,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _txt('Khung giờ', CheckoutColors.gray, 12, FontWeight.w700),
                          const SizedBox(height: 4),
                          _timeSlotDropdown(
                            value: _selectedTimeSlot,
                            height: 42,
                            fontSize: 13,
                            onChanged: (v) {
                              setState(() => _selectedTimeSlot = v);
                              state.deliveryTimeSlot = v;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _webRight() => Column(
        children: [
          _card(
            title: 'Tóm tắt đơn hàng',
            child: _summaryContent(),
          ),
          const SizedBox(height: 12),
          _card(
            title: 'Mã giảm giá',
            child: Row(
              children: [
                Expanded(
                  child: _voucherInput(voucherController, 42, 13),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async =>
                      state.applyVoucherCode(voucherController.text),
                  child: _solidButton('Áp dụng', CheckoutColors.blue, 110, 42, 13),
                ),
              ],
            ),
          ),
          if (state.userPoints > 0) ...[
            const SizedBox(height: 12),
            _LoyaltyPointsCard(state: state),
          ],
          if (state.bankTransferInfo != null) ...[
            const SizedBox(height: 12),
            _card(
              title: 'Thông tin chuyển khoản',
              child: _bankTransferInfoBox(state.bankTransferInfo!),
            ),
          ],
          const SizedBox(height: 12),
          _cta(
            'THANH TOÁN NGAY',
            52,
            16,
            onTap: state.submitOrder,
            isLoading: state.isSubmitting,
          ),
          const SizedBox(height: 12),
          _policy(
            titleSize: 14,
            bodySize: 12,
            lines: const [
              '• Liên hệ: 0901 234 567',
              '• Giao hàng: nội thành trong ngày',
              '• Thanh toán: COD / Chuyển khoản',
            ],
          ),
        ],
      );

  Widget _webFooter() => Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: _plainBox(fill: CheckoutColors.lightGray),
        child: _txt('PIXEL BAKERY | CHECKOUT', CheckoutColors.gray, 10, FontWeight.w700),
      );

  Widget _card({required String title, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: _plainBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(title, CheckoutColors.blue, 18, FontWeight.w800),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );

  Widget _addressField(CheckoutState state, double h, double fs) {
    final addresses = state.userAddresses;
    if (addresses.length <= 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt('Địa chỉ nhận hàng', CheckoutColors.gray, 12, FontWeight.w700),
          const SizedBox(height: 4),
          _simpleInput(state.displayAddress, h, fs, textColor: CheckoutColors.blue),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _txt('Địa chỉ nhận hàng', CheckoutColors.gray, 12, FontWeight.w700),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: h,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.centerLeft,
          decoration: _plainBox(radius: 6),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: state.selectedAddressIndex ?? 0,
              items: addresses.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CheckoutColors.blue,
                      fontSize: fs,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Noto Sans',
                    ),
                  ),
                );
              }).toList(growable: false),
              onChanged: (index) => state.selectAddress(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _labeledInput(String label, String value, double h) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt(label, CheckoutColors.gray, 12, FontWeight.w700),
          const SizedBox(height: 4),
          _simpleInput(value, h, 14, textColor: CheckoutColors.blue),
        ],
      );

  Widget _simpleInput(String text, double h, double fs, {Color textColor = CheckoutColors.gray}) => Container(
        width: double.infinity,
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: _plainBox(radius: 6),
        child: _txt(text, textColor, fs, FontWeight.w600),
      );

  Widget _voucherInput(
    TextEditingController controller,
    double h,
    double fs,
  ) =>
      Container(
        width: double.infinity,
        height: h,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: _plainBox(radius: 6),
        child: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Nhập mã giảm giá',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: TextStyle(
            color: CheckoutColors.blue,
            fontSize: fs,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans',
          ),
        ),
      );

  Widget _editableTextField({
    required TextEditingController controller,
    required String hintText,
    required double height,
  }) =>
      Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: _plainBox(radius: 6),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: CheckoutColors.gray,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Noto Sans',
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            color: CheckoutColors.blue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans',
          ),
        ),
      );

  Widget _editableTextArea({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 3,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: _plainBox(radius: 6),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: CheckoutColors.gray,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              fontFamily: 'Noto Sans',
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            color: CheckoutColors.blue,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans',
          ),
        ),
      );

  Widget _timeSlotDropdown({
    required String? value,
    required double height,
    required double fontSize,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: _plainBox(radius: 6),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: Text(
              'Chọn khung giờ',
              style: TextStyle(
                color: CheckoutColors.gray,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                fontFamily: 'Noto Sans',
              ),
            ),
            items: const [
              '08:00 - 12:00',
              '12:00 - 17:00',
              '17:00 - 21:00',
            ]
                .map((slot) => DropdownMenuItem<String>(
                      value: slot,
                      child: Text(
                        slot,
                        style: TextStyle(
                          color: CheckoutColors.blue,
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Noto Sans',
                        ),
                      ),
                    ))
                .toList(growable: false),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _pickRow(String left, String right, bool selected) => Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: CheckoutColors.softBlue,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? CheckoutColors.blue : CheckoutColors.gray, width: 2),
        ),
        child: Row(
          children: [
            _txt(left, CheckoutColors.blue, 14, FontWeight.w700),
            const Spacer(),
            _txt(right, CheckoutColors.green, 14, FontWeight.w700),
          ],
        ),
      );

  Widget _paymentRow(String label, bool selected) => Container(
        width: double.infinity,
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: _plainBox(radius: 6),
        child: Row(
          children: [
            _txt(label, selected ? CheckoutColors.red : CheckoutColors.gray, 14, FontWeight.w700),
            const Spacer(),
            if (selected) _txt('Đang chọn', CheckoutColors.green, 12, FontWeight.w700),
          ],
        ),
      );

  Widget _bankTransferInfoBox(BankTransferInfoModel info) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sumRow('Ngân hàng', info.bankName),
          const SizedBox(height: 6),
          _sumRow('Chủ tài khoản', info.accountName),
          const SizedBox(height: 6),
          _sumRow('Số tài khoản', info.accountNumber),
          const SizedBox(height: 6),
          _sumRow('Nội dung CK', '${info.transferNotePrefix}-[MÃ ĐƠN]'),
        ],
      );

  Widget _sumRow(String l, String r) => Row(
        children: [
          Expanded(child: _txt(l, CheckoutColors.gray, 14, FontWeight.w600)),
          _txt(r, CheckoutColors.blue, 14, FontWeight.w700),
        ],
      );

  Widget _summaryContent() {
    final items = AppServices.instance.cartSession.items;
    final baseDeliveryFee = items.isEmpty ? 0 : 20000;
    final deliveryFee =
        state.appliedVoucherCode != null ? state.previewDeliveryFee : baseDeliveryFee;
    final discountAmount = state.previewDiscountAmount;
    final total = state.appliedVoucherCode != null
        ? state.previewTotal
        : AppServices.instance.cartSession.subtotal + baseDeliveryFee;
    final voucherCode = state.appliedVoucherCode ?? state.lastOrder?.voucherCode;
    if (items.isEmpty) {
      return _txt(
        'Chưa có sản phẩm trong giỏ hàng.',
        CheckoutColors.gray,
        14,
        FontWeight.w600,
      );
    }

    return Column(
      children: [
        if (voucherCode != null) ...[
          _sumRow('Voucher', voucherCode),
          const SizedBox(height: 8),
        ],
        ...List.generate(items.length * 2 + 1, (index) {
          if (index.isOdd) {
            return const SizedBox(height: 8);
          }
          final itemIndex = index ~/ 2;
          if (itemIndex == items.length) {
            return _sumRow('Phí giao hàng', _formatCurrency(deliveryFee));
          }
          final item = items[itemIndex];
          return _summaryItemRow(item);
        }),
        if (discountAmount > 0) ...[
          const SizedBox(height: 8),
          _sumRow('Giảm giá', '-${_formatCurrency(discountAmount)}'),
        ],
        const SizedBox(height: 10),
        Container(height: 2, color: CheckoutColors.gray),
        const SizedBox(height: 8),
        Row(
          children: [
            _txt('Tổng cộng', CheckoutColors.red, 16, FontWeight.w800),
            const Spacer(),
            _txt(_formatCurrency(total), CheckoutColors.green, 20, FontWeight.w900),
          ],
        ),
      ],
    );
  }

  Widget _solidButton(String text, Color bg, double w, double h, double fs) => Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: _txt(text, Colors.white, fs, FontWeight.w800),
      );

  Widget _summaryItemRow(CartItem item) => _isBoxStyledCheckoutItem(item)
      ? _boxedSummaryItemRow(item)
      : Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7D5B2), width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _checkoutSummaryThumbnail(item.imageUrl, 58),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _txt(
                      item.title,
                      CheckoutColors.gray,
                      14,
                      FontWeight.w600,
                    ),
                    if ((item.variantLabel ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _txt(
                          item.variantLabel!,
                          CheckoutColors.blue,
                          12,
                          FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 8),
                    _checkoutQuantityActions(item),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _txt(
                _formatCurrency(item.lineTotal),
                CheckoutColors.blue,
                14,
                FontWeight.w700,
              ),
            ],
          ),
        );

  Widget _boxedSummaryItemRow(CartItem item) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE7D5B2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checkoutSummaryThumbnail(item.imageUrl, 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _txt(
                        item.title,
                        CheckoutColors.blue,
                        14,
                        FontWeight.w800,
                      ),
                      if (item.boxItems.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _txt(
                          'Giá hộp: ${_formatCurrency(_calculateCheckoutBoxPackagePrice(item) * item.quantity)}',
                          CheckoutColors.green,
                          12,
                          FontWeight.w700,
                        ),
                      ],
                      if ((item.variantLabel ?? '').trim().isNotEmpty &&
                          item.boxItems.isEmpty) ...[
                        const SizedBox(height: 4),
                        _txt(
                          item.variantLabel!,
                          CheckoutColors.gray,
                          12,
                          FontWeight.w600,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                  _txt(
                  _formatCurrency(item.lineTotal),
                  CheckoutColors.green,
                  14,
                  FontWeight.w800,
                ),
              ],
            ),
            const SizedBox(height: 10),
            _checkoutQuantityActions(item),
            if (item.boxItems.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...item.boxItems.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == item.boxItems.length - 1 ? 0 : 8,
                      ),
                      child: _boxedChildRow(
                        index: entry.key,
                        item: entry.value,
                      ),
                    ),
                  ),
            ],
          ],
        ),
      );

  Widget _boxedChildRow({
    required int index,
    required CartBoxItem item,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _checkoutSummaryThumbnail(item.imageUrl ?? '', 42),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _txt(
                  'Bánh ${index + 1}: ${item.title}',
                  CheckoutColors.gray,
                  12,
                  FontWeight.w700,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: _txt(
                        item.variantLabel,
                        CheckoutColors.gray,
                        11,
                        FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _txt(
                      item.price,
                      CheckoutColors.green,
                      11,
                      FontWeight.w700,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );

  Widget _cta(
    String text,
    double h,
    double fs, {
    VoidCallback? onTap,
    bool isLoading = false,
  }) =>
      GestureDetector(
        onTap: isLoading ? null : onTap,
        child: Container(
          width: double.infinity,
          height: h,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CheckoutColors.red,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CheckoutColors.gray, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x66616161), blurRadius: 0, offset: Offset(2, 2)),
            ],
          ),
          child: _txt(
            isLoading ? 'ĐANG XỬ LÝ...' : text,
            Colors.white,
            fs,
            FontWeight.w900,
          ),
        ),
      );

  Widget _submitBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: state.isSubmitSuccess
              ? const Color(0xFFEFF8F1)
              : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: state.isSubmitSuccess
                ? CheckoutColors.green
                : CheckoutColors.red,
            width: 2,
          ),
        ),
        child: _txt(
          state.submitMessage ?? '',
          state.isSubmitSuccess ? CheckoutColors.green : CheckoutColors.red,
          13,
          FontWeight.w700,
        ),
      );

  Widget _policy({required double titleSize, required double bodySize, required List<String> lines}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _policyBox(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Chính sách', CheckoutColors.blue, titleSize, FontWeight.w800),
            const SizedBox(height: 6),
            for (final l in lines) ...[
              _txt(l, CheckoutColors.gray, bodySize, FontWeight.w600),
              const SizedBox(height: 2),
            ],
          ],
        ),
      );

  BoxDecoration _screenBox([BuildContext? context]) => BoxDecoration(
        color: context != null ? Theme.of(context).cardColor : CheckoutColors.white,
        border: Border.all(color: CheckoutColors.gray, width: 3),
      );

  BoxDecoration _plainBox({double radius = 8, Color fill = CheckoutColors.white}) => BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CheckoutColors.gray, width: 2),
      );

  BoxDecoration _gradientBox() => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF4F8FF)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CheckoutColors.gray, width: 2),
      );

  BoxDecoration _policyBox() => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF3FF), Color(0xFFF1FAF1)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CheckoutColors.gray, width: 2),
      );

  Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'Noto Sans'),
      );

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
    buffer.write('đ');
    return buffer.toString();
  }
}

class MobileCheckoutLayout extends StatefulWidget {
  const MobileCheckoutLayout({
    super.key,
    required this.state,
    required this.voucherController,
    required this.noteController,
    required this.deliveryDateController,
    required this.customerDropdownController,
    this.showTopHeader = true,
  });

  final CheckoutState state;
  final TextEditingController voucherController;
  final TextEditingController noteController;
  final TextEditingController deliveryDateController;
  final CheckoutCustomerDropdownController customerDropdownController;
  final bool showTopHeader;

  @override
  State<MobileCheckoutLayout> createState() => _MobileCheckoutLayoutState();
}

class _MobileCheckoutLayoutState extends State<MobileCheckoutLayout> {
  String? _selectedTimeSlot;

  CheckoutState get state => widget.state;
  TextEditingController get voucherController => widget.voucherController;
  CheckoutCustomerDropdownController get customerDropdownController =>
      widget.customerDropdownController;
  bool get showTopHeader => widget.showTopHeader;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        state,
        AppServices.instance.cartSession,
        AppServices.instance.authSession,
      ]),
      builder: (context, _) => SizedBox(
        width: 390,
        height: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border.all(color: CheckoutColors.gray, width: 3),
          ),
          child: Column(
            children: [
              if (showTopHeader) _mobileTopHeader(context),
              if (showTopHeader) const SizedBox(height: 10),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _mobileCard(
                        title: 'Thông tin khách hàng',
                        child: Column(
                          children: [
                            if (state.isAdmin) ...[
                              CheckoutCustomerDropdown(
                                controller: customerDropdownController,
                                hintText: 'Chọn khách hàng để tạo đơn',
                                height: 40,
                                fontSize: 12,
                                onChanged: state.selectCustomer,
                              ),
                              const SizedBox(height: 8),
                            ],
                            _mobileInput(
                              state.displayName,
                            ),
                            const SizedBox(height: 8),
                            _mobileInput(
                              state.displayPhone,
                            ),
                            const SizedBox(height: 8),
                            _mobileAddressField(state),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _mobileCard(
                        title: 'Phương thức giao hàng',
                        child: _mobilePick(
                          'Giao tiêu chuẩn (2h)',
                          _formatCurrency(
                            AppServices.instance.cartSession.items.isEmpty ? 0 : 20000,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      _mobileCard(
                        title: 'Phương thức thanh toán',
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => state.selectPaymentMethod(
                                CheckoutPaymentMethod.cod,
                              ),
                              child: _mobilePayRow(
                                'COD',
                                state.selectedPaymentMethod ==
                                    CheckoutPaymentMethod.cod,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => state.selectPaymentMethod(
                                CheckoutPaymentMethod.bankTransfer,
                              ),
                              child: _mobilePayRow(
                                'Chuyển khoản',
                                state.selectedPaymentMethod ==
                                    CheckoutPaymentMethod.bankTransfer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _mobileCard(
                        title: 'Thông tin giao hàng',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _txt('Ghi chú đơn hàng', CheckoutColors.gray, 11, FontWeight.w700),
                            const SizedBox(height: 4),
                            _mobileEditableTextArea(
                              controller: widget.noteController,
                              hintText: 'Ghi chú cho người giao hàng...',
                              maxLines: 3,
                            ),
                            const SizedBox(height: 8),
                            _txt('Ngày giao hàng', CheckoutColors.gray, 11, FontWeight.w700),
                            const SizedBox(height: 4),
                            _mobileEditableTextField(
                              controller: widget.deliveryDateController,
                              hintText: 'dd/mm/yyyy',
                              height: 40,
                            ),
                            const SizedBox(height: 8),
                            _txt('Khung giờ', CheckoutColors.gray, 11, FontWeight.w700),
                            const SizedBox(height: 4),
                            _mobileTimeSlotDropdown(
                              value: _selectedTimeSlot,
                              height: 40,
                              onChanged: (v) {
                                setState(() => _selectedTimeSlot = v);
                                state.deliveryTimeSlot = v;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _mobileCard(
                        title: 'Tóm tắt đơn hàng',
                        child: _mobileSummaryContent(),
                      ),
                      const SizedBox(height: 10),
                      _mobileCard(
                        title: 'Mã giảm giá',
                        child: Row(
                          children: [
                            Expanded(child: _mobileVoucherInput(voucherController)),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () async =>
                                  state.applyVoucherCode(voucherController.text),
                              child: Container(
                                width: 100,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: CheckoutColors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: CheckoutColors.gray, width: 2),
                                ),
                                alignment: Alignment.center,
                                child: _txt('Áp dụng', Colors.white, 12, FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (state.userPoints > 0) ...[
                        const SizedBox(height: 10),
                        _LoyaltyPointsCard(state: state, compact: true),
                      ],
                      if (state.bankTransferInfo != null) ...[
                        const SizedBox(height: 10),
                        _mobileCard(
                          title: 'Thông tin chuyển khoản',
                          child: _mobileBankTransferInfo(state.bankTransferInfo!),
                        ),
                      ],
                      if (state.submitMessage != null) ...[
                        const SizedBox(height: 10),
                        _mobileSubmitBanner(),
                      ],
                      const SizedBox(height: 10),
                      _mobileCta(),
                      const SizedBox(height: 10),
                      _mobilePolicy(),
                      const SizedBox(height: 10),
                      const PixelFooter(label: 'PIXEL BAKERY | THANH TOÁN', mobile: true),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileTopHeader(BuildContext context) => Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: CheckoutColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => context.goNamed(AppRouteNames.home),
              child: _txt('PIXEL BAKERY', CheckoutColors.red, 14, FontWeight.w900),
            ),
            const Spacer(),
            _txt('Thanh toán', CheckoutColors.blue, 12, FontWeight.w700),
          ],
        ),
      );

  Widget _mobileCard({required String title, required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: CheckoutColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(title, CheckoutColors.blue, 15, FontWeight.w800),
            const SizedBox(height: 8),
            child,
          ],
        ),
      );

  Widget _mobileAddressField(CheckoutState state) {
    final addresses = state.userAddresses;
    if (addresses.length <= 1) {
      return _mobileInput(state.displayAddress);
    }
    return Container(
      width: double.infinity,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: CheckoutColors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: CheckoutColors.gray, width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: state.selectedAddressIndex ?? 0,
          items: addresses.asMap().entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.key,
              child: Text(
                entry.value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: CheckoutColors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Sans',
                ),
              ),
            );
          }).toList(growable: false),
          onChanged: (index) => state.selectAddress(index),
        ),
      ),
    );
  }

  Widget _mobileInput(String text) => Container(
        width: double.infinity,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: CheckoutColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: _txt(text, text == 'Nhập mã giảm giá' ? CheckoutColors.gray : CheckoutColors.blue, 12, FontWeight.w600),
      );

  Widget _mobileVoucherInput(TextEditingController controller) => Container(
        width: double.infinity,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: CheckoutColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'Nhập mã giảm giá',
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            color: CheckoutColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans',
          ),
        ),
      );

  BoxDecoration _mobilePlainBox({double radius = 6}) => BoxDecoration(
        color: CheckoutColors.white,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: CheckoutColors.gray, width: 2),
      );

  Widget _mobileEditableTextField({
    required TextEditingController controller,
    required String hintText,
    required double height,
  }) =>
      Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: _mobilePlainBox(),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: CheckoutColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Noto Sans',
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            color: CheckoutColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans',
          ),
        ),
      );

  Widget _mobileEditableTextArea({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 3,
  }) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: _mobilePlainBox(),
        child: TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: CheckoutColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Noto Sans',
            ),
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            isCollapsed: true,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            color: CheckoutColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans',
          ),
        ),
      );

  Widget _mobileTimeSlotDropdown({
    required String? value,
    required double height,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: _mobilePlainBox(),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: value,
            hint: const Text(
              'Chọn khung giờ',
              style: TextStyle(
                color: CheckoutColors.gray,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Noto Sans',
              ),
            ),
            items: const [
              '08:00 - 12:00',
              '12:00 - 17:00',
              '17:00 - 21:00',
            ]
                .map((slot) => DropdownMenuItem<String>(
                      value: slot,
                      child: Text(
                        slot,
                        style: const TextStyle(
                          color: CheckoutColors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Noto Sans',
                        ),
                      ),
                    ))
                .toList(growable: false),
            onChanged: onChanged,
          ),
        ),
      );

  Widget _mobilePick(String l, String r) => Container(
        width: double.infinity,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: CheckoutColors.softBlue,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CheckoutColors.blue, width: 2),
        ),
        child: Row(
          children: [
            _txt(l, CheckoutColors.blue, 12, FontWeight.w700),
            const Spacer(),
            _txt(r, CheckoutColors.green, 12, FontWeight.w700),
          ],
        ),
      );

  Widget _mobilePayRow(String label, bool selected) => Container(
        width: double.infinity,
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: CheckoutColors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: Row(
          children: [
            _txt(label, CheckoutColors.red, 13, FontWeight.w700),
            const Spacer(),
            if (selected) _txt('Đang chọn', CheckoutColors.green, 11, FontWeight.w700),
          ],
        ),
      );

  Widget _mobileBankTransferInfo(BankTransferInfoModel info) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mSum('Ngân hàng', info.bankName),
          const SizedBox(height: 6),
          _mSum('Chủ TK', info.accountName),
          const SizedBox(height: 6),
          _mSum('Số TK', info.accountNumber),
          const SizedBox(height: 6),
          _mSum('Nội dung', '${info.transferNotePrefix}-[MÃ ĐƠN]'),
        ],
      );

  Widget _mSum(String l, String r) => Row(
        children: [
          Expanded(child: _txt(l, CheckoutColors.gray, 12, FontWeight.w600)),
          _txt(r, CheckoutColors.blue, 12, FontWeight.w700),
        ],
      );

  Widget _mobileSummaryContent() {
    final items = AppServices.instance.cartSession.items;
    final baseDeliveryFee = items.isEmpty ? 0 : 20000;
    final deliveryFee =
        state.appliedVoucherCode != null ? state.previewDeliveryFee : baseDeliveryFee;
    final discountAmount = state.previewDiscountAmount;
    final total = state.appliedVoucherCode != null
        ? state.previewTotal
        : AppServices.instance.cartSession.subtotal + baseDeliveryFee;
    final voucherCode = state.appliedVoucherCode ?? state.lastOrder?.voucherCode;
    if (items.isEmpty) {
      return _txt(
        'Chưa có sản phẩm trong giỏ hàng.',
        CheckoutColors.gray,
        12,
        FontWeight.w600,
      );
    }

    return Column(
      children: [
        if (voucherCode != null) ...[
          _mSum('Voucher', voucherCode),
          const SizedBox(height: 6),
        ],
        ...List.generate(items.length * 2 + 1, (index) {
          if (index.isOdd) {
            return const SizedBox(height: 6);
          }
          final itemIndex = index ~/ 2;
          if (itemIndex == items.length) {
            return _mSum('Phí giao hàng', _formatCurrency(deliveryFee));
          }
          final item = items[itemIndex];
          return _mobileSummaryItemRow(item);
        }),
        if (discountAmount > 0) ...[
          const SizedBox(height: 6),
          _mSum('Giảm giá', '-${_formatCurrency(discountAmount)}'),
        ],
        const SizedBox(height: 8),
        Container(height: 2, color: CheckoutColors.gray),
        const SizedBox(height: 8),
        Row(
          children: [
            _txt('Tổng cộng', CheckoutColors.red, 14, FontWeight.w800),
            const Spacer(),
            _txt(_formatCurrency(total), CheckoutColors.green, 18, FontWeight.w900),
          ],
        ),
      ],
    );
  }

  Widget _mobileCta() => GestureDetector(
        onTap: state.isSubmitting ? null : state.submitOrder,
        child: Container(
          width: double.infinity,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CheckoutColors.red,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CheckoutColors.gray, width: 2),
          ),
          child: _txt(
            state.isSubmitting ? 'ĐANG XỬ LÝ...' : 'THANH TOÁN NGAY',
            Colors.white,
            14,
            FontWeight.w900,
          ),
        ),
      );

  Widget _mobileSummaryItemRow(CartItem item) => _isBoxStyledCheckoutItem(item)
      ? _mobileBoxSummaryItemRow(item)
      : Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE7D5B2), width: 1.2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _checkoutSummaryThumbnail(item.imageUrl, 48),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _txt(
                      item.title,
                      CheckoutColors.gray,
                      12,
                      FontWeight.w600,
                    ),
                    if ((item.variantLabel ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: _txt(
                          item.variantLabel!,
                          CheckoutColors.blue,
                          11,
                          FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 6),
                    _checkoutQuantityActions(item, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _txt(
                _formatCurrency(item.lineTotal),
                CheckoutColors.blue,
                12,
                FontWeight.w700,
              ),
            ],
          ),
        );

  Widget _mobileBoxSummaryItemRow(CartItem item) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE7D5B2), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _checkoutSummaryThumbnail(item.imageUrl, 58),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _txt(
                        item.title,
                        CheckoutColors.blue,
                        12,
                        FontWeight.w800,
                      ),
                      if (item.boxItems.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        _txt(
                          'Giá hộp: ${_formatCurrency(_calculateCheckoutBoxPackagePrice(item) * item.quantity)}',
                          CheckoutColors.green,
                          10,
                          FontWeight.w700,
                        ),
                      ],
                      if ((item.variantLabel ?? '').trim().isNotEmpty &&
                          item.boxItems.isEmpty) ...[
                        const SizedBox(height: 4),
                        _txt(
                          item.variantLabel!,
                          CheckoutColors.gray,
                          10,
                          FontWeight.w600,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _txt(
                  _formatCurrency(item.lineTotal),
                  CheckoutColors.green,
                  12,
                  FontWeight.w800,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _checkoutQuantityActions(item, compact: true),
            if (item.boxItems.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...item.boxItems.asMap().entries.map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom: entry.key == item.boxItems.length - 1 ? 0 : 6,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _checkoutSummaryThumbnail(entry.value.imageUrl ?? '', 34),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _txt(
                                  'Bánh ${entry.key + 1}: ${entry.value.title}',
                                  CheckoutColors.gray,
                                  10,
                                  FontWeight.w700,
                                ),
                                const SizedBox(height: 1),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _txt(
                                        entry.value.variantLabel,
                                        CheckoutColors.gray,
                                        9,
                                        FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _txt(
                                      entry.value.price,
                                      CheckoutColors.green,
                                      9,
                                      FontWeight.w700,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ],
        ),
      );




  Widget _mobileSubmitBanner() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: state.isSubmitSuccess
              ? const Color(0xFFEFF8F1)
              : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: state.isSubmitSuccess
                ? CheckoutColors.green
                : CheckoutColors.red,
            width: 2,
          ),
        ),
        child: _txt(
          state.submitMessage ?? '',
          state.isSubmitSuccess ? CheckoutColors.green : CheckoutColors.red,
          12,
          FontWeight.w700,
        ),
      );

  Widget _mobilePolicy() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF3FF), Color(0xFFF1FAF1)],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Chính sách', CheckoutColors.blue, 13, FontWeight.w800),
            const SizedBox(height: 4),
            _txt('• Liên hệ: 0901 234 567', CheckoutColors.gray, 11, FontWeight.w600),
            _txt('• Giao hàng: nội thành trong ngày', CheckoutColors.gray, 11, FontWeight.w600),
          ],
        ),
      );

  Widget _mobileFooter() => Container(
        width: double.infinity,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: CheckoutColors.lightGray,
          border: Border.all(color: CheckoutColors.gray, width: 2),
        ),
        child: _txt('PIXEL BAKERY | CHECKOUT', CheckoutColors.gray, 8, FontWeight.w700),
      );

  Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight, fontFamily: 'Noto Sans'),
      );

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
    buffer.write('đ');
    return buffer.toString();
  }

}

class CheckoutCustomerDropdownController extends ChangeNotifier {
  List<AdminCustomerModel> _items = const [];
  String? _selectedId;

  List<AdminCustomerModel> get items => _items;
  String? get selectedId => _selectedId;
  AdminCustomerModel? get selectedItem {
    final id = _selectedId;
    if (id == null) {
      return null;
    }
    for (final item in _items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  void setOptions(List<AdminCustomerModel> items, {String? selectedId}) {
    _items = List<AdminCustomerModel>.from(items);
    _selectedId = selectedId;
    notifyListeners();
  }

  void select(String? id) {
    if (_selectedId == id) {
      return;
    }
    _selectedId = id;
    notifyListeners();
  }
}

class CheckoutCustomerDropdown extends StatelessWidget {
  const CheckoutCustomerDropdown({
    super.key,
    required this.controller,
    required this.hintText,
    required this.height,
    required this.fontSize,
    required this.onChanged,
  });

  final CheckoutCustomerDropdownController controller;
  final String hintText;
  final double height;
  final double fontSize;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Container(
          width: double.infinity,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: CheckoutColors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: CheckoutColors.gray, width: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: controller.selectedId,
              hint: Text(
                hintText,
                style: TextStyle(
                  color: CheckoutColors.gray,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Sans',
                ),
              ),
              items: controller.items.map((customer) {
                return DropdownMenuItem<String>(
                  value: customer.id,
                  child: Text(
                    '${customer.fullName} • ${customer.email}',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: CheckoutColors.blue,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Noto Sans',
                    ),
                  ),
                );
              }).toList(growable: false),
              onChanged: (value) {
                controller.select(value);
                onChanged(value);
              },
            ),
          ),
        );
      },
    );
  }
}

// ─── Loyalty Points Card ──────────────────────────────────────────────────────

class _LoyaltyPointsCard extends StatefulWidget {
  const _LoyaltyPointsCard({required this.state, this.compact = false});
  final CheckoutState state;
  final bool compact;
  @override
  State<_LoyaltyPointsCard> createState() => _LoyaltyPointsCardState();
}

class _LoyaltyPointsCardState extends State<_LoyaltyPointsCard> {
  bool _usePoints = false;

  void _toggle(bool v) {
    setState(() => _usePoints = v);
    widget.state.pointsToUse = v ? widget.state.userPoints : 0;
  }

  String _fmt(int amount) =>
      '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.')}đ';

  @override
  Widget build(BuildContext context) {
    final points = widget.state.userPoints;
    final discount = _fmt(points * 1000);
    if (widget.compact) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8A8A8A), width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFF1E88E5), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bạn có $points điểm (≈ $discount)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E88E5)),
              ),
            ),
            Switch(
              value: _usePoints,
              onChanged: _toggle,
              activeColor: const Color(0xFF1E88E5),
            ),
          ],
        ),
      );
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8A8A8A), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Điểm tích lũy', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E88E5))),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bạn có $points điểm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurface)),
                    Text('Dùng hết = giảm $discount', style: const TextStyle(fontSize: 12, color: Color(0xFF2E7D32))),
                  ],
                ),
              ),
              Switch(value: _usePoints, onChanged: _toggle, activeColor: const Color(0xFF1E88E5)),
            ],
          ),
          if (_usePoints) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFFEAF3FF), borderRadius: BorderRadius.circular(6)),
              child: Text(
                'Áp dụng $points điểm → giảm $discount',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E88E5)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
