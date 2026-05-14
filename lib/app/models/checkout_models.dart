import 'cart_models.dart';

class CheckoutPaymentMethod {
  static const cod = 'cod';
  static const bankTransfer = 'bank_transfer';

  static String labelOf(String code) {
    switch (code) {
      case bankTransfer:
        return 'Chuyển khoản ngân hàng';
      case cod:
      default:
        return 'Thanh toán khi nhận hàng (COD)';
    }
  }
}

class OrderPaymentStatus {
  static const pendingCod = 'pending_cod';
  static const awaitingTransfer = 'awaiting_transfer';
  static const paid = 'paid';
  static const cancelled = 'cancelled';
  static const refundPending = 'refund_pending';
  static const refunded = 'refunded';
}

class CheckoutRequestModel {
  const CheckoutRequestModel({
    required this.paymentMethod,
    required this.deliveryFee,
    required this.items,
    this.voucherCode,
    this.customerUserId,
    this.orderNote,
    this.deliveryDate,
    this.deliveryTimeSlot,
  });

  final String paymentMethod;
  final int deliveryFee;
  final List<CartItem> items;
  final String? voucherCode;
  final String? customerUserId;
  final String? orderNote;
  final String? deliveryDate;
  final String? deliveryTimeSlot;

  Map<String, dynamic> toJson() {
    return {
      'paymentMethod': paymentMethod,
      'deliveryFee': deliveryFee,
      'voucherCode': voucherCode,
      'customerUserId': customerUserId,
      'orderNote': orderNote,
      'deliveryDate': deliveryDate,
      'deliveryTimeSlot': deliveryTimeSlot,
      'items': items
          .map(
            (item) => {
              'productId': item.productId,
              'title': item.title,
              'priceValue': item.priceValue,
              'quantity': item.quantity,
              'category': item.category,
              'imageUrl': item.imageUrl,
              'price': item.price,
              'variantKey': item.variantKey,
              'variantLabel': item.variantLabel,
              'boxItems': item.boxItems
                  .map((entry) => entry.toJson())
                  .toList(growable: false),
            },
          )
          .toList(growable: false),
    };
  }
}

class BankTransferInfoModel {
  const BankTransferInfoModel({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.transferNotePrefix,
  });

  final String bankName;
  final String accountName;
  final String accountNumber;
  final String transferNotePrefix;

  factory BankTransferInfoModel.fromJson(Map<String, dynamic> json) {
    return BankTransferInfoModel(
      bankName: (json['bankName'] ?? '').toString(),
      accountName: (json['accountName'] ?? '').toString(),
      accountNumber: (json['accountNumber'] ?? '').toString(),
      transferNotePrefix: (json['transferNotePrefix'] ?? '').toString(),
    );
  }
}

