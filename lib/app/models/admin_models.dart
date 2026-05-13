import 'menu_models.dart';

class AdminStatCardModel {
  const AdminStatCardModel({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final String tone;

  factory AdminStatCardModel.fromJson(Map<String, dynamic> json) {
    return AdminStatCardModel(
      label: (json['label'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      tone: (json['tone'] ?? '').toString(),
    );
  }
}

class AdminRecentOrderModel {
  const AdminRecentOrderModel({
    required this.orderId,
    required this.total,
    required this.status,
  });

  final String orderId;
  final int total;
  final String status;

  factory AdminRecentOrderModel.fromJson(Map<String, dynamic> json) {
    return AdminRecentOrderModel(
      orderId: (json['orderId'] ?? '').toString(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
    );
  }
}

class AdminAlertModel {
  const AdminAlertModel({
    required this.title,
    required this.description,
    required this.tone,
  });

  final String title;
  final String description;
  final String tone;

  factory AdminAlertModel.fromJson(Map<String, dynamic> json) {
    return AdminAlertModel(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      tone: (json['tone'] ?? '').toString(),
    );
  }
}

class AdminTabSummaryModel {
  const AdminTabSummaryModel({
    required this.title,
    required this.rows,
    this.buttonLabel,
    this.compact = false,
  });

  final String title;
  final List<String> rows;
  final String? buttonLabel;
  final bool compact;

  factory AdminTabSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminTabSummaryModel(
      title: (json['title'] ?? '').toString(),
      rows: ((json['rows'] as List?) ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      buttonLabel: json['buttonLabel']?.toString(),
      compact: json['compact'] == true,
    );
  }
}

class AdminDashboardModel {
  const AdminDashboardModel({
    required this.title,
    required this.notificationLabel,
    required this.statCards,
    required this.recentOrders,
    required this.alerts,
    required this.salesByHour,
    required this.topTrendLabel,
    required this.topTrendValue,
    required this.tabSummaries,
  });

  final String title;
  final String notificationLabel;
  final List<AdminStatCardModel> statCards;
  final List<AdminRecentOrderModel> recentOrders;
  final List<AdminAlertModel> alerts;
  final List<int> salesByHour;
  final String topTrendLabel;
  final String topTrendValue;
  final List<AdminTabSummaryModel> tabSummaries;

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    return AdminDashboardModel(
      title: (json['title'] ?? '').toString(),
      notificationLabel: (json['notificationLabel'] ?? '').toString(),
      statCards: ((json['statCards'] as List?) ?? const [])
          .map((item) => AdminStatCardModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      recentOrders: ((json['recentOrders'] as List?) ?? const [])
          .map((item) => AdminRecentOrderModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      alerts: ((json['alerts'] as List?) ?? const [])
          .map((item) => AdminAlertModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      salesByHour: ((json['salesByHour'] as List?) ?? const [])
          .map((item) => (item as num).toInt())
          .toList(growable: false),
      topTrendLabel: (json['topTrendLabel'] ?? '').toString(),
      topTrendValue: (json['topTrendValue'] ?? '').toString(),
      tabSummaries: ((json['tabSummaries'] as List?) ?? const [])
          .map((item) => AdminTabSummaryModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }
}

class AdminOrderModel {
  const AdminOrderModel({
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    required this.total,
    required this.status,
    required this.itemCount,
    required this.paymentMethod,
    required this.createdAt,
  });

  final String orderId;
  final String customerName;
  final String customerEmail;
  final int total;
  final String status;
  final int itemCount;
  final String paymentMethod;
  final String createdAt;

  factory AdminOrderModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderModel(
      orderId: (json['orderId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  AdminOrderModel copyWith({String? status}) {
    return AdminOrderModel(
      orderId: orderId,
      customerName: customerName,
      customerEmail: customerEmail,
      total: total,
      status: status ?? this.status,
      itemCount: itemCount,
      paymentMethod: paymentMethod,
      createdAt: createdAt,
    );
  }
}

class AdminOrderIngredientShortageModel {
  const AdminOrderIngredientShortageModel({
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

  factory AdminOrderIngredientShortageModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return AdminOrderIngredientShortageModel(
      ingredientId: (json['ingredientId'] ?? '').toString(),
      ingredientName: (json['ingredientName'] ?? '').toString(),
      requiredQuantity: (json['requiredQuantity'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      unit: (json['unit'] ?? '').toString(),
    );
  }
}

class AdminOrderAdvanceCheckModel {
  const AdminOrderAdvanceCheckModel({
    required this.orderId,
    required this.currentStatus,
    required this.nextStatus,
    required this.requiresInventoryConfirmation,
    required this.canAdvance,
    required this.message,
    this.shortages = const [],
  });

  final String orderId;
  final String currentStatus;
  final String nextStatus;
  final bool requiresInventoryConfirmation;
  final bool canAdvance;
  final String message;
  final List<AdminOrderIngredientShortageModel> shortages;

  factory AdminOrderAdvanceCheckModel.fromJson(Map<String, dynamic> json) {
    return AdminOrderAdvanceCheckModel(
      orderId: (json['orderId'] ?? '').toString(),
      currentStatus: (json['currentStatus'] ?? '').toString(),
      nextStatus: (json['nextStatus'] ?? '').toString(),
      requiresInventoryConfirmation:
          json['requiresInventoryConfirmation'] == true,
      canAdvance: json['canAdvance'] != false,
      message: (json['message'] ?? '').toString(),
      shortages: ((json['shortages'] as List?) ?? const [])
          .map(
            (item) => AdminOrderIngredientShortageModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(growable: false),
    );
  }
}

class AdminProductModel {
  const AdminProductModel({
    required this.id,
    required this.title,
    required this.category,
    required this.priceValue,
    required this.stockStatus,
    this.imageUrl,
  });

  final int id;
  final String title;
  final String category;
  final int priceValue;
  final String stockStatus;
  final String? imageUrl;

  factory AdminProductModel.fromJson(Map<String, dynamic> json) {
    return AdminProductModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      stockStatus: (json['stockStatus'] ?? '').toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  AdminProductModel copyWith({String? stockStatus, String? imageUrl}) {
    return AdminProductModel(
      id: id,
      title: title,
      category: category,
      priceValue: priceValue,
      stockStatus: stockStatus ?? this.stockStatus,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class AdminCustomerModel {
  const AdminCustomerModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    required this.orderCount,
    required this.isAdmin,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final int orderCount;
  final bool isAdmin;

  factory AdminCustomerModel.fromJson(Map<String, dynamic> json) {
    return AdminCustomerModel(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
      isAdmin: json['isAdmin'] == true,
    );
  }
}

class AdminCustomerDraft {
  const AdminCustomerDraft({
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
  });

  final String fullName;
  final String email;
  final String? phone;
  final String? address;

  factory AdminCustomerDraft.fromCustomer(AdminCustomerModel customer) {
    return AdminCustomerDraft(
      fullName: customer.fullName,
      email: customer.email,
      phone: customer.phone,
      address: customer.address,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
    };
  }
}

class AdminIngredientModel {
  const AdminIngredientModel({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.standardUnit,
    required this.conversionFactor,
    required this.unitPrice,
    required this.availableQuantity,
    required this.availableNormalizedQuantity,
    required this.lowStockThreshold,
    required this.lowStockThresholdNormalized,
    required this.status,
    required this.lastUpdatedAt,
  });

  final String id;
  final String name;
  final String category;
  final String unit;
  final String standardUnit;
  final int conversionFactor;
  final int unitPrice;
  final int availableQuantity;
  final int availableNormalizedQuantity;
  final int lowStockThreshold;
  final int lowStockThresholdNormalized;
  final String status;
  final String lastUpdatedAt;

  factory AdminIngredientModel.fromJson(Map<String, dynamic> json) {
    return AdminIngredientModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      standardUnit: (json['standardUnit'] ?? '').toString(),
      conversionFactor: (json['conversionFactor'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      availableNormalizedQuantity:
          (json['availableNormalizedQuantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 0,
      lowStockThresholdNormalized:
          (json['lowStockThresholdNormalized'] as num?)?.toInt() ?? 0,
      status: (json['status'] ?? '').toString(),
      lastUpdatedAt: (json['lastUpdatedAt'] ?? '').toString(),
    );
  }
}

class AdminIngredientDraft {
  const AdminIngredientDraft({
    required this.name,
    required this.category,
    required this.unit,
    required this.unitPrice,
    required this.availableQuantity,
    required this.lowStockThreshold,
  });

  final String name;
  final String category;
  final String unit;
  final int unitPrice;
  final int availableQuantity;
  final int lowStockThreshold;

  factory AdminIngredientDraft.fromIngredient(AdminIngredientModel ingredient) {
    return AdminIngredientDraft(
      name: ingredient.name,
      category: ingredient.category,
      unit: ingredient.unit,
      unitPrice: ingredient.unitPrice,
      availableQuantity: ingredient.availableQuantity,
      lowStockThreshold: ingredient.lowStockThreshold,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': category,
      'unit': unit,
      'unitPrice': unitPrice,
      'availableQuantity': availableQuantity,
      'lowStockThreshold': lowStockThreshold,
    };
  }
}

class AdminBulkImportResultModel {
  const AdminBulkImportResultModel({
    required this.message,
    required this.createdCount,
    required this.updatedCount,
    required this.errorCount,
    required this.errors,
    this.auditLogId,
  });

  final String message;
  final int createdCount;
  final int updatedCount;
  final int errorCount;
  final List<AdminImportValidationErrorModel> errors;
  final String? auditLogId;

  factory AdminBulkImportResultModel.fromJson(Map<String, dynamic> json) {
    return AdminBulkImportResultModel(
      message: (json['message'] ?? '').toString(),
      createdCount: (json['createdCount'] as num?)?.toInt() ?? 0,
      updatedCount: (json['updatedCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      errors: ((json['errors'] as List?) ?? const [])
          .map((item) => AdminImportValidationErrorModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      auditLogId: json['auditLogId']?.toString(),
    );
  }
}

class AdminImportValidationErrorModel {
  const AdminImportValidationErrorModel({
    required this.rowNumber,
    required this.field,
    required this.message,
    this.value,
  });

  final int rowNumber;
  final String field;
  final String message;
  final String? value;

  factory AdminImportValidationErrorModel.fromJson(Map<String, dynamic> json) {
    return AdminImportValidationErrorModel(
      rowNumber: (json['rowNumber'] as num?)?.toInt() ?? 0,
      field: (json['field'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      value: json['value']?.toString(),
    );
  }
}

class AdminImportAuditLogModel {
  const AdminImportAuditLogModel({
    required this.id,
    required this.entityType,
    required this.status,
    required this.createdCount,
    required this.updatedCount,
    required this.errorCount,
    required this.createdAt,
  });

  final String id;
  final String entityType;
  final String status;
  final int createdCount;
  final int updatedCount;
  final int errorCount;
  final String createdAt;

  factory AdminImportAuditLogModel.fromJson(Map<String, dynamic> json) {
    return AdminImportAuditLogModel(
      id: (json['id'] ?? '').toString(),
      entityType: (json['entityType'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdCount: (json['createdCount'] as num?)?.toInt() ?? 0,
      updatedCount: (json['updatedCount'] as num?)?.toInt() ?? 0,
      errorCount: (json['errorCount'] as num?)?.toInt() ?? 0,
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class AdminIngredientExcelRow {
  const AdminIngredientExcelRow({
    this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.unitPrice,
    required this.availableQuantity,
    required this.lowStockThreshold,
  });

  final String? id;
  final String name;
  final String category;
  final String unit;
  final int unitPrice;
  final int availableQuantity;
  final int lowStockThreshold;

  factory AdminIngredientExcelRow.fromJson(Map<String, dynamic> json) {
    return AdminIngredientExcelRow(
      id: json['id']?.toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      unit: (json['unit'] ?? '').toString(),
      unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
      availableQuantity: (json['availableQuantity'] as num?)?.toInt() ?? 0,
      lowStockThreshold: (json['lowStockThreshold'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'unit': unit,
      'unitPrice': unitPrice,
      'availableQuantity': availableQuantity,
      'lowStockThreshold': lowStockThreshold,
    };
  }
}

class AdminVoucherExcelRow {
  const AdminVoucherExcelRow({
    required this.code,
    required this.title,
    required this.note,
    required this.accent,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
  });

  final String code;
  final String title;
  final String note;
  final String accent;
  final String discountType;
  final int discountValue;
  final int minOrderValue;

  factory AdminVoucherExcelRow.fromJson(Map<String, dynamic> json) {
    return AdminVoucherExcelRow(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      accent: (json['accent'] ?? '').toString(),
      discountType: (json['discountType'] ?? '').toString(),
      discountValue: (json['discountValue'] as num?)?.toInt() ?? 0,
      minOrderValue: (json['minOrderValue'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'title': title,
        'note': note,
        'accent': accent,
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
      };
}

class AdminCustomerExcelRow {
  const AdminCustomerExcelRow({
    this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    required this.isAdmin,
  });

  final String? id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final bool isAdmin;

  factory AdminCustomerExcelRow.fromJson(Map<String, dynamic> json) {
    return AdminCustomerExcelRow(
      id: json['id']?.toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      isAdmin: json['isAdmin'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'address': address,
        'isAdmin': isAdmin,
      };
}

class AdminOrderExcelRow {
  const AdminOrderExcelRow({
    required this.orderId,
    this.userId,
    required this.customerName,
    required this.customerEmail,
    this.customerPhone,
    this.customerAddress,
    required this.paymentMethod,
    required this.status,
    required this.itemCount,
    required this.subtotal,
    required this.discountAmount,
    required this.deliveryFee,
    required this.total,
    this.voucherCode,
    required this.itemsJson,
    this.createdAt,
  });

  final String orderId;
  final String? userId;
  final String customerName;
  final String customerEmail;
  final String? customerPhone;
  final String? customerAddress;
  final String paymentMethod;
  final String status;
  final int itemCount;
  final int subtotal;
  final int discountAmount;
  final int deliveryFee;
  final int total;
  final String? voucherCode;
  final String itemsJson;
  final String? createdAt;

  factory AdminOrderExcelRow.fromJson(Map<String, dynamic> json) {
    return AdminOrderExcelRow(
      orderId: (json['orderId'] ?? '').toString(),
      userId: json['userId']?.toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      customerPhone: json['customerPhone']?.toString(),
      customerAddress: json['customerAddress']?.toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discountAmount'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      voucherCode: json['voucherCode']?.toString(),
      itemsJson: (json['itemsJson'] ?? '[]').toString(),
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'userId': userId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'customerAddress': customerAddress,
        'paymentMethod': paymentMethod,
        'status': status,
        'itemCount': itemCount,
        'subtotal': subtotal,
        'discountAmount': discountAmount,
        'deliveryFee': deliveryFee,
        'total': total,
        'voucherCode': voucherCode,
        'itemsJson': itemsJson,
        'createdAt': createdAt,
      };
}

class AdminProductExcelRow {
  const AdminProductExcelRow({
    this.id,
    required this.title,
    required this.category,
    required this.priceValue,
    required this.description,
    required this.images,
    required this.sku,
    required this.stockStatus,
    required this.weight,
    required this.storageNote,
    required this.deliveryNote,
    required this.detailBullets,
  });

  final int? id;
  final String title;
  final String category;
  final int priceValue;
  final String description;
  final String images;
  final String sku;
  final String stockStatus;
  final String weight;
  final String storageNote;
  final String deliveryNote;
  final String detailBullets;

  factory AdminProductExcelRow.fromJson(Map<String, dynamic> json) {
    return AdminProductExcelRow(
      id: (json['id'] as num?)?.toInt(),
      title: (json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      priceValue: (json['priceValue'] as num?)?.toInt() ?? 0,
      description: (json['description'] ?? '').toString(),
      images: (json['images'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      stockStatus: (json['stockStatus'] ?? '').toString(),
      weight: (json['weight'] ?? '').toString(),
      storageNote: (json['storageNote'] ?? '').toString(),
      deliveryNote: (json['deliveryNote'] ?? '').toString(),
      detailBullets: (json['detailBullets'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'priceValue': priceValue,
      'description': description,
      'images': images,
      'sku': sku,
      'stockStatus': stockStatus,
      'weight': weight,
      'storageNote': storageNote,
      'deliveryNote': deliveryNote,
      'detailBullets': detailBullets,
    };
  }
}

class AdminRecipeIngredientModel {
  const AdminRecipeIngredientModel({
    required this.ingredientId,
    required this.ingredientName,
    required this.sourceType,
    required this.unit,
    required this.quantity,
    required this.normalizedQuantity,
    required this.wastePercent,
    required this.unitPrice,
    required this.lineCost,
  });

  final String ingredientId;
  final String ingredientName;
  final String sourceType;
  final String unit;
  final int quantity;
  final int normalizedQuantity;
  final int wastePercent;
  final int unitPrice;
  final int lineCost;

  factory AdminRecipeIngredientModel.fromJson(Map<String, dynamic> json) {
    return AdminRecipeIngredientModel(
      ingredientId: (json['ingredientId'] ?? '').toString(),
      ingredientName: (json['ingredientName'] ?? '').toString(),
      sourceType: (json['sourceType'] ?? 'ingredient').toString(),
      unit: (json['unit'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      normalizedQuantity: (json['normalizedQuantity'] as num?)?.toInt() ?? 0,
      wastePercent: (json['wastePercent'] as num?)?.toInt() ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toInt() ?? 0,
      lineCost: (json['lineCost'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminRecipeModel {
  const AdminRecipeModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.recipeType,
    required this.yieldQuantity,
    required this.yieldUnit,
    required this.ingredients,
    required this.totalCost,
    required this.costPerUnit,
    required this.grossProfitEstimate,
    required this.grossMarginPercent,
    required this.createdAt,
  });

  final String id;
  final int productId;
  final String productTitle;
  final String recipeType;
  final int yieldQuantity;
  final String yieldUnit;
  final List<AdminRecipeIngredientModel> ingredients;
  final int totalCost;
  final int costPerUnit;
  final int grossProfitEstimate;
  final double grossMarginPercent;
  final String createdAt;

  factory AdminRecipeModel.fromJson(Map<String, dynamic> json) {
    return AdminRecipeModel(
      id: (json['id'] ?? '').toString(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productTitle: (json['productTitle'] ?? '').toString(),
      recipeType: (json['recipeType'] ?? 'finished').toString(),
      yieldQuantity: (json['yieldQuantity'] as num?)?.toInt() ?? 0,
      yieldUnit: (json['yieldUnit'] ?? '').toString(),
      ingredients: ((json['ingredients'] as List?) ?? const [])
          .map((item) => AdminRecipeIngredientModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      totalCost: (json['totalCost'] as num?)?.toInt() ?? 0,
      costPerUnit: (json['costPerUnit'] as num?)?.toInt() ?? 0,
      grossProfitEstimate: (json['grossProfitEstimate'] as num?)?.toInt() ?? 0,
      grossMarginPercent: (json['grossMarginPercent'] as num?)?.toDouble() ?? 0,
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class AdminRecipeReferenceModel {
  const AdminRecipeReferenceModel({
    required this.id,
    required this.productId,
    required this.productTitle,
    required this.recipeType,
    required this.yieldQuantity,
    required this.yieldUnit,
    required this.costPerUnit,
  });

  final String id;
  final int productId;
  final String productTitle;
  final String recipeType;
  final int yieldQuantity;
  final String yieldUnit;
  final int costPerUnit;

  factory AdminRecipeReferenceModel.fromJson(Map<String, dynamic> json) {
    return AdminRecipeReferenceModel(
      id: (json['id'] ?? '').toString(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productTitle: (json['productTitle'] ?? '').toString(),
      recipeType: (json['recipeType'] ?? '').toString(),
      yieldQuantity: (json['yieldQuantity'] as num?)?.toInt() ?? 0,
      yieldUnit: (json['yieldUnit'] ?? '').toString(),
      costPerUnit: (json['costPerUnit'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminRecipeExcelRow {
  const AdminRecipeExcelRow({
    this.id,
    required this.productId,
    required this.recipeType,
    required this.yieldQuantity,
    required this.yieldUnit,
    required this.ingredientsJson,
  });

  final String? id;
  final int productId;
  final String recipeType;
  final int yieldQuantity;
  final String yieldUnit;
  final String ingredientsJson;

  factory AdminRecipeExcelRow.fromJson(Map<String, dynamic> json) {
    return AdminRecipeExcelRow(
      id: json['id']?.toString(),
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      recipeType: (json['recipeType'] ?? 'finished').toString(),
      yieldQuantity: (json['yieldQuantity'] as num?)?.toInt() ?? 0,
      yieldUnit: (json['yieldUnit'] ?? '').toString(),
      ingredientsJson: (json['ingredientsJson'] ?? '[]').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'recipeType': recipeType,
        'yieldQuantity': yieldQuantity,
        'yieldUnit': yieldUnit,
        'ingredientsJson': ingredientsJson,
      };
}

class AdminRecipeOptionsModel {
  const AdminRecipeOptionsModel({
    required this.products,
    required this.ingredients,
    required this.recipeReferences,
  });

  final List<AdminProductModel> products;
  final List<AdminIngredientModel> ingredients;
  final List<AdminRecipeReferenceModel> recipeReferences;

  factory AdminRecipeOptionsModel.fromJson(Map<String, dynamic> json) {
    return AdminRecipeOptionsModel(
      products: ((json['products'] as List?) ?? const [])
          .map((item) => AdminProductModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      ingredients: ((json['ingredients'] as List?) ?? const [])
          .map((item) => AdminIngredientModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
      recipeReferences: ((json['recipeReferences'] as List?) ?? const [])
          .map((item) => AdminRecipeReferenceModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ))
          .toList(growable: false),
    );
  }
}

class AdminRecipeIngredientDraft {
  const AdminRecipeIngredientDraft({
    required this.ingredientId,
    this.sourceType = 'ingredient',
    required this.quantity,
    this.wastePercent = 0,
  });

  final String ingredientId;
  final String sourceType;
  final int quantity;
  final int wastePercent;

  Map<String, dynamic> toJson() {
    return {
      'ingredientId': ingredientId,
      'sourceType': sourceType,
      'quantity': quantity,
      'wastePercent': wastePercent,
    };
  }
}

class AdminRecipeDraft {
  const AdminRecipeDraft({
    required this.productId,
    this.recipeType = 'finished',
    required this.yieldQuantity,
    required this.yieldUnit,
    required this.ingredients,
  });

  final int productId;
  final String recipeType;
  final int yieldQuantity;
  final String yieldUnit;
  final List<AdminRecipeIngredientDraft> ingredients;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'recipeType': recipeType,
      'yieldQuantity': yieldQuantity,
      'yieldUnit': yieldUnit,
      'ingredients': ingredients.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class AdminInventoryTransactionModel {
  const AdminInventoryTransactionModel({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.transactionType,
    required this.quantityDelta,
    required this.unit,
    required this.normalizedQuantityDelta,
    required this.normalizedUnit,
    required this.balanceQuantity,
    required this.balanceNormalizedQuantity,
    this.referenceType,
    this.referenceId,
    this.note,
    required this.createdAt,
  });

  final String id;
  final String ingredientId;
  final String ingredientName;
  final String transactionType;
  final int quantityDelta;
  final String unit;
  final int normalizedQuantityDelta;
  final String normalizedUnit;
  final int balanceQuantity;
  final int balanceNormalizedQuantity;
  final String? referenceType;
  final String? referenceId;
  final String? note;
  final String createdAt;

  factory AdminInventoryTransactionModel.fromJson(Map<String, dynamic> json) {
    return AdminInventoryTransactionModel(
      id: (json['id'] ?? '').toString(),
      ingredientId: (json['ingredientId'] ?? '').toString(),
      ingredientName: (json['ingredientName'] ?? '').toString(),
      transactionType: (json['transactionType'] ?? '').toString(),
      quantityDelta: (json['quantityDelta'] as num?)?.toInt() ?? 0,
      unit: (json['unit'] ?? '').toString(),
      normalizedQuantityDelta:
          (json['normalizedQuantityDelta'] as num?)?.toInt() ?? 0,
      normalizedUnit: (json['normalizedUnit'] ?? '').toString(),
      balanceQuantity: (json['balanceQuantity'] as num?)?.toInt() ?? 0,
      balanceNormalizedQuantity:
          (json['balanceNormalizedQuantity'] as num?)?.toInt() ?? 0,
      referenceType: json['referenceType']?.toString(),
      referenceId: json['referenceId']?.toString(),
      note: json['note']?.toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }
}

class AdminProductCostReportModel {
  const AdminProductCostReportModel({
    required this.productId,
    required this.productTitle,
    required this.recipeType,
    required this.sellingPrice,
    required this.estimatedCost,
    required this.grossProfit,
    required this.grossMarginPercent,
  });

  final int productId;
  final String productTitle;
  final String recipeType;
  final int sellingPrice;
  final int estimatedCost;
  final int grossProfit;
  final double grossMarginPercent;

  factory AdminProductCostReportModel.fromJson(Map<String, dynamic> json) {
    return AdminProductCostReportModel(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productTitle: (json['productTitle'] ?? '').toString(),
      recipeType: (json['recipeType'] ?? '').toString(),
      sellingPrice: (json['sellingPrice'] as num?)?.toInt() ?? 0,
      estimatedCost: (json['estimatedCost'] as num?)?.toInt() ?? 0,
      grossProfit: (json['grossProfit'] as num?)?.toInt() ?? 0,
      grossMarginPercent: (json['grossMarginPercent'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdminRevenueDayModel {
  const AdminRevenueDayModel({
    required this.date,
    required this.revenue,
    required this.orderCount,
  });

  final String date;
  final int revenue;
  final int orderCount;

  factory AdminRevenueDayModel.fromJson(Map<String, dynamic> json) {
    return AdminRevenueDayModel(
      date: (json['date'] ?? '').toString(),
      revenue: (json['revenue'] as num?)?.toInt() ?? 0,
      orderCount: (json['orderCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminRevenueSummaryModel {
  const AdminRevenueSummaryModel({
    required this.range,
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.days,
  });

  final String range;
  final int totalRevenue;
  final int totalOrders;
  final int avgOrderValue;
  final List<AdminRevenueDayModel> days;

  factory AdminRevenueSummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminRevenueSummaryModel(
      range: (json['range'] ?? '7d').toString(),
      totalRevenue: (json['totalRevenue'] as num?)?.toInt() ?? 0,
      totalOrders: (json['totalOrders'] as num?)?.toInt() ?? 0,
      avgOrderValue: (json['avgOrderValue'] as num?)?.toInt() ?? 0,
      days: ((json['days'] as List?) ?? const [])
          .map((e) => AdminRevenueDayModel.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminRevenueSummaryModel &&
      other.range == range &&
      other.totalRevenue == totalRevenue &&
      other.totalOrders == totalOrders &&
      other.avgOrderValue == avgOrderValue &&
      other.days.length == days.length;

  @override
  int get hashCode => Object.hash(range, totalRevenue, totalOrders, avgOrderValue, days.length);
}

const defaultRevenueSummary = AdminRevenueSummaryModel(
  range: '7d',
  totalRevenue: 0,
  totalOrders: 0,
  avgOrderValue: 0,
  days: [],
);

class AdminProductDraft {
  const AdminProductDraft({
    required this.title,
    required this.category,
    required this.priceValue,
    required this.description,
    required this.images,
    required this.sku,
    required this.stockStatus,
    required this.weight,
    required this.storageNote,
    required this.deliveryNote,
    required this.detailBullets,
  });

  final String title;
  final String category;
  final int priceValue;
  final String description;
  final List<String> images;
  final String sku;
  final String stockStatus;
  final String weight;
  final String storageNote;
  final String deliveryNote;
  final List<String> detailBullets;

  factory AdminProductDraft.fromDetail(MenuProductDetail detail) {
    return AdminProductDraft(
      title: detail.title,
      category: detail.category,
      priceValue: detail.priceValue,
      description: detail.description,
      images: detail.images,
      sku: detail.sku,
      stockStatus: detail.stockStatus,
      weight: detail.weight,
      storageNote: detail.storageNote,
      deliveryNote: detail.deliveryNote,
      detailBullets: detail.detailBullets,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'priceValue': priceValue,
      'description': description,
      'images': images,
      'sku': sku,
      'stockStatus': stockStatus,
      'weight': weight,
      'storageNote': storageNote,
      'deliveryNote': deliveryNote,
      'detailBullets': detailBullets,
    };
  }
}

class AdminVoucherModel {
  const AdminVoucherModel({
    required this.code,
    required this.title,
    required this.note,
    required this.accent,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
  });

  final String code;
  final String title;
  final String note;
  final String accent;
  final String discountType;
  final int discountValue;
  final int minOrderValue;

  factory AdminVoucherModel.fromJson(Map<String, dynamic> json) {
    return AdminVoucherModel(
      code: (json['code'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      accent: (json['accent'] ?? '').toString(),
      discountType: (json['discountType'] ?? '').toString(),
      discountValue: (json['discountValue'] as num?)?.toInt() ?? 0,
      minOrderValue: (json['minOrderValue'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminVoucherDraft {
  const AdminVoucherDraft({
    required this.code,
    required this.title,
    required this.note,
    required this.accent,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
  });

  final String code;
  final String title;
  final String note;
  final String accent;
  final String discountType;
  final int discountValue;
  final int minOrderValue;

  factory AdminVoucherDraft.fromVoucher(AdminVoucherModel voucher) {
    return AdminVoucherDraft(
      code: voucher.code,
      title: voucher.title,
      note: voucher.note,
      accent: voucher.accent,
      discountType: voucher.discountType,
      discountValue: voucher.discountValue,
      minOrderValue: voucher.minOrderValue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
      'note': note,
      'accent': accent,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
    };
  }
}

class AdminTestimonialModel {
  const AdminTestimonialModel({
    required this.id,
    required this.content,
    required this.author,
    required this.accent,
    this.createdAt,
    this.isVisible = true,
  });

  final String id;
  final String content;
  final String author;
  final String accent;
  final String? createdAt;
  final bool isVisible;

  factory AdminTestimonialModel.fromJson(Map<String, dynamic> json) {
    return AdminTestimonialModel(
      id: (json['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      accent: (json['accent'] ?? '').toString(),
      createdAt: json['createdAt']?.toString(),
      isVisible: json['isVisible'] != false,
    );
  }
}

class AdminContentDocumentModel {
  const AdminContentDocumentModel({
    required this.key,
    required this.title,
    required this.jsonContent,
  });

  final String key;
  final String title;
  final String jsonContent;

  factory AdminContentDocumentModel.fromJson(Map<String, dynamic> json) {
    return AdminContentDocumentModel(
      key: (json['key'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      jsonContent: (json['jsonContent'] ?? '').toString(),
    );
  }
}

class AdminProductReviewModel {
  const AdminProductReviewModel({
    required this.productId,
    required this.productTitle,
    required this.author,
    required this.content,
    required this.rating,
    required this.createdAt,
  });

  final int productId;
  final String productTitle;
  final String author;
  final String content;
  final int rating;
  final String createdAt;

  factory AdminProductReviewModel.fromJson(Map<String, dynamic> json) {
    return AdminProductReviewModel(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productTitle: (json['productTitle'] ?? '').toString(),
      author: (json['author'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdminProductReviewModel &&
      other.productId == productId &&
      other.createdAt == createdAt;

  @override
  int get hashCode => Object.hash(productId, createdAt);
}

const defaultAdminDashboard = AdminDashboardModel(
  title: 'Dashboard Quản trị',
  notificationLabel: '0 thông báo',
  statCards: [
    AdminStatCardModel(label: 'Doanh thu hôm nay', value: '0đ', tone: 'default'),
    AdminStatCardModel(label: 'Đơn mới', value: '0', tone: 'default'),
    AdminStatCardModel(label: 'Khách mới', value: '+0', tone: 'success'),
    AdminStatCardModel(label: 'Tỷ lệ huỷ', value: '0%', tone: 'danger'),
  ],
  recentOrders: [],
  alerts: [],
  salesByHour: [0, 0, 0, 0],
  topTrendLabel: 'Doanh số theo tab',
  topTrendValue: 'Chưa có dữ liệu',
  tabSummaries: [],
);
