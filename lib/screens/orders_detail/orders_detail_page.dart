import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;

import '../../app/models/checkout_models.dart';
import '../shared/app_header.dart';
import '../shared/page_skeleton.dart';
import '../shared/pixel_footer.dart';
import 'orders_detail_state.dart';

class OrdersDetailColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF00A86B);
  static const orange = Color(0xFFD97706);
  static const gray = Color(0xFF8A8A8A);
  static const bodyBg = Color(0xFFF8F8F8);
  static const textDark = Color(0xFF222222);
  static const border = Color(0xFFD9D9D9);
}

class ResponsiveOrdersDetailScreen extends StatefulWidget {
  const ResponsiveOrdersDetailScreen({
    super.key,
    this.showTopHeader = true,
    this.orderId,
  });

  final bool showTopHeader;
  final String? orderId;

  @override
  State<ResponsiveOrdersDetailScreen> createState() =>
      _ResponsiveOrdersDetailScreenState();
}

class _ResponsiveOrdersDetailScreenState
    extends State<ResponsiveOrdersDetailScreen> {
  final OrdersDetailState _state = OrdersDetailState();

  @override
  void initState() {
    super.initState();
    _state.load(initialOrderId: widget.orderId);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return isMobile
            ? _OrdersDetailMobile(
                state: _state,
                showTopHeader: widget.showTopHeader,
              )
            : _OrdersDetailWeb(
                state: _state,
                showTopHeader: widget.showTopHeader,
              );
      },
    );
  }
}

class _OrdersDetailWeb extends StatelessWidget {
  const _OrdersDetailWeb({required this.state, this.showTopHeader = true});