class OrderTimelineEntryModel {
  const OrderTimelineEntryModel({
    required this.code,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  final String code;
  final String title;
  final String description;
  final String createdAt;

  factory OrderTimelineEntryModel.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEntryModel(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class IngredientShortageModel {
  const IngredientShortageModel({
    required this.ingredientId,
    required this.ingredientName,
    required this.requiredQuantity,
    required this.availableQuantity,
    required this.unit,
  });

  final String ingredientId;
  final String ingredientName;
  final int requiredQuantity;
  final int availableQuantity;
  final String unit;

  factory IngredientShortageModel.fromJson(Map<String, dynamic> json) {
    return IngredientShortageModel(
      ingredientId: (json['ingredientId'] ?? '').toString(),
      ingredientName: (json['ingredientName'] ?? '').toString(),
      requiredQuantity: (json['requiredQuantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      unit: (json['unit'] ?? '').toString(),
    );
  }
}

class CheckoutValidationModel {
  const CheckoutValidationModel({
    required this.canCheckout,
    required this.subtotal,
    required this.deliveryFee,
    required this.discountAmount,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.message,
    this.voucherCode,
    this.bankTransferInfo,
    this.shortages = const [],
    this.paymentGateway,
    this.paymentActionUrl,
  });

  final bool canCheckout;
  final int subtotal;
  final int deliveryFee;
  final int discountAmount;
  final int total;
  final String paymentMethod;
  final String paymentStatus;
  final String message;
  final String? voucherCode;
  final BankTransferInfoModel? bankTransferInfo;
  final List<IngredientShortageModel> shortages;
  final String? paymentGateway;
  final String? paymentActionUrl;

  factory CheckoutValidationModel.fromJson(Map<String, dynamic> json) {
    return CheckoutValidationModel(
      canCheckout: json['canCheckout'] == true,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      voucherCode: json['voucherCode']?.toString(),
      bankTransferInfo: json['bankTransferInfo'] is Map<String, dynamic>
          ? BankTransferInfoModel.fromJson(
              Map<String, dynamic>.from(json['bankTransferInfo'] as Map),
            )
          : null,
      paymentGateway: json['paymentGateway']?.toString(),
      paymentActionUrl: json['paymentActionUrl']?.toString(),
      shortages: ((json['shortages'] as List?) ?? const [])
          .map((item) => IngredientShortageModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }
}

class CheckoutItemResult {
  const CheckoutItemResult({
    required this.productId,
    required this.title,
    required this.priceValue,
    required this.quantity,
    required this.lineTotal,
    this.category,
    this.imageUrl,
    this.price,
    this.variantKey,
    this.variantLabel,
    this.boxItems = const [],
  });

  final int productId;
  final String title;
  final int priceValue;
  final int quantity;
  final int lineTotal;
  final String? category;
  final String? imageUrl;
  final String? price;
  final String? variantKey;
  final String? variantLabel;
  final List<CartBoxItem> boxItems;

  factory CheckoutItemResult.fromJson(Map<String, dynamic> json) {
    return CheckoutItemResult(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      price: json['price']?.toString(),
      variantKey: json['variantKey']?.toString(),
      variantLabel: json['variantLabel']?.toString(),
      boxItems: ((json['boxItems'] as List?) ?? const [])
          .map((item) => CartBoxItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemCount,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.total,
    this.voucherCode,
    required this.items,
    required this.message,
    this.timeline = const [],
    this.invoiceHtml,
    this.bankTransferInfo,
    this.paymentGateway,
    this.paymentActionUrl,
    this.canCancel = false,
    this.canConfirmTransfer = false,
    this.canRequestRefund = false,
  });

  final String orderId;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int itemCount;
  final int subtotal;
  final int discountAmount;
  final int deliveryFee;
  final int total;
  final String? voucherCode;
  final List<CheckoutItemResult> items;
  final String message;
  final List<OrderTimelineEntryModel> timeline;
  final String? invoiceHtml;
  final BankTransferInfoModel? bankTransferInfo;
  final String? paymentGateway;
  final String? paymentActionUrl;
  final bool canCancel;
  final bool canConfirmTransfer;
  final bool canRequestRefund;

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      orderId: (json['orderId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      voucherCode: json['voucherCode']?.toString(),
      items: ((json['items'] as List?) ?? const [])
          .map((item) => CheckoutItemResult.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      message: (json['message'] ?? '').toString(),
      timeline: ((json['timeline'] as List?) ?? const [])
          .map((item) => OrderTimelineEntryModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      invoiceHtml: json['invoiceHtml']?.toString(),
      bankTransferInfo: json['bankTransferInfo'] is Map<String, dynamic>
          ? BankTransferInfoModel.fromJson(
              Map<String, dynamic>.from(json['bankTransferInfo'] as Map),
            )
          : null,
      paymentGateway: json['paymentGateway']?.toString(),
      paymentActionUrl: json['paymentActionUrl']?.toString(),
      canCancel: json['canCancel'] == true,
      canConfirmTransfer: json['canConfirmTransfer'] == true,
      canRequestRefund: json['canRequestRefund'] == true,
    );
  }
}

class CartSyncResult {

  const CartSyncResult({
    required this.items,
    required this.itemCount,
    required this.subtotal,
  });

  final List<CartItem> items;
  final int itemCount;
  final int subtotal;

  factory CartSyncResult.fromJson(Map<String, dynamic> json) {
    final items = ((json['items'] as List?) ?? const [])
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);
          return CartItem(
            productId: (map['productId'] as num?)?.toInt() ?? 0,
            title: (map['title'] ?? '').toString(),
            price: map['price']?.toString() ?? '',
            priceValue: (map['priceValue'] as num?)?.toInt() ?? 0,
            category: map['category']?.toString() ?? '',
            imageUrl: map['imageUrl']?.toString() ?? '',
            quantity: (map['quantity'] as num?)?.toInt() ?? 0,
            variantKey: map['variantKey']?.toString(),
            variantLabel: map['variantLabel']?.toString(),
            boxItems: ((map['boxItems'] as List?) ?? const [])
                .map((item) => CartBoxItem.fromJson(Map<String, dynamic>.from(item as Map)))
                .toList(growable: false),
          );
        })
        .toList(growable: false);
    return CartSyncResult(
      items: items,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
    );
  }
}

class OrderSummaryModel {
  const OrderSummaryModel({
    required this.orderId,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemCount,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.voucherCode,
  });

  final String orderId;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int itemCount;
  final int subtotal;
  final int discountAmount;
  final int deliveryFee;
  final int total;
  final String createdAt;
  final String? voucherCode;

  factory OrderSummaryModel.fromJson(Map<String, dynamic> json) {
    return OrderSummaryModel(
      orderId: (json['orderId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] ?? '').toString(),
      voucherCode: json['voucherCode']?.toString(),
    );
  }
}

class OrderDetailItemModel {
  const OrderDetailItemModel({
    required this.productId,
    required this.title,
    required this.priceValue,
    required this.quantity,
    required this.lineTotal,
    this.category,
    this.imageUrl,
    this.price,
    this.variantKey,
    this.variantLabel,
    this.boxItems = const [],
  });

  final int productId;
  final String title;
  final int priceValue;
  final int quantity;
  final int lineTotal;
  final String? category;
  final String? imageUrl;
  final String? price;
  final String? variantKey;
  final String? variantLabel;
  final List<CartBoxItem> boxItems;

  factory OrderDetailItemModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailItemModel(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      lineTotal: (json['lineTotal'] as num?)?.toInt() ?? 0,
      category: json['category']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      price: json['price']?.toString(),
      variantKey: json['variantKey']?.toString(),
      variantLabel: json['variantLabel']?.toString(),
      boxItems: ((json['boxItems'] as List?) ?? const [])
          .map((item) => CartBoxItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(growable: false),
    );
  }
}

class OrderDetailModel {
  const OrderDetailModel({
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.itemCount,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    required this.items,
    this.customerPhone,
    this.customerAddress,
    this.voucherCode,
    this.timeline = const [],
    this.invoiceHtml,
    this.bankTransferInfo,
    this.paymentGateway,
    this.paymentActionUrl,
    this.canCancel = false,
    this.canConfirmTransfer = false,
    this.canRequestRefund = false,
    this.orderNote,
    this.deliveryDate,
    this.deliveryTimeSlot,
  });

  final String orderId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final int itemCount;
  final int subtotal;
  final int discountAmount;
  final int deliveryFee;
  final int total;
  final String? voucherCode;
  final String createdAt;
  final List<OrderDetailItemModel> items;
  final List<OrderTimelineEntryModel> timeline;
  final String? invoiceHtml;
  final BankTransferInfoModel? bankTransferInfo;
  final String? paymentGateway;
  final String? paymentActionUrl;
  final bool canCancel;
  final bool canConfirmTransfer;
  final bool canRequestRefund;
  final String? orderNote;
  final String? deliveryDate;
  final String? deliveryTimeSlot;

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailModel(
      orderId: (json['orderId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      customerPhone: json['customerPhone']?.toString(),
      customerAddress: json['customerAddress']?.toString(),
      status: (json['status'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      voucherCode: json['voucherCode']?.toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
      items: ((json['items'] as List?) ?? const [])
          .map((item) => OrderDetailItemModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      timeline: ((json['timeline'] as List?) ?? const [])
          .map((item) => OrderTimelineEntryModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      invoiceHtml: json['invoiceHtml']?.toString(),
      bankTransferInfo: json['bankTransferInfo'] is Map<String, dynamic>
          ? BankTransferInfoModel.fromJson(
              Map<String, dynamic>.from(json['bankTransferInfo'] as Map),
            )
          : null,
      paymentGateway: json['paymentGateway']?.toString(),
      paymentActionUrl: json['paymentActionUrl']?.toString(),
      canCancel: json['canCancel'] == true,
      canConfirmTransfer: json['canConfirmTransfer'] == true,
      canRequestRefund: json['canRequestRefund'] == true,
      orderNote: json['orderNote']?.toString(),
      deliveryDate: json['deliveryDate']?.toString(),
      deliveryTimeSlot: json['deliveryTimeSlot']?.toString(),
    );
  }
}
