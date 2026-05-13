import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/models/ui_accent.dart';
import '../../app/models/voucher_models.dart';
import '../../app/routing/app_router.dart';
import '../../app/state/screen_controller.dart';
import '../shared/app_header.dart';
import '../shared/pixel_footer.dart';
import 'voucher_state.dart';

class VoucherColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
}

Color _voucherColor(UiAccent accent) {
  switch (accent) {
    case UiAccent.red:
      return VoucherColors.red;
    case UiAccent.blue:
      return VoucherColors.blue;
    case UiAccent.green:
      return VoucherColors.green;
    case UiAccent.gray:
      return VoucherColors.gray;
    case UiAccent.orange:
      return VoucherColors.red;
  }
}

class ResponsiveVoucherScreen extends StatefulWidget {
  const ResponsiveVoucherScreen({super.key, this.showTopHeader = true});
  final bool showTopHeader;

  @override
  State<ResponsiveVoucherScreen> createState() =>
      _ResponsiveVoucherScreenState();
}

class _ResponsiveVoucherScreenState extends State<ResponsiveVoucherScreen> {
  final VoucherState _voucherState = VoucherState();

  @override
  void initState() {
    super.initState();
    _voucherState.load();
  }

  @override
  void dispose() {
    _voucherState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerEffectListener<VoucherState, VoucherEffect>(
      controller: _voucherState,
      listener: (context, effect) {
        if (effect == VoucherEffect.login) {
          context.goNamed(AppRouteNames.login);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return isMobile
              ? MobileVoucherLayout(
                  state: _voucherState, showTopHeader: widget.showTopHeader)
              : WebVoucherLayout(
                  state: _voucherState, showTopHeader: widget.showTopHeader);
        },
      ),
    );
  }
}

class WebVoucherLayout extends StatelessWidget {
  final VoucherState state;
  final bool showTopHeader;
  const WebVoucherLayout(
      {super.key, required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => SizedBox(
        width: 1200,
        height: double.infinity,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: VoucherColors.gray, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showTopHeader)
                const PixelHeaderBar(
                    rightLabel: 'voucher', showBack: true, showBrand: false),
              if (showTopHeader) const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _title(),
                      if (state.message != null) ...[
                        const SizedBox(height: 12),
                        _messageBanner(state.message!, state.isSuccess),
                      ],
                      const SizedBox(height: 12),
                      ...List.generate(state.vouchers.length, (index) {
                        final voucher = state.vouchers[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == state.vouchers.length - 1 ? 0 : 10,
                          ),
                          child: _voucher(index, voucher),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const PixelFooter(label: 'PIXEL BAKERY | VOUCHER'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title() => Text(
        'Voucher Web',
        style: TextStyle(
            color: VoucherColors.blue,
            fontSize: 30,
            fontWeight: FontWeight.w900),
      );

  Widget _voucher(int index, VoucherModel voucher) {
    final color = _voucherColor(voucher.accent);
    return GestureDetector(
      onTap: () => state.selectVoucher(index),
      child: ControllerSelector<VoucherState, int>(
        controller: state,
        selector: (controller) => controller.selectedVoucherIndex,
        builder: (context, selectedVoucherIndex, _) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedVoucherIndex == index ? color : VoucherColors.gray,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 130,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: VoucherColors.gray, width: 2),
                ),
                child: Text(voucher.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(voucher.title,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(voucher.note,
                        style: TextStyle(
                            color: VoucherColors.gray,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ],
                ),
              ),
              Container(
                width: 110,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color:
                      selectedVoucherIndex == index ? color : VoucherColors.red,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: VoucherColors.gray, width: 2),
                ),
                child: GestureDetector(
                  onTap: state.collectSelectedVoucher,
                  child: Text(
                    voucher.used
                        ? 'Đã dùng'
                        : voucher.collected
                        ? 'Đã lưu'
                        : (state.isSubmitting &&
                                state.selectedVoucherIndex == index
                            ? 'Đang lưu'
                            : 'Thu thập'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _messageBanner(String message, bool success) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: success ? const Color(0xFFEFF8F1) : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: success ? VoucherColors.green : VoucherColors.red,
            width: 2,
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: success ? VoucherColors.green : VoucherColors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class MobileVoucherLayout extends StatelessWidget {
  final VoucherState state;
  final bool showTopHeader;
  const MobileVoucherLayout(
      {super.key, required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: VoucherColors.gray, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                  rightLabel: 'voucher', showBack: true, showBrand: false),
            if (showTopHeader) const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Mobile Voucher',
                        style: TextStyle(
                            color: VoucherColors.blue,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                    if (state.message != null) ...[
                      const SizedBox(height: 10),
                      _mobileMessageBanner(state.message!, state.isSuccess),
                    ],
                    const SizedBox(height: 10),
                    ...List.generate(state.vouchers.length * 2 - 1, (index) {
                      if (index.isOdd) return const SizedBox(height: 8);
                      final voucher = state.vouchers[index ~/ 2];
                      return _card(index ~/ 2, voucher);
                    }),
                  ],
                ),
              ),
            ),
            const PixelFooter(label: 'PIXEL BAKERY | VOUCHER', mobile: true),
          ],
        ),
      ),
    );
  }

  Widget _card(int index, VoucherModel voucher) {
    final color = _voucherColor(voucher.accent);
    return GestureDetector(
      onTap: () => state.selectVoucher(index),
      child: ControllerSelector<VoucherState, int>(
        controller: state,
        selector: (controller) => controller.selectedVoucherIndex,
        builder: (context, selectedVoucherIndex, _) => Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedVoucherIndex == index ? color : VoucherColors.gray,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 95,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: VoucherColors.gray, width: 2),
                ),
                child: Text(voucher.code,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(voucher.title,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: state.collectSelectedVoucher,
                      child: Text(
                        voucher.used
                            ? 'Đã dùng'
                            : voucher.collected
                            ? 'Đã lưu'
                            : (state.isSubmitting &&
                                    state.selectedVoucherIndex == index
                                ? 'Đang lưu'
                                : 'Thu thập'),
                        style: TextStyle(
                          color:
                              voucher.collected ? VoucherColors.green : VoucherColors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileMessageBanner(String message, bool success) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: success ? const Color(0xFFEFF8F1) : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: success ? VoucherColors.green : VoucherColors.red,
            width: 2,
          ),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: success ? VoucherColors.green : VoucherColors.red,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
