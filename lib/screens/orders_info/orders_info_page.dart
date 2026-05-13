import 'package:flutter/material.dart';
import '../../app/models/order_models.dart';
import '../../app/models/ui_accent.dart';
import '../shared/app_header.dart';
import '../shared/pixel_footer.dart';
import 'orders_info_state.dart';

class OrdersInfoColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF059669);
  static const orange = Color(0xFFD97706);
  static const gray = Color(0xFF8A8A8A);
  static const bodyBg = Color(0xFFF8F8F8);
  static const textDark = Color(0xFF222222);
  static const borderSoft = Color(0xFFCFCFCF);
}

Color _ordersInfoColor(UiAccent accent) {
  switch (accent) {
    case UiAccent.red:
      return OrdersInfoColors.red;
    case UiAccent.blue:
      return const Color(0xFF2563EB);
    case UiAccent.green:
      return OrdersInfoColors.green;
    case UiAccent.gray:
      return OrdersInfoColors.gray;
    case UiAccent.orange:
      return OrdersInfoColors.orange;
  }
}

class ResponsiveOrdersInfoScreen extends StatefulWidget {
  const ResponsiveOrdersInfoScreen({super.key, this.showTopHeader = true});
  final bool showTopHeader;

  @override
  State<ResponsiveOrdersInfoScreen> createState() =>
      _ResponsiveOrdersInfoScreenState();
}

class _ResponsiveOrdersInfoScreenState
    extends State<ResponsiveOrdersInfoScreen> {
  final OrdersInfoState _state = OrdersInfoState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return isMobile
            ? _OrdersInfoMobile(
                state: _state, showTopHeader: widget.showTopHeader)
            : _OrdersInfoWeb(
                state: _state, showTopHeader: widget.showTopHeader);
      },
    );
  }
}

class _OrdersInfoWeb extends StatelessWidget {
  final OrdersInfoState state;
  final bool showTopHeader;
  const _OrdersInfoWeb({required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1280,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: OrdersInfoColors.bodyBg,
          border: Border.all(color: OrdersInfoColors.gray, width: 2),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _header(),
              const SizedBox(height: 12),
              _topCards(),
              const SizedBox(height: 12),
              _statusPanel(),
              const SizedBox(height: 12),
              _faqPanel(),
              const SizedBox(height: 12),
              const PixelFooter(label: 'PIXEL BAKERY | THEO DÕI ĐƠN'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _box(const Color(0xFF8A8A8A)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Thông tin tab Đơn hàng', OrdersInfoColors.blue, 20,
                FontWeight.w800),
            const SizedBox(height: 6),
            _txt(
              'Tổng hợp quy trình xử lý, SLA và chính sách đơn hàng.',
              OrdersInfoColors.gray,
              12,
              FontWeight.w400,
            ),
          ],
        ),
      );

  Widget _topCards() => SizedBox(
        height: 220,
        child: Row(
          children: [
            Expanded(child: _cardSla()),
            const SizedBox(width: 10),
            Expanded(child: _cardFlow()),
            const SizedBox(width: 10),
            Expanded(child: _cardNotes()),
          ],
        ),
      );

  Widget _cardSla() => _infoCard(state.slaSection);

  Widget _cardFlow() => _infoCard(state.flowSection);

  Widget _cardNotes() => _infoCard(state.notesSection);

