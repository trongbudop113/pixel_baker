import '../../app/models/order_models.dart';
import '../../app/models/ui_accent.dart';

class OrdersInfoState {
  final List<OrdersInfoSection> sections = const [
    OrdersInfoSection(
      title: 'SLA xử lý',
      items: [
        'Xác nhận đơn: <= 10 phút',
        'Chuẩn bị bánh: 20-45 phút',
        'Giao nội thành: <= 60 phút',
      ],
    ),
    OrdersInfoSection(
      title: 'Luồng trạng thái',
      items: [
        'Mới -> Xác nhận -> Đang làm',
        '-> Đang giao -> Hoàn tất',
        'Nhánh lỗi: Hoàn tiền / Huỷ',
      ],
      emphasizedLast: true,
    ),
    OrdersInfoSection(
      title: 'Lưu ý vận hành',
      items: [
        'Ưu tiên đơn có giờ hẹn',
        'Gọi xác nhận với COD > 500k',
        'Chụp ảnh lỗi trước khi hoàn tiền',
      ],
    ),
  ];

  final List<OrderStatusInfo> statuses = const [
    OrderStatusInfo(
      label: 'Mới',
      description: 'Đơn vừa tạo, chờ nhân viên xác nhận',
      accent: UiAccent.blue,
    ),
    OrderStatusInfo(
      label: 'Đang giao',
      description: 'Đơn đã rời bếp và đang trên đường',
      accent: UiAccent.orange,
    ),
    OrderStatusInfo(
      label: 'Hoàn tất',
      description: 'Khách đã nhận bánh thành công',
      accent: UiAccent.green,
    ),
  ];

  OrdersInfoSection get slaSection => sections[0];
  OrdersInfoSection get flowSection => sections[1];
  OrdersInfoSection get notesSection => sections[2];
}
