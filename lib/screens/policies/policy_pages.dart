import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/routing/app_router.dart';
import '../shared/app_header.dart';
import '../shared/pixel_footer.dart';

class PolicyColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const gray = Color(0xFF8A8A8A);
  static const softGray = Color(0xFFE5E7EB);
  static const bodyBg = Color(0xFFF8F8F8);
  static const textDark = Color(0xFF222222);
  static const green = Color(0xFF059669);
  static const amber = Color(0xFFD97706);
}

class ResponsiveDeliveryPolicyScreen extends StatelessWidget {
  const ResponsiveDeliveryPolicyScreen({
    super.key,
    this.showTopHeader = true,
  });

  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    const policy = _PolicyContent(
      pageLabel: 'giao hàng',
      heroTitle: 'Chính sách giao hàng',
      heroDescription:
          'Thông tin về khu vực phục vụ, thời gian xử lý và các lưu ý khi nhận bánh tại Pixel Bakery.',
      highlightCards: [
        _PolicyHighlight(
          title: 'Khu vực áp dụng',
          value: 'Nội thành ưu tiên giao nhanh trong ngày.',
          accent: PolicyColors.blue,
        ),
        _PolicyHighlight(
          title: 'Thời gian xử lý',
          value: 'Xác nhận đơn trong 15-30 phút giờ làm việc.',
          accent: PolicyColors.red,
        ),
        _PolicyHighlight(
          title: 'Phí giao hàng',
          value: 'Hiển thị minh bạch tại bước checkout trước khi đặt.',
          accent: PolicyColors.green,
        ),
      ],
      sections: [
        _PolicySection(
          title: '1. Phạm vi giao hàng',
          items: [
            'Pixel Bakery nhận giao tại các quận nội thành và khu vực lân cận theo năng lực vận hành từng thời điểm.',
            'Một số địa chỉ xa trung tâm hoặc khung giờ cao điểm có thể cần thêm thời gian điều phối.',
            'Nếu địa chỉ ngoài vùng phục vụ chuẩn, đội ngũ cửa hàng sẽ chủ động liên hệ để xác nhận phương án giao phù hợp.',
          ],
        ),
        _PolicySection(
          title: '2. Thời gian giao nhận',
          items: [
            'Đơn giao trong ngày được ưu tiên xử lý theo khung giờ khách chọn khi đặt hàng.',
            'Đơn đặt trước theo ngày sẽ được giữ lịch và xác nhận lại trước thời điểm giao.',
            'Trong các dịp lễ, Tết hoặc thời tiết xấu, thời gian giao có thể thay đổi và sẽ được thông báo sớm nếu phát sinh.',
          ],
        ),
        _PolicySection(
          title: '3. Điều kiện bàn giao',
          items: [
            'Khách vui lòng giữ điện thoại liên lạc trong thời gian giao hàng để shipper kết nối nhanh.',
            'Người nhận nên kiểm tra ngoại quan hộp bánh, phụ kiện và thông tin đơn ngay khi nhận.',
            'Nếu cần đổi địa chỉ hoặc người nhận, vui lòng báo trước khi đơn chuyển sang trạng thái đang giao.',
          ],
        ),
        _PolicySection(
          title: '4. Trường hợp giao không thành công',
          items: [
            'Nếu shipper không liên hệ được, đơn có thể được giữ ở trạng thái chờ trong thời gian ngắn để tiếp tục hỗ trợ.',
            'Trường hợp giao lại phát sinh chi phí do thay đổi từ phía khách, phí bổ sung sẽ được thông báo trước.',
            'Với sản phẩm tươi cần bảo quản lạnh, cửa hàng có quyền từ chối giao lại nhiều lần để bảo đảm chất lượng bánh.',
          ],
        ),
      ],
      notesTitle: 'Lưu ý quan trọng',
      notes: [
        'Khung giờ giao là khoảng thời gian dự kiến, không phải cam kết đến từng phút.',
        'Các mẫu bánh thiết kế riêng có thể cần thêm thời gian chuẩn bị và xác nhận thủ công.',
        'Nếu đơn hàng có yêu cầu đặc biệt về bảo quản hoặc setup quà tặng, vui lòng ghi chú ngay khi thanh toán.',
      ],
    );
    return _PolicyScreen(policy: policy, showTopHeader: showTopHeader);
  }
}

