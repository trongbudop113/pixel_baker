import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;

import '../models/admin_models.dart';

class AdminExcelCore {
  AdminExcelCore._();

  static const _productSheetName = 'Products';
  static const _ingredientSheetName = 'Ingredients';
  static const _voucherSheetName = 'Vouchers';
  static const _recipeSheetName = 'Recipes';
  static const _customerSheetName = 'Customers';
  static const _orderSheetName = 'Orders';

  static const List<String> _productHeaders = [
    'id',
    'title',
    'category',
    'priceValue',
    'description',
    'images',
    'sku',
    'stockStatus',
    'weight',
    'storageNote',
    'deliveryNote',
    'detailBullets',
  ];

  static const List<String> _ingredientHeaders = [
    'id',
    'name',
    'category',
    'unit',
    'unitPrice',
    'availableQuantity',
    'lowStockThreshold',
  ];

  static const List<String> _voucherHeaders = [
    'code',
    'title',
    'note',
    'accent',
    'discountType',
    'discountValue',
    'minOrderValue',
  ];

  static const List<String> _recipeHeaders = [
    'id',
    'productId',
    'recipeType',
    'yieldQuantity',
    'yieldUnit',
    'ingredientsJson',
  ];

  static const List<String> _customerHeaders = [
    'id',
    'fullName',
    'email',
    'phone',
    'address',
    'isAdmin',
  ];

  static const List<String> _orderHeaders = [
    'orderId',
    'userId',
    'customerName',
    'customerEmail',
    'customerPhone',
    'customerAddress',
    'paymentMethod',
    'status',
    'itemCount',
    'subtotal',
    'discountAmount',
    'deliveryFee',
    'total',
    'voucherCode',
    'itemsJson',
    'createdAt',
  ];

