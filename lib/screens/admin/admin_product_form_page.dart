import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/admin_models.dart';
import '../../app/repositories/admin_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/routing/app_router.dart';

class ResponsiveAdminProductFormScreen extends StatefulWidget {
  const ResponsiveAdminProductFormScreen({
    super.key,
    this.productId,
    this.showTopHeader = true,
    this.returnSidebarIndex = 2,
  });

  final int? productId;
  final bool showTopHeader;
  final int returnSidebarIndex;

  @override
  State<ResponsiveAdminProductFormScreen> createState() =>
      _ResponsiveAdminProductFormScreenState();
}

class _ResponsiveAdminProductFormScreenState
    extends State<ResponsiveAdminProductFormScreen> {
  final AdminRepository _repository = AppServices.instance.adminRepository;
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockStatusController = TextEditingController(text: 'Còn hàng');
  final _weightController = TextEditingController();
  final _storageNoteController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _imagesController = TextEditingController();
  final _detailBulletsController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;
  bool _isSuccess = false;

  bool get _isEditMode => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _stockStatusController.dispose();
    _weightController.dispose();
    _storageNoteController.dispose();
    _deliveryNoteController.dispose();
    _imagesController.dispose();
    _detailBulletsController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final detail = await _repository.fetchProductDetail(widget.productId!);
      _bindDraft(AdminProductDraft.fromDetail(detail));
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _message = 'Không thể tải thông tin sản phẩm.';
        _isSuccess = false;
      });
    }
  }

  void _bindDraft(AdminProductDraft draft) {
    _titleController.text = draft.title;
    _categoryController.text = draft.category;
    _priceController.text = draft.priceValue.toString();
    _descriptionController.text = draft.description;
    _skuController.text = draft.sku;
    _stockStatusController.text = draft.stockStatus;
    _weightController.text = draft.weight;
    _storageNoteController.text = draft.storageNote;
    _deliveryNoteController.text = draft.deliveryNote;
    _imagesController.text = draft.images.join('\n');
    _detailBulletsController.text = draft.detailBullets.join('\n');
  }

  AdminProductDraft? _buildDraft() {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();
    final sku = _skuController.text.trim();
    final stockStatus = _stockStatusController.text.trim();
    final weight = _weightController.text.trim();
    final storageNote = _storageNoteController.text.trim();
    final deliveryNote = _deliveryNoteController.text.trim();
    final priceValue = int.tryParse(_priceController.text.trim());
    final images = _imagesController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    final detailBullets = _detailBulletsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (title.isEmpty ||
        category.isEmpty ||
        description.isEmpty ||
        sku.isEmpty ||
        stockStatus.isEmpty ||
        weight.isEmpty ||
        storageNote.isEmpty ||
        deliveryNote.isEmpty ||
        priceValue == null ||
        priceValue <= 0 ||
        images.isEmpty) {
      setState(() {
        _message = 'Vui lòng nhập đầy đủ thông tin sản phẩm.';
        _isSuccess = false;
      });
      return null;
    }

    return AdminProductDraft(
      title: title,
      category: category,
      priceValue: priceValue,
      description: description,
      images: images,
      sku: sku,
      stockStatus: stockStatus,
      weight: weight,
      storageNote: storageNote,
      deliveryNote: deliveryNote,
      detailBullets: detailBullets,
    );
  }

  Future<void> _submit() async {
    final draft = _buildDraft();
    if (draft == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      if (_isEditMode) {
        await _repository.updateProduct(widget.productId!, draft);
      } else {
        await _repository.createProduct(draft);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _message = _isEditMode
            ? 'Cập nhật sản phẩm thành công.'
            : 'Thêm sản phẩm thành công.';
        _isSuccess = true;
      });
      context.goNamed(
        AppRouteNames.admin,
        queryParameters: {'sidebar': '${widget.returnSidebarIndex}'},
      );
    } catch (_) {
      setState(() {
        _isSaving = false;
        _message = 'Không thể lưu sản phẩm lúc này.';
        _isSuccess = false;
      });
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
      withData: true,
    );
    if (result == null) {
      return;
    }
    final dataUrls = <String>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        continue;
      }
      final extension = (file.extension ?? 'png').toLowerCase();
      final mime = extension == 'jpg' || extension == 'jpeg'
          ? 'image/jpeg'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/png';
      dataUrls.add('data:$mime;base64,${base64Encode(bytes)}');
    }
    if (dataUrls.isEmpty) {
      return;
    }
    final existing = _imagesController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _imagesController.text = [...existing, ...dataUrls].join('\n');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Center(
      child: Container(
        width: isMobile ? 390 : 1200,
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        color: const Color(0xFFF8F8F8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context),
              const SizedBox(height: 16),
              if (_message != null) ...[
                _messageBanner(),
                const SizedBox(height: 12),
              ],
              if (_isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else
                _formCard(isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) => Row(
        children: [
          GestureDetector(
            onTap: () => context.goNamed(
              AppRouteNames.admin,
              queryParameters: {'sidebar': '${widget.returnSidebarIndex}'},
            ),
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFCFCFCF)),
              ),
              child: const Icon(Icons.arrow_back, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
              style: const TextStyle(
                color: Color(0xFF1E88E5),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            child: Text(_isSaving ? 'Đang lưu...' : 'Lưu sản phẩm'),
          ),
        ],
      );

  Widget _formCard(bool isMobile) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCFCFCF)),
        ),
        child: Column(
          children: [
            if (isMobile) ..._mobileFields() else ..._desktopFields(),
          ],
        ),
      );

  List<Widget> _desktopFields() {
    return [
      Row(
        children: [
          Expanded(child: _field('Tên sản phẩm', _titleController)),
          const SizedBox(width: 12),
          Expanded(child: _field('Danh mục', _categoryController)),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _field('Giá', _priceController, keyboardType: TextInputType.number)),
          const SizedBox(width: 12),
          Expanded(child: _field('SKU', _skuController)),
          const SizedBox(width: 12),
          Expanded(child: _field('Trạng thái', _stockStatusController)),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(child: _field('Khối lượng', _weightController)),
          const SizedBox(width: 12),
          Expanded(child: _field('Ghi chú bảo quản', _storageNoteController)),
        ],
      ),
      const SizedBox(height: 12),
      _field('Ghi chú giao hàng', _deliveryNoteController),
      const SizedBox(height: 12),
      _field('Mô tả', _descriptionController, maxLines: 4),
      const SizedBox(height: 12),
      _imageField(),
      const SizedBox(height: 12),
      _field('Điểm nổi bật, mỗi dòng 1 ý', _detailBulletsController, maxLines: 5),
    ];
  }

  List<Widget> _mobileFields() {
    return [
      _field('Tên sản phẩm', _titleController),
      const SizedBox(height: 12),
      _field('Danh mục', _categoryController),
      const SizedBox(height: 12),
      _field('Giá', _priceController, keyboardType: TextInputType.number),
      const SizedBox(height: 12),
      _field('SKU', _skuController),
      const SizedBox(height: 12),
      _field('Trạng thái', _stockStatusController),
      const SizedBox(height: 12),
      _field('Khối lượng', _weightController),
      const SizedBox(height: 12),
      _field('Ghi chú bảo quản', _storageNoteController),
      const SizedBox(height: 12),
      _field('Ghi chú giao hàng', _deliveryNoteController),
      const SizedBox(height: 12),
      _field('Mô tả', _descriptionController, maxLines: 4),
      const SizedBox(height: 12),
      _imageField(),
      const SizedBox(height: 12),
      _field('Điểm nổi bật, mỗi dòng 1 ý', _detailBulletsController, maxLines: 5),
    ];
  }

  Widget _imageField() {
    final images = _imagesController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ảnh sản phẩm',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload ảnh'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _field('Danh sách ảnh, mỗi dòng 1 URL hoặc data URL', _imagesController, maxLines: 5),
        if (images.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: images.take(4).map((image) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCFCFCF)),
                  image: DecorationImage(
                    image: NetworkImage(image),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ],
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _messageBanner() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isSuccess ? const Color(0xFFEFF8F1) : const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          ),
        ),
        child: Text(
          _message!,
          style: TextStyle(
            color: _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
