import 'ui_accent.dart';

class VoucherModel {
  const VoucherModel({
    required this.code,
    required this.title,
    required this.note,
    required this.accent,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    this.collected = false,
    this.used = false,
  });

  final String code;
  final String title;
  final String note;
  final UiAccent accent;
  final String discountType;
  final int discountValue;
  final int minOrderValue;
  final bool collected;
  final bool used;

  factory VoucherModel.fromJson(Map<String, dynamic> json) {
    return VoucherModel(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      accent: _accentFromString((json['accent'] ?? '').toString()),
      discountType: (json['discountType'] ?? '').toString(),
      discountValue: (json['discountValue'] as num?)?.toInt() ?? 0,
      minOrderValue: (json['minOrderValue'] as num?)?.toInt() ?? 0,
      collected: json['collected'] == true,
      used: json['used'] == true,
    );
  }

  VoucherModel copyWith({bool? collected, bool? used}) {
    return VoucherModel(
      code: code,
      title: title,
      note: note,
      accent: accent,
      discountType: discountType,
      discountValue: discountValue,
      minOrderValue: minOrderValue,
      collected: collected ?? this.collected,
      used: used ?? this.used,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'note': note,
      'accent': accent.name,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'collected': collected,
      'used': used,
    };
  }
}

class VoucherValidationResult {
  const VoucherValidationResult({
    required this.code,
    required this.discountAmount,
    required this.deliveryFeeAfterDiscount,
    required this.totalAfterDiscount,
    required this.message,
  });

  final String code;
  final int discountAmount;
  final int deliveryFeeAfterDiscount;
  final int totalAfterDiscount;
  final String message;

  factory VoucherValidationResult.fromJson(Map<String, dynamic> json) {
    return VoucherValidationResult(
      code: (json['code'] ?? '').toString(),
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      deliveryFeeAfterDiscount:
          (json['deliveryFeeAfterDiscount'] as num?)?.toInt() ?? 0,
      totalAfterDiscount: (json['totalAfterDiscount'] as num?)?.toInt() ?? 0,
      message: (json['message'] ?? '').toString(),
    );
  }
}

UiAccent _accentFromString(String value) {
  switch (value.toLowerCase()) {
    case 'blue':
      return UiAccent.blue;
    case 'green':
      return UiAccent.green;
    case 'gray':
      return UiAccent.gray;
    case 'orange':
      return UiAccent.orange;
    default:
      return UiAccent.red;
  }
}

const defaultVouchers = [
  VoucherModel(
    code: 'PIXEL15',
    title: 'Giảm 15% cho đơn đầu tiên',
    note: 'HSD: 31/12/2026',
    accent: UiAccent.red,
    discountType: 'percent',
    discountValue: 15,
    minOrderValue: 0,
  ),
  VoucherModel(
    code: 'FREESHIP20',
    title: 'Giảm 20.000đ phí vận chuyển',
    note: 'Đơn từ 149.000đ',
    accent: UiAccent.blue,
    discountType: 'shipping',
    discountValue: 20000,
    minOrderValue: 149000,
  ),
  VoucherModel(
    code: 'SWEET10',
    title: 'Giảm 10% cho combo bánh ngọt',
    note: 'Áp dụng thứ 2 - thứ 6',
    accent: UiAccent.green,
    discountType: 'percent',
    discountValue: 10,
    minOrderValue: 99000,
  ),
];