class ResponsivePaymentPolicyScreen extends StatelessWidget {
  const ResponsivePaymentPolicyScreen({
    super.key,
    this.showTopHeader = true,
  });

  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    const policy = _PolicyContent(
      pageLabel: 'thanh toán',
      heroTitle: 'Chính sách thanh toán',
      heroDescription:
          'Quy định về phương thức thanh toán, thời điểm ghi nhận đơn và các lưu ý khi hoàn tất giao dịch.',
      highlightCards: [
        _PolicyHighlight(
          title: 'Phương thức hỗ trợ',
          value: 'COD và chuyển khoản/online theo lựa chọn tại checkout.',
          accent: PolicyColors.blue,
        ),
        _PolicyHighlight(
          title: 'Xác nhận đơn',
          value: 'Đơn chỉ được giữ khi thông tin thanh toán hợp lệ.',
          accent: PolicyColors.red,
        ),
        _PolicyHighlight(
          title: 'Hoàn tiền',
          value: 'Xử lý theo từng trường hợp lỗi đơn hoặc giao dịch.',
          accent: PolicyColors.amber,
        ),
      ],
      sections: [
        _PolicySection(
          title: '1. Phương thức thanh toán',
          items: [
            'Khách có thể chọn thanh toán khi nhận hàng (COD) hoặc thanh toán trước bằng hình thức online được cửa hàng hỗ trợ.',
            'Các phương thức khả dụng có thể thay đổi theo giá trị đơn hàng, khu vực giao và chương trình đang áp dụng.',
            'Mọi khoản phí giao hàng, giảm giá và tổng thanh toán đều được hiển thị trước khi khách xác nhận đặt đơn.',
          ],
        ),
        _PolicySection(
          title: '2. Ghi nhận và xác nhận giao dịch',
          items: [
            'Đơn thanh toán online được ghi nhận sau khi hệ thống hoặc cửa hàng xác minh trạng thái giao dịch thành công.',
            'Nếu giao dịch chưa hoàn tất nhưng số dư đã bị trừ, khách vui lòng giữ biên lai/chụp màn hình để được hỗ trợ đối soát.',
            'Đơn COD được xem là hợp lệ khi khách cung cấp đầy đủ thông tin người nhận và địa chỉ giao hàng chính xác.',
          ],
        ),
        _PolicySection(
          title: '3. Điều chỉnh, hủy đơn và hoàn tiền',
          items: [
            'Yêu cầu hủy hoặc chỉnh sửa đơn cần được gửi sớm trước khi cửa hàng bắt đầu sản xuất hoặc bàn giao cho đơn vị vận chuyển.',
            'Nếu lỗi phát sinh từ phía Pixel Bakery như hết hàng, giao sai mẫu hoặc không thể thực hiện đơn, cửa hàng sẽ hoàn tiền theo giá trị chưa phục vụ.',
            'Thời gian nhận tiền hoàn phụ thuộc vào phương thức thanh toán ban đầu và quy trình xử lý của ngân hàng/đối tác thanh toán.',
          ],
        ),
        _PolicySection(
          title: '4. Bảo mật và đối soát',
          items: [
            'Pixel Bakery không yêu cầu khách cung cấp mật khẩu ngân hàng hoặc mã OTP qua chat, điện thoại hay email.',
            'Trong trường hợp phát hiện giao dịch bất thường, cửa hàng có thể tạm giữ đơn để xác minh thêm thông tin.',
            'Khách nên kiểm tra kỹ nội dung chuyển khoản, mã đơn và tổng tiền để quá trình đối soát diễn ra nhanh hơn.',
          ],
        ),
      ],
      notesTitle: 'Hỗ trợ thanh toán',
      notes: [
        'Giữ lại xác nhận chuyển khoản hoặc ảnh chụp giao dịch cho tới khi đơn được xác nhận thành công.',
        'Voucher và ưu đãi chỉ có hiệu lực khi được áp dụng hợp lệ trên đơn trước bước xác nhận cuối cùng.',
        'Nếu cần xuất hóa đơn hoặc hỗ trợ đối soát doanh nghiệp, vui lòng liên hệ cửa hàng ngay sau khi đặt đơn.',
      ],
    );
    return _PolicyScreen(policy: policy, showTopHeader: showTopHeader);
  }
}