  Widget _statusPanel() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _box(OrdersInfoColors.borderSoft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Bảng màu trạng thái', OrdersInfoColors.blue, 16,
                FontWeight.w800),
            ...List.generate(state.statuses.length * 2, (index) {
              if (index.isEven) return const SizedBox(height: 8);
              final status = state.statuses[index ~/ 2];
              return _statusRow(
                status.label,
                status.description,
                _ordersInfoColor(status.accent),
              );
            }),
          ],
        ),
      );

  Widget _faqPanel() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: _box(OrdersInfoColors.borderSoft),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('FAQ nội bộ tab đơn hàng', OrdersInfoColors.blue, 16,
                FontWeight.w800),
            const SizedBox(height: 8),
            _txt('Q: Khi nào được phép hoàn tiền 100%?',
                OrdersInfoColors.textDark, 12, FontWeight.w700),
            const SizedBox(height: 4),
            _txt('A: Khi lỗi từ phía cửa hàng hoặc giao sai sản phẩm.',
                OrdersInfoColors.gray, 12, FontWeight.w400),
            const SizedBox(height: 8),
            _txt('Q: Đơn COD không nghe máy xử lý thế nào?',
                OrdersInfoColors.textDark, 12, FontWeight.w700),
            const SizedBox(height: 4),
            _txt(
              'A: Gọi lại 3 lần trong 15 phút, sau đó chuyển trạng thái treo.',
              OrdersInfoColors.gray,
              12,
              FontWeight.w400,
            ),
          ],
        ),
      );

  Widget _infoCard(OrdersInfoSection section) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(OrdersInfoColors.borderSoft),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt(section.title, OrdersInfoColors.blue, 14, FontWeight.w800),
          const SizedBox(height: 8),
          ...List.generate(section.items.length, (index) {
            final isLast = index == section.items.length - 1;
            final isEmphasis = section.emphasizedLast && isLast;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
              child: _txt(
                '• ${section.items[index]}',
                isEmphasis ? OrdersInfoColors.red : OrdersInfoColors.textDark,
                12,
                isEmphasis ? FontWeight.w700 : FontWeight.w400,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _statusRow(String label, String desc, Color color) => Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: OrdersInfoColors.bodyBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD1D5DB), width: 1),
        ),
        child: Row(
          children: [
            SizedBox(width: 90, child: _txt(label, color, 12, FontWeight.w700)),
            Expanded(
                child:
                    _txt(desc, OrdersInfoColors.textDark, 12, FontWeight.w400)),
          ],
        ),
      );

  BoxDecoration _box(Color border) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: 1),
      );

  Widget _txt(String t, Color c, double s, FontWeight w) =>
      Text(t, style: TextStyle(color: c, fontSize: s, fontWeight: w));
}

class _OrdersInfoMobile extends StatelessWidget {
  final OrdersInfoState state;
  final bool showTopHeader;
  const _OrdersInfoMobile({required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: OrdersInfoColors.bodyBg,
          border: Border.all(color: OrdersInfoColors.gray, width: 2),
        ),
        child: Column(
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                  rightLabel: 'SLA', showBack: true, showBrand: false),
            if (showTopHeader) const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _mobileHeader(),
                    const SizedBox(height: 10),
                    _mobileCard('SLA xử lý', [
                      '• Xác nhận <= 10 phút',
                      '• Chuẩn bị 20-45 phút',
                      '• Giao <= 60 phút',
                    ]),
                    const SizedBox(height: 10),
                    _mobileCard(
                        'Luồng trạng thái',
                        [
                          'Mới -> Xác nhận -> Đang làm',
                          '-> Đang giao -> Hoàn tất',
                          'Lỗi: Hoàn tiền / Huỷ đơn',
                        ],
                        emphasisLast: true),
                    const SizedBox(height: 10),
                    _mobileCard('Lưu ý nhanh', [
                      '• Ưu tiên đơn có giờ hẹn',
                      '• COD > 500k phải gọi xác nhận',
                      '• Lưu ảnh lỗi trước khi hoàn tiền',
                    ]),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: OrdersInfoColors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _mtxt('Xem SOP chi tiết', Colors.white, 11,
                          FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const PixelFooter(label: 'PIXEL BAKERY | THEO DÕI ĐƠN', mobile: true),
          ],
        ),
      ),
    );
  }

  Widget _mobileHeader() => Container(
        width: double.infinity,
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OrdersInfoColors.gray, width: 1),
        ),
        child: Row(
          children: [
            _mtxt('Info Đơn hàng', OrdersInfoColors.blue, 16, FontWeight.w800),
            const Spacer(),
            _mtxt('SLA', OrdersInfoColors.red, 11, FontWeight.w700),
          ],
        ),
      );

  Widget _mobileCard(String title, List<String> lines,
          {bool emphasisLast = false}) =>
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: OrdersInfoColors.borderSoft, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _mtxt(title, OrdersInfoColors.blue, 13, FontWeight.w800),
            const SizedBox(height: 6),
            ...List.generate(lines.length, (index) {
              final isLast = index == lines.length - 1;
              final isEm = emphasisLast && isLast;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
                child: _mtxt(
                  lines[index],
                  isEm ? OrdersInfoColors.red : OrdersInfoColors.textDark,
                  11,
                  isEm ? FontWeight.w700 : FontWeight.w400,
                ),
              );
            }),
          ],
        ),
      );

  Widget _mtxt(String t, Color c, double s, FontWeight w) =>
      Text(t, style: TextStyle(color: c, fontSize: s, fontWeight: w));
}
