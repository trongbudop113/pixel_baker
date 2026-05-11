import 'ui_accent.dart';

class OrderItem {
  const OrderItem({
    required this.name,
    required this.qty,
  });

  final String name;
  final int qty;
}

class OrderModel {
  const OrderModel({
    required this.code,
    required this.customer,
    required this.phone,
    required this.address,
    required this.status,
    required this.statusColorKey,
    required this.total,
    required this.items,
  });

  final String code;
  final String customer;
  final String phone;
  final String address;
  final String status;
  final String statusColorKey;
  final int total;
  final List<OrderItem> items;
}

class OrdersInfoSection {
  const OrdersInfoSection({
    required this.title,
    required this.items,
    this.emphasizedLast = false,
  });

  final String title;
  final List<String> items;
  final bool emphasizedLast;
}

class OrderStatusInfo {
  const OrderStatusInfo({
    required this.label,
    required this.description,
    required this.accent,
  });

  final String label;
  final String description;
  final UiAccent accent;
}