class _PolicyScreen extends StatelessWidget {
  const _PolicyScreen({
    required this.policy,
    required this.showTopHeader,
  });

  final _PolicyContent policy;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return isMobile
            ? _PolicyMobile(policy: policy, showTopHeader: showTopHeader)
            : _PolicyWeb(policy: policy, showTopHeader: showTopHeader);
      },
    );
  }
}

class _PolicyWeb extends StatelessWidget {
  const _PolicyWeb({
    required this.policy,
    required this.showTopHeader,
  });

  final _PolicyContent policy;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1240,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: PolicyColors.bodyBg,
          border: Border.all(color: PolicyColors.gray, width: 2),
        ),
        child: Column(
          children: [
            if (showTopHeader)
              PixelHeaderBar(
                rightLabel: policy.pageLabel,
                showBack: true,
                showBrand: false,
                backFallbackRoute: AppRoutePaths.home,
              ),
            if (showTopHeader) const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _heroCard(isMobile: false),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 7,
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < policy.sections.length;
                                  index++) ...[
                                _sectionCard(policy.sections[index]),
                                if (index != policy.sections.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Column(
                            children: [
                              _highlightsCard(isMobile: false),
                              const SizedBox(height: 12),
                              _notesCard(),
                              const SizedBox(height: 12),
                              _supportCard(context),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const PixelFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard({required bool isMobile}) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(policy.heroTitle, PolicyColors.blue, isMobile ? 18 : 22,
                FontWeight.w900),
            const SizedBox(height: 6),
            _txt(
              policy.heroDescription,
              PolicyColors.gray,
              isMobile ? 12 : 13,
              FontWeight.w500,
            ),
          ],
        ),
      );

  Widget _sectionCard(_PolicySection section) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(section.title, PolicyColors.blue, 16, FontWeight.w800),
            const SizedBox(height: 10),
            for (var index = 0; index < section.items.length; index++) ...[
              _txt(
                '• ${section.items[index]}',
                PolicyColors.textDark,
                13,
                FontWeight.w500,
              ),
              if (index != section.items.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );

  Widget _highlightsCard({required bool isMobile}) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Thông tin nhanh', PolicyColors.blue, 15, FontWeight.w800),
            const SizedBox(height: 10),
            for (var index = 0; index < policy.highlightCards.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == policy.highlightCards.length - 1 ? 0 : 10,
                ),
                child: _highlightBox(
                  policy.highlightCards[index],
                  compact: isMobile,
                ),
              ),
          ],
        ),
      );

  Widget _notesCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(policy.notesTitle, PolicyColors.red, 15, FontWeight.w800),
            const SizedBox(height: 10),
            for (var index = 0; index < policy.notes.length; index++) ...[
              _txt(
                '• ${policy.notes[index]}',
                PolicyColors.textDark,
                12,
                FontWeight.w500,
              ),
              if (index != policy.notes.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );

  Widget _supportCard(BuildContext context) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Cần hỗ trợ thêm?', PolicyColors.blue, 15, FontWeight.w800),
            const SizedBox(height: 6),
            _txt(
              'Nếu cần xác nhận trường hợp cụ thể, hãy liên hệ cửa hàng hoặc quay lại checkout để xem thông tin phí và phương thức áp dụng trên đơn hiện tại.',
              PolicyColors.gray,
              12,
              FontWeight.w500,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Liên hệ',
                    color: PolicyColors.blue,
                    onTap: () => context.goNamed(AppRouteNames.contact),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _actionButton(
                    label: 'Đặt đơn',
                    color: PolicyColors.red,
                    onTap: () => context.goNamed(AppRouteNames.menu),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _PolicyMobile extends StatelessWidget {
  const _PolicyMobile({
    required this.policy,
    required this.showTopHeader,
  });

  final _PolicyContent policy;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: PolicyColors.bodyBg,
          border: Border.all(color: PolicyColors.gray, width: 2),
        ),
        child: Column(
          children: [
            if (showTopHeader)
              PixelHeaderBar(
                rightLabel: policy.pageLabel,
                showBack: true,
                showBrand: false,
                backFallbackRoute: AppRoutePaths.home,
              ),
            if (showTopHeader) const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _heroCard(),
                  const SizedBox(height: 10),
                  _highlightsCard(),
                  const SizedBox(height: 10),
                  for (final section in policy.sections) ...[
                    _sectionCard(section),
                    const SizedBox(height: 10),
                  ],
                  _notesCard(),
                  const SizedBox(height: 10),
                  _supportCard(context),
                  const SizedBox(height: 12),
                  const PixelFooter(mobile: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(policy.heroTitle, PolicyColors.blue, 18, FontWeight.w900),
            const SizedBox(height: 6),
            _txt(
                policy.heroDescription, PolicyColors.gray, 12, FontWeight.w500),
          ],
        ),
      );

  Widget _highlightsCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Thông tin nhanh', PolicyColors.blue, 14, FontWeight.w800),
            const SizedBox(height: 10),
            for (var index = 0; index < policy.highlightCards.length; index++)
              Padding(
                padding: EdgeInsets.only(
                  bottom: index == policy.highlightCards.length - 1 ? 0 : 8,
                ),
                child: _highlightBox(
                  policy.highlightCards[index],
                  compact: true,
                ),
              ),
          ],
        ),
      );

  Widget _sectionCard(_PolicySection section) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(section.title, PolicyColors.blue, 14, FontWeight.w800),
            const SizedBox(height: 8),
            for (var index = 0; index < section.items.length; index++) ...[
              _txt(
                '• ${section.items[index]}',
                PolicyColors.textDark,
                12,
                FontWeight.w500,
              ),
              if (index != section.items.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );

  Widget _notesCard() => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(policy.notesTitle, PolicyColors.red, 14, FontWeight.w800),
            const SizedBox(height: 8),
            for (var index = 0; index < policy.notes.length; index++) ...[
              _txt(
                '• ${policy.notes[index]}',
                PolicyColors.textDark,
                12,
                FontWeight.w500,
              ),
              if (index != policy.notes.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      );

  Widget _supportCard(BuildContext context) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Cần hỗ trợ thêm?', PolicyColors.blue, 14, FontWeight.w800),
            const SizedBox(height: 6),
            _txt(
              'Liên hệ Pixel Bakery nếu bạn cần xác nhận đơn gấp, đối soát thanh toán hoặc kiểm tra phạm vi giao hàng.',
              PolicyColors.gray,
              12,
              FontWeight.w500,
            ),
            const SizedBox(height: 12),
            _actionButton(
              label: 'Liên hệ cửa hàng',
              color: PolicyColors.blue,
              onTap: () => context.goNamed(AppRouteNames.contact),
            ),
            const SizedBox(height: 8),
            _actionButton(
              label: 'Xem thực đơn',
              color: PolicyColors.red,
              onTap: () => context.goNamed(AppRouteNames.menu),
            ),
          ],
        ),
      );
}