  static Future<void> exportProducts(List<AdminProductExcelRow> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel[_productSheetName];
    excel.delete('Sheet1');
    _writeHeader(sheet, _productHeaders);
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.id?.toString() ?? ''),
        TextCellValue(row.title),
        TextCellValue(row.category),
        IntCellValue(row.priceValue),
        TextCellValue(row.description),
        TextCellValue(row.images),
        TextCellValue(row.sku),
        TextCellValue(row.stockStatus),
        TextCellValue(row.weight),
        TextCellValue(row.storageNote),
        TextCellValue(row.deliveryNote),
        TextCellValue(row.detailBullets),
      ]);
    }
    await _downloadExcel(
      bytes: Uint8List.fromList(excel.encode() ?? const []),
      fileName: 'products_${_fileTimestamp()}.xlsx',
    );
  }

  static Future<void> exportIngredients(
    List<AdminIngredientExcelRow> rows,
  ) async {
    final excel = Excel.createExcel();
    final sheet = excel[_ingredientSheetName];
    excel.delete('Sheet1');
    _writeHeader(sheet, _ingredientHeaders);
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.id ?? ''),
        TextCellValue(row.name),
        TextCellValue(row.category),
        TextCellValue(row.unit),
        IntCellValue(row.unitPrice),
        IntCellValue(row.availableQuantity),
        IntCellValue(row.lowStockThreshold),
      ]);
    }
    await _downloadExcel(
      bytes: Uint8List.fromList(excel.encode() ?? const []),
      fileName: 'ingredients_${_fileTimestamp()}.xlsx',
    );
  }

  static Future<void> exportVouchers(List<AdminVoucherExcelRow> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel[_voucherSheetName];
    excel.delete('Sheet1');
    _writeHeader(sheet, _voucherHeaders);
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.code),
        TextCellValue(row.title),
        TextCellValue(row.note),
        TextCellValue(row.accent),
        TextCellValue(row.discountType),
        IntCellValue(row.discountValue),
        IntCellValue(row.minOrderValue),
      ]);
    }
    await _downloadExcel(
      bytes: Uint8List.fromList(excel.encode() ?? const []),
      fileName: 'vouchers_${_fileTimestamp()}.xlsx',
    );
  }

  static Future<void> exportRecipes(List<AdminRecipeExcelRow> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel[_recipeSheetName];
    excel.delete('Sheet1');
    _writeHeader(sheet, _recipeHeaders);
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.id ?? ''),
        IntCellValue(row.productId),
        TextCellValue(row.recipeType),
        IntCellValue(row.yieldQuantity),
        TextCellValue(row.yieldUnit),
        TextCellValue(row.ingredientsJson),
      ]);
    }
    await _downloadExcel(
      bytes: Uint8List.fromList(excel.encode() ?? const []),
      fileName: 'recipes_${_fileTimestamp()}.xlsx',
    );
  }

  static Future<void> exportCustomers(List<AdminCustomerExcelRow> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel[_customerSheetName];
    excel.delete('Sheet1');
    _writeHeader(sheet, _customerHeaders);
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.id ?? ''),
        TextCellValue(row.fullName),
        TextCellValue(row.email),
        TextCellValue(row.phone ?? ''),
        TextCellValue(row.address ?? ''),
        TextCellValue(row.isAdmin ? 'true' : 'false'),
      ]);
    }
    await _downloadExcel(
      bytes: Uint8List.fromList(excel.encode() ?? const []),
      fileName: 'customers_${_fileTimestamp()}.xlsx',
    );
  }

  static Future<void> exportOrders(List<AdminOrderExcelRow> rows) async {
    final excel = Excel.createExcel();
    final sheet = excel[_orderSheetName];
    excel.delete('Sheet1');
    _writeHeader(sheet, _orderHeaders);
    for (final row in rows) {
      sheet.appendRow([
        TextCellValue(row.orderId),
        TextCellValue(row.userId ?? ''),
        TextCellValue(row.customerName),
        TextCellValue(row.customerEmail),
        TextCellValue(row.customerPhone ?? ''),
        TextCellValue(row.customerAddress ?? ''),
        TextCellValue(row.paymentMethod),
        TextCellValue(row.status),
        IntCellValue(row.itemCount),
        IntCellValue(row.subtotal),
        IntCellValue(row.discountAmount),
        IntCellValue(row.deliveryFee),
        IntCellValue(row.total),
        TextCellValue(row.voucherCode ?? ''),
        TextCellValue(row.itemsJson),
        TextCellValue(row.createdAt ?? ''),
      ]);
    }
    await _downloadExcel(
      bytes: Uint8List.fromList(excel.encode() ?? const []),
      fileName: 'orders_${_fileTimestamp()}.xlsx',
    );
  }

  static Future<void> exportProductTemplate() async {
    await exportProducts(const [
      AdminProductExcelRow(
        id: 0,
        title: 'Bánh Mousse Dâu',
        category: 'Mousse',
        priceValue: 120000,
        description: 'Mẫu import sản phẩm',
        images: 'https://example.com/image-1.jpg | https://example.com/image-2.jpg',
        sku: 'MOUSSE-DAU-01',
        stockStatus: 'Còn hàng',
        weight: '450g',
        storageNote: 'Bảo quản lạnh',
        deliveryNote: 'Giao trong ngày',
        detailBullets: 'Mềm mịn | Ít ngọt',
      ),
    ]);
  }

  static Future<void> exportIngredientTemplate() async {
    await exportIngredients(const [
      AdminIngredientExcelRow(
        id: 'bot-mi-so-8',
        name: 'Bột mì số 8',
        category: 'Bột',
        unit: 'kg',
        unitPrice: 40000,
        availableQuantity: 5,
        lowStockThreshold: 2,
      ),
    ]);
  }

  static Future<void> exportVoucherTemplate() async {
    await exportVouchers(const [
      AdminVoucherExcelRow(
        code: 'WELCOME10',
        title: 'Giảm 10%',
        note: 'Áp dụng cho đơn đầu tiên',
        accent: 'red',
        discountType: 'percent',
        discountValue: 10,
        minOrderValue: 100000,
      ),
    ]);
  }

  static Future<void> exportRecipeTemplate() async {
    await exportRecipes(const [
      AdminRecipeExcelRow(
        id: 'recipe-sample',
        productId: 1,
        recipeType: 'finished',
        yieldQuantity: 10,
        yieldUnit: 'phần',
        ingredientsJson:
            '[{"ingredientId":"bot-mi-so-8","sourceType":"ingredient","quantity":1000,"wastePercent":2}]',
      ),
    ]);
  }

  static Future<void> exportCustomerTemplate() async {
    await exportCustomers(const [
      AdminCustomerExcelRow(
        id: 'user-sample',
        fullName: 'Nguyen Van A',
        email: 'sample@example.com',
        phone: '0900000000',
        address: '123 Nguyen Trai, Q1',
        isAdmin: false,
      ),
    ]);
  }

  static Future<void> exportOrderTemplate() async {
    await exportOrders(const [
      AdminOrderExcelRow(
        orderId: 'OD-SAMPLE-001',
        userId: 'user-sample',
        customerName: 'Nguyen Van A',
        customerEmail: 'sample@example.com',
        customerPhone: '0900000000',
        customerAddress: '123 Nguyen Trai, Q1',
        paymentMethod: 'cod',
        status: 'paid',
        itemCount: 1,
        subtotal: 120000,
        discountAmount: 0,
        deliveryFee: 15000,
        total: 135000,
        voucherCode: '',
        itemsJson:
            '[{"productId":1,"title":"Bánh Mousse Dâu","priceValue":120000,"quantity":1,"category":"Mousse","imageUrl":"","price":"120.000đ"}]',
        createdAt: '2026-04-05T10:00:00+07:00',
      ),
    ]);
  }

  static Future<List<AdminProductExcelRow>?> importProducts() async {
    final bytes = await _pickExcelBytes();
    if (bytes == null) {
      return null;
    }
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[_productSheetName] ?? _firstSheet(excel);
    if (sheet == null) {
      return const [];
    }
    return _readRows(sheet)
        .map(_productRowFromMap)
        .whereType<AdminProductExcelRow>()
        .toList(growable: false);
  }

  static Future<List<AdminIngredientExcelRow>?> importIngredients() async {
    final bytes = await _pickExcelBytes();
    if (bytes == null) {
      return null;
    }
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[_ingredientSheetName] ?? _firstSheet(excel);
    if (sheet == null) {
      return const [];
    }
    return _readRows(sheet)
        .map(_ingredientRowFromMap)
        .whereType<AdminIngredientExcelRow>()
        .toList(growable: false);
  }

  static Future<List<AdminVoucherExcelRow>?> importVouchers() async {
    final bytes = await _pickExcelBytes();
    if (bytes == null) return null;
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[_voucherSheetName] ?? _firstSheet(excel);
    if (sheet == null) return const [];
    return _readRows(sheet)
        .map(_voucherRowFromMap)
        .whereType<AdminVoucherExcelRow>()
        .toList(growable: false);
  }

  static Future<List<AdminRecipeExcelRow>?> importRecipes() async {
    final bytes = await _pickExcelBytes();
    if (bytes == null) return null;
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[_recipeSheetName] ?? _firstSheet(excel);
    if (sheet == null) return const [];
    return _readRows(sheet)
        .map(_recipeRowFromMap)
        .whereType<AdminRecipeExcelRow>()
        .toList(growable: false);
  }

  static Future<List<AdminCustomerExcelRow>?> importCustomers() async {
    final bytes = await _pickExcelBytes();
    if (bytes == null) return null;
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[_customerSheetName] ?? _firstSheet(excel);
    if (sheet == null) return const [];
    return _readRows(sheet)
        .map(_customerRowFromMap)
        .whereType<AdminCustomerExcelRow>()
        .toList(growable: false);
  }

  static Future<List<AdminOrderExcelRow>?> importOrders() async {
    final bytes = await _pickExcelBytes();
    if (bytes == null) return null;
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[_orderSheetName] ?? _firstSheet(excel);
    if (sheet == null) return const [];
    return _readRows(sheet)
        .map(_orderRowFromMap)
        .whereType<AdminOrderExcelRow>()
        .toList(growable: false);
  }

  static void _writeHeader(Sheet sheet, List<String> headers) {
    sheet.appendRow(headers.map(TextCellValue.new).toList(growable: false));
  }

  static Iterable<Map<String, String>> _readRows(Sheet sheet) sync* {
    if (sheet.rows.isEmpty) {
      return;
    }
    final headers = sheet.rows.first
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .toList(growable: false);
    for (final row in sheet.rows.skip(1)) {
      final map = <String, String>{};
      var hasValue = false;
      for (var i = 0; i < headers.length; i++) {
        final header = headers[i];
        if (header.isEmpty) {
          continue;
        }
        final value = i < row.length ? row[i]?.value?.toString().trim() ?? '' : '';
        if (value.isNotEmpty) {
          hasValue = true;
        }
        map[header] = value;
      }
      if (hasValue) {
        yield map;
      }
    }
  }

  static AdminProductExcelRow? _productRowFromMap(Map<String, String> row) {
    final title = row['title']?.trim() ?? '';
    if (title.isEmpty) {
      return null;
    }
    return AdminProductExcelRow(
      id: int.tryParse(row['id'] ?? ''),
      title: title,
      category: row['category']?.trim() ?? '',
      priceValue: int.tryParse(row['priceValue'] ?? '') ?? 0,
      description: row['description']?.trim() ?? '',
      images: row['images']?.trim() ?? '',
      sku: row['sku']?.trim() ?? '',
      stockStatus: row['stockStatus']?.trim() ?? '',
      weight: row['weight']?.trim() ?? '',
      storageNote: row['storageNote']?.trim() ?? '',
      deliveryNote: row['deliveryNote']?.trim() ?? '',
      detailBullets: row['detailBullets']?.trim() ?? '',
    );
  }

  static AdminIngredientExcelRow? _ingredientRowFromMap(Map<String, String> row) {
    final name = row['name']?.trim() ?? '';
    if (name.isEmpty) {
      return null;
    }
    return AdminIngredientExcelRow(
      id: row['id']?.trim().isEmpty ?? true ? null : row['id']?.trim(),
      name: name,
      category: row['category']?.trim() ?? '',
      unit: row['unit']?.trim() ?? '',
      unitPrice: int.tryParse(row['unitPrice'] ?? '') ?? 0,
      availableQuantity: int.tryParse(row['availableQuantity'] ?? '') ?? 0,
      lowStockThreshold: int.tryParse(row['lowStockThreshold'] ?? '') ?? 0,
    );
  }

  static AdminVoucherExcelRow? _voucherRowFromMap(Map<String, String> row) {
    final code = row['code']?.trim() ?? '';
    if (code.isEmpty) return null;
    return AdminVoucherExcelRow(
      code: code,
      title: row['title']?.trim() ?? '',
      note: row['note']?.trim() ?? '',
      accent: row['accent']?.trim() ?? '',
      discountType: row['discountType']?.trim() ?? '',
      discountValue: int.tryParse(row['discountValue'] ?? '') ?? 0,
      minOrderValue: int.tryParse(row['minOrderValue'] ?? '') ?? 0,
    );
  }

  static AdminRecipeExcelRow? _recipeRowFromMap(Map<String, String> row) {
    final productId = int.tryParse(row['productId'] ?? '') ?? 0;
    if (productId <= 0) return null;
    return AdminRecipeExcelRow(
      id: row['id']?.trim().isEmpty ?? true ? null : row['id']?.trim(),
      productId: productId,
      recipeType: row['recipeType']?.trim() ?? 'finished',
      yieldQuantity: int.tryParse(row['yieldQuantity'] ?? '') ?? 0,
      yieldUnit: row['yieldUnit']?.trim() ?? '',
      ingredientsJson: row['ingredientsJson']?.trim() ?? '[]',
    );
  }

  static AdminCustomerExcelRow? _customerRowFromMap(Map<String, String> row) {
    final email = row['email']?.trim() ?? '';
    if (email.isEmpty) return null;
    return AdminCustomerExcelRow(
      id: row['id']?.trim().isEmpty ?? true ? null : row['id']?.trim(),
      fullName: row['fullName']?.trim() ?? '',
      email: email,
      phone: row['phone']?.trim(),
      address: row['address']?.trim(),
      isAdmin: (row['isAdmin']?.trim().toLowerCase() ?? '') == 'true',
    );
  }

  static AdminOrderExcelRow? _orderRowFromMap(Map<String, String> row) {
    final orderId = row['orderId']?.trim() ?? '';
    if (orderId.isEmpty) return null;
    return AdminOrderExcelRow(
      orderId: orderId,
      userId: row['userId']?.trim().isEmpty ?? true ? null : row['userId']?.trim(),
      customerName: row['customerName']?.trim() ?? '',
      customerEmail: row['customerEmail']?.trim() ?? '',
      customerPhone: row['customerPhone']?.trim(),
      customerAddress: row['customerAddress']?.trim(),
      paymentMethod: row['paymentMethod']?.trim() ?? '',
      status: row['status']?.trim() ?? '',
      itemCount: int.tryParse(row['itemCount'] ?? '') ?? 0,
      subtotal: int.tryParse(row['subtotal'] ?? '') ?? 0,
      discountAmount: int.tryParse(row['discountAmount'] ?? '') ?? 0,
      deliveryFee: int.tryParse(row['deliveryFee'] ?? '') ?? 0,
      total: int.tryParse(row['total'] ?? '') ?? 0,
      voucherCode: row['voucherCode']?.trim(),
      itemsJson: row['itemsJson']?.trim() ?? '[]',
      createdAt: row['createdAt']?.trim(),
    );
  }

  static Future<Uint8List?> _pickExcelBytes() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xlsx'],
      withData: true,
    );
    final file = result == null || result.files.isEmpty ? null : result.files.first;
    return file?.bytes;
  }

  static Sheet? _firstSheet(Excel excel) {
    if (excel.tables.isEmpty) {
      return null;
    }
    return excel.tables.values.first;
  }

  static Future<void> _downloadExcel({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final blob = html.Blob(
      [bytes],
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..style.display = 'none'
      ..download = fileName;
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  static String _fileTimestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}';
  }
}