  final OrdersDetailState state;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1280,
      color: OrdersDetailColors.bodyBg,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (showTopHeader)
            const PixelHeaderBar(
              rightLabel: 'Đơn hàng',
              showBack: true,
              showBrand: false,
            ),
          if (showTopHeader) const SizedBox(height: 12),
          Expanded(
            child: AnimatedBuilder(
              animation: state,
              builder: (context, _) {
                if (state.isLoading && state.filteredOrders.isEmpty) {
                  return const OrdersListSkeleton();
                }
                if (state.errorMessage != null && state.filteredOrders.isEmpty) {
                  return _CenteredMessage(
                    message: state.errorMessage!,
                    color: OrdersDetailColors.red,
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _SearchBar(state: state),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _CardSection(
                              title: 'Danh sách đơn hàng',
                              child: _OrdersList(state: state, compact: false),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CardSection(
                        title: 'Chi tiết đơn',
                        child: _OrderDetailPanel(
                          detail: state.selectedOrder,
                          isUpdating: state.isUpdating,
                          actionMessage: state.actionMessage,
                          errorMessage: state.errorMessage,
                          onConfirmTransfer: state.confirmSelectedBankTransfer,
                          onCancelOrder: state.cancelSelectedOrder,
                          onRequestRefund: state.requestRefundForSelectedOrder,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: state,
            builder: (context, _) => PixelFooter(
              label: state.selectedOrder != null
                  ? 'PIXEL BAKERY | ĐƠN ${state.selectedOrder!.orderId}'
                  : 'PIXEL BAKERY | ĐƠN HÀNG',
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdersDetailMobile extends StatelessWidget {
  const _OrdersDetailMobile({required this.state, this.showTopHeader = true});

  final OrdersDetailState state;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 390,
      color: OrdersDetailColors.bodyBg,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          if (showTopHeader)
            const PixelHeaderBar(
              rightLabel: 'Đơn hàng',
              showBack: true,
              showBrand: false,
            ),
          if (showTopHeader) const SizedBox(height: 10),
          Expanded(
            child: AnimatedBuilder(
              animation: state,
              builder: (context, _) {
                if (state.isLoading && state.filteredOrders.isEmpty) {
                  return const OrdersListSkeleton(compact: true);
                }
                if (state.errorMessage != null && state.filteredOrders.isEmpty) {
                  return _CenteredMessage(
                    message: state.errorMessage!,
                    color: OrdersDetailColors.red,
                  );
                }
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _SearchBar(state: state, compact: true),
                      const SizedBox(height: 10),
                      _CardSection(
                        title: 'Danh sách đơn hàng',
                        child: _OrdersList(state: state, compact: true),
                      ),
                      const SizedBox(height: 10),
                      _CardSection(
                        title: 'Chi tiết đơn',
                        child: _OrderDetailPanel(
                          detail: state.selectedOrder,
                          isUpdating: state.isUpdating,
                          actionMessage: state.actionMessage,
                          errorMessage: state.errorMessage,
                          onConfirmTransfer: state.confirmSelectedBankTransfer,
                          onCancelOrder: state.cancelSelectedOrder,
                          onRequestRefund: state.requestRefundForSelectedOrder,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          PixelFooter(
            mobile: true,
            label: state.selectedOrder != null
                ? 'PIXEL BAKERY | ĐƠN ${state.selectedOrder!.orderId}'
                : 'PIXEL BAKERY | ĐƠN HÀNG',
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.state, this.compact = false});

  final OrdersDetailState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 42 : 48,
      decoration: _box(),
      child: TextField(
        onChanged: state.setSearchKeyword,
        style: const TextStyle(fontSize: 12, color: OrdersDetailColors.textDark),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: compact ? 12 : 14,
          ),
          hintText: 'Tìm mã đơn hoặc trạng thái...',
          hintStyle: const TextStyle(fontSize: 12, color: OrdersDetailColors.gray),
          prefixIcon: const Icon(Icons.search_rounded, size: 16, color: OrdersDetailColors.gray),
          prefixIconConstraints: const BoxConstraints(minWidth: 36, minHeight: 0),
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.state, required this.compact});

  final OrdersDetailState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final orders = state.filteredOrders;
    if (orders.isEmpty) {
      return const _CenteredMessage(
        message: 'Không có đơn hàng phù hợp.',
        color: OrdersDetailColors.gray,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < orders.length; index++) ...[
          _OrderRow(
            order: orders[index],
            isSelected: index == state.selectedOrderIndex,
            compact: compact,
            onTap: () => state.selectOrderByFilteredIndex(index),
          ),
          if (index != orders.length - 1)
            SizedBox(height: compact ? 8 : 10),
        ],
      ],
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({
    required this.order,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  final OrderSummaryModel order;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: compact ? 10 : 12,
        ),
        decoration: _box(
          fill: isSelected ? const Color(0xFFEAF3FF) : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.orderId}',
                    style: const TextStyle(
                      color: OrdersDetailColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.createdAt),
                    style: const TextStyle(
                      color: OrdersDetailColors.gray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Text(
                _statusLabel(order.status),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _statusColor(order.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                _formatCurrency(order.total),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: OrdersDetailColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailPanel extends StatelessWidget {
  const _OrderDetailPanel({
    required this.detail,
    required this.isUpdating,
    required this.onConfirmTransfer,
    required this.onCancelOrder,
    required this.onRequestRefund,
    this.actionMessage,
    this.errorMessage,
  });

  final OrderDetailModel? detail;
  final bool isUpdating;
  final VoidCallback onConfirmTransfer;
  final VoidCallback onCancelOrder;
  final VoidCallback onRequestRefund;
  final String? actionMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (detail == null) {
      return const _CenteredMessage(
        message: 'Chọn một đơn hàng để xem chi tiết.',
        color: OrdersDetailColors.gray,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '#${detail!.orderId}',
                style: const TextStyle(
                  color: OrdersDetailColors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Builder(builder: (ctx) => IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              tooltip: 'Sao chép mã đơn',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: detail!.orderId));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép mã đơn hàng'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            )),
            if (detail!.invoiceHtml != null && detail!.invoiceHtml!.trim().isNotEmpty)
              TextButton(
                onPressed: () => _printInvoice(detail!.invoiceHtml!),
                child: const Text('In hóa đơn'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        _InfoLine(label: 'Trạng thái', value: _statusLabel(detail!.status)),
        _InfoLine(
          label: 'Thanh toán',
          value: CheckoutPaymentMethod.labelOf(detail!.paymentMethod),
        ),
        _InfoLine(
          label: 'Trạng thái thanh toán',
          value: _paymentStatusLabel(detail!.paymentStatus),
        ),
        _InfoLine(label: 'Ngày tạo', value: _formatDate(detail!.createdAt)),
        _InfoLine(label: 'Khách hàng', value: detail!.customerName),
        _InfoLine(label: 'Email', value: detail!.customerEmail),
        _InfoLine(label: 'SĐT', value: detail!.customerPhone ?? '-'),
        _InfoLine(label: 'Địa chỉ', value: detail!.customerAddress ?? '-'),
        if (detail!.deliveryDate != null && detail!.deliveryDate!.isNotEmpty)
          _InfoLine(label: 'Ngày giao', value: detail!.deliveryDate!),
        if (detail!.deliveryTimeSlot != null && detail!.deliveryTimeSlot!.isNotEmpty)
          _InfoLine(label: 'Khung giờ', value: detail!.deliveryTimeSlot!),
        if (detail!.orderNote != null && detail!.orderNote!.isNotEmpty)
          _InfoLine(label: 'Ghi chú', value: detail!.orderNote!),
        if (detail!.voucherCode != null && detail!.voucherCode!.isNotEmpty)
          _InfoLine(label: 'Voucher', value: detail!.voucherCode!),
        if ((detail!.pointsUsed) > 0)
          _InfoLine(
            label: 'Dùng điểm',
            value: '-${detail!.pointsUsed} điểm (-${_formatCurrency(detail!.pointsUsed * 1000)})',
            valueColor: const Color(0xFFD97706),
          ),
        if ((detail!.pointsEarned) > 0)
          _InfoLine(
            label: 'Điểm tích lũy',
            value: '+${detail!.pointsEarned} điểm',
            valueColor: const Color(0xFF00A86B),
          ),
        if (detail!.bankTransferInfo != null) ...[
          const SizedBox(height: 6),
          _InfoLine(label: 'Ngân hàng', value: detail!.bankTransferInfo!.bankName),
          _InfoLine(label: 'Số TK', value: detail!.bankTransferInfo!.accountNumber),
        ],
        if ((actionMessage ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            actionMessage!,
            style: const TextStyle(
              color: OrdersDetailColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if ((errorMessage ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: const TextStyle(
              color: OrdersDetailColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (detail!.canConfirmTransfer ||
            detail!.canCancel ||
            detail!.canRequestRefund) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (detail!.canConfirmTransfer)
                OutlinedButton(
                  onPressed: isUpdating ? null : onConfirmTransfer,
                  child: const Text('Xác nhận đã chuyển khoản'),
                ),
              if (detail!.canCancel)
                OutlinedButton(
                  onPressed: isUpdating ? null : onCancelOrder,
                  child: const Text('Hủy đơn'),
                ),
              if (detail!.canRequestRefund)
                OutlinedButton(
                  onPressed: isUpdating ? null : onRequestRefund,
                  child: const Text('Yêu cầu hoàn tiền'),
                ),
            ],
          ),
        ],
        const SizedBox(height: 10),
        const Text(
          'Timeline',
          style: TextStyle(
            color: OrdersDetailColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...detail!.timeline.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: _box(fill: const Color(0xFFF8F8F8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: const TextStyle(
                      color: OrdersDetailColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.description,
                    style: const TextStyle(
                      color: OrdersDetailColors.gray,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(entry.createdAt),
                    style: const TextStyle(
                      color: OrdersDetailColors.gray,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Sản phẩm',
          style: TextStyle(
            color: OrdersDetailColors.textDark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...detail!.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: _box(fill: const Color(0xFFF8F8F8)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.quantity}x ${item.title}',
                      style: const TextStyle(
                        color: OrdersDetailColors.textDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    _formatCurrency(item.lineTotal),
                    style: const TextStyle(
                      color: OrdersDetailColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _InfoLine(label: 'Tạm tính', value: _formatCurrency(detail!.subtotal)),
        _InfoLine(
          label: 'Giảm giá',
          value: _formatCurrency(detail!.discountAmount),
        ),
        _InfoLine(
          label: 'Phí giao hàng',
          value: _formatCurrency(detail!.deliveryFee),
        ),
        const SizedBox(height: 4),
        Text(
          'Tổng thanh toán: ${_formatCurrency(detail!.total)}',
          style: const TextStyle(
            color: OrdersDetailColors.red,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

void _printInvoice(String htmlContent) {
  if (!kIsWeb) {
    return;
  }
  final dynamic popup = html.window.open('', 'invoice-print');
  popup.document.write(htmlContent);
  popup.document.close();
  popup.focus();
  popup.print();
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: OrdersDetailColors.textDark,
            fontSize: 12,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: valueColor != null ? TextStyle(color: valueColor, fontWeight: FontWeight.w700) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  const _CardSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: OrdersDetailColors.blue,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

BoxDecoration _box({
  Color fill = Colors.white,
}) {
  return BoxDecoration(
    color: fill,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: OrdersDetailColors.border, width: 1),
  );
}

Color _statusColor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
    case 'completed':
    case 'delivered':
    case 'refunded':
      return OrdersDetailColors.green;
    case 'shipping':
    case 'pending':
    case 'processing':
    case 'awaiting_transfer':
    case 'pending_cod':
    case 'refund_pending':
      return OrdersDetailColors.orange;
    case 'cancelled':
    case 'failed':
      return OrdersDetailColors.red;
    default:
      return OrdersDetailColors.blue;
  }
}

String _statusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
      return 'Đã thanh toán';
    case 'awaiting_transfer':
      return 'Chờ chuyển khoản';
    case 'pending_cod':
      return 'Chờ thu cod';
    case 'refund_pending':
      return 'Chờ hoàn tiền';
    case 'refunded':
      return 'Đã hoàn tiền';
    case 'completed':
    case 'delivered':
      return 'Đã giao';
    case 'shipping':
      return 'Đang giao';
    case 'processing':
      return 'Đang xử lý';
    case 'pending':
      return 'Chờ xử lý';
    case 'cancelled':
      return 'Đã hủy';
    case 'failed':
      return 'Thất bại';
    default:
      return status;
  }
}

String _paymentStatusLabel(String status) {
  switch (status.trim().toLowerCase()) {
    case 'pending_cod':
      return 'Thanh toán khi nhận hàng';
    case 'awaiting_transfer':
      return 'Chờ chuyển khoản';
    case 'paid':
      return 'Đã thanh toán';
    case 'refund_pending':
      return 'Đang chờ hoàn tiền';
    case 'refunded':
      return 'Đã hoàn tiền';
    case 'cancelled':
      return 'Đã hủy thanh toán';
    default:
      return status;
  }
}

String _formatCurrency(int amount) {
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    final reverseIndex = digits.length - index;
    buffer.write(digits[index]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }
  return '${amount < 0 ? '-' : ''}${buffer.toString()}đ';
}

String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) {
    return raw;
  }
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year} $hour:$minute';
}