Widget _highlightBox(_PolicyHighlight item, {required bool compact}) =>
    Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: item.accent, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt(item.title, item.accent, compact ? 12 : 13, FontWeight.w800),
          const SizedBox(height: 6),
          _txt(
            item.value,
            PolicyColors.textDark,
            compact ? 11 : 12,
            FontWeight.w500,
          ),
        ],
      ),
    );

Widget _card({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PolicyColors.softGray, width: 1.5),
      ),
      child: child,
    );

Widget _actionButton({
  required String label,
  required Color color,
  required VoidCallback onTap,
}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PolicyColors.gray, width: 1),
        ),
        child: _txt(label, Colors.white, 12, FontWeight.w800),
      ),
    );

Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: 1.45,
      ),
    );

class _PolicyContent {
  const _PolicyContent({
    required this.pageLabel,
    required this.heroTitle,
    required this.heroDescription,
    required this.highlightCards,
    required this.sections,
    required this.notesTitle,
    required this.notes,
  });

  final String pageLabel;
  final String heroTitle;
  final String heroDescription;
  final List<_PolicyHighlight> highlightCards;
  final List<_PolicySection> sections;
  final String notesTitle;
  final List<String> notes;
}

class _PolicyHighlight {
  const _PolicyHighlight({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;
}

class _PolicySection {
  const _PolicySection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;
}
