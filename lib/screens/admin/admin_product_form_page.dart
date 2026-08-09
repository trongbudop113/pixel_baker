import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/admin_models.dart';
import '../../app/models/menu_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/admin_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/routing/app_router.dart';
import 'image_editor_dialog.dart';

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
  static const String _optionGroupsJsonHint =
      '[{"id":"sauce","label":"Chọn sốt","options":[{"id":"both","label":"2 loại sốt","priceDelta":0,"isDefault":true},{"id":"cheese","label":"Sốt phô mai","priceDelta":-5000},{"id":"egg","label":"Sốt dầu trứng","priceDelta":-3000}]}]';

  final AdminRepository _repository = AppServices.instance.adminRepository;
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _stockStatusController = TextEditingController(text: 'Còn hàng');
  final _weightController = TextEditingController();
  final _storageNoteController = TextEditingController();
  final _deliveryNoteController = TextEditingController();
  final _imagesController = TextEditingController();
  final _detailBulletsController = TextEditingController();
  final _ingredientsTextController = TextEditingController();
  final _optionGroupsController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isUploadingImages = false;
  int _uploadingImageIndex = 0;
  int _uploadingImageTotal = 0;
  String? _message;
  bool _isSuccess = false;
  List<AdminCategoryModel> _categories = const [];
  String? _selectedCategory;

  bool get _isEditMode => widget.productId != null;

  AdminCategoryModel? get _selectedCategoryModel {
    final selected = (_selectedCategory ?? '').trim();
    if (selected.isEmpty) {
      return null;
    }
    for (final category in _categories) {
      if (category.category.trim() == selected) {
        return category;
      }
    }
    return null;
  }

  bool get _isSelectedSemiFinishedCategory =>
      _selectedCategoryModel?.isSemiFinished ?? false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (_isEditMode) {
      _loadProduct();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _stockStatusController.dispose();
    _weightController.dispose();
    _storageNoteController.dispose();
    _deliveryNoteController.dispose();
    _imagesController.dispose();
    _detailBulletsController.dispose();
    _ingredientsTextController.dispose();
    _optionGroupsController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _repository.fetchCategories();
      if (!mounted) {
        return;
      }
      setState(() {
        _categories = categories
            .where((item) =>
                item.category.trim().isNotEmpty &&
                item.category.trim().toLowerCase() != 'all')
            .toList(growable: false);
        if (_selectedCategory == null && _categories.isNotEmpty) {
          _selectedCategory = _categories.first.category;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _message = 'Không thể tải danh mục sản phẩm.';
        _isSuccess = false;
      });
    }
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
    _selectedCategory = draft.category;
    _priceController.text = draft.priceValue.toString();
    _descriptionController.text = draft.description;
    _skuController.text = draft.sku;
    _stockStatusController.text = draft.stockStatus;
    _weightController.text = draft.weight;
    _storageNoteController.text = draft.storageNote;
    _deliveryNoteController.text = draft.deliveryNote;
    _imagesController.text = draft.images.join('\n');
    _detailBulletsController.text = draft.detailBullets.join('\n');
    _ingredientsTextController.text = draft.ingredientsText;
    _optionGroupsController.text = draft.optionGroups.isEmpty
        ? ''
        : const JsonEncoder.withIndent('  ').convert(
            draft.optionGroups.map((item) => item.toJson()).toList(),
          );
  }

  AdminProductDraft? _buildDraft() {
    final title = _titleController.text.trim();
    final category = (_selectedCategory ?? '').trim();
    final description = _isSelectedSemiFinishedCategory
        ? ''
        : _descriptionController.text.trim();
    final sku = _skuController.text.trim();
    final stockStatus = _isSelectedSemiFinishedCategory
        ? 'Tạm ẩn'
        : _stockStatusController.text.trim();
    final weight = _weightController.text.trim();
    final storageNote = _isSelectedSemiFinishedCategory
        ? ''
        : _storageNoteController.text.trim();
    final deliveryNote = _isSelectedSemiFinishedCategory
        ? ''
        : _deliveryNoteController.text.trim();
    final ingredientsText = _isSelectedSemiFinishedCategory
        ? ''
        : _ingredientsTextController.text.trim();
    final priceValue = _isSelectedSemiFinishedCategory
        ? 0
        : int.tryParse(_priceController.text.trim());
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
    final optionGroups = _isSelectedSemiFinishedCategory
        ? const <ProductOptionGroup>[]
        : _parseOptionGroupsJson();
    if (optionGroups == null) {
      return null;
    }

    final missingFields = <String>[
      if (title.isEmpty) 'Tên sản phẩm',
      if (category.isEmpty) 'Danh mục',
      if (!_isSelectedSemiFinishedCategory && description.isEmpty) 'Mô tả',
      if (sku.isEmpty) 'SKU',
      if (stockStatus.isEmpty) 'Trạng thái',
      if (weight.isEmpty) 'Khối lượng',
      if (!_isSelectedSemiFinishedCategory && storageNote.isEmpty)
        'Ghi chú bảo quản',
      if (!_isSelectedSemiFinishedCategory && deliveryNote.isEmpty)
        'Ghi chú giao hàng',
      if (!_isSelectedSemiFinishedCategory &&
          (priceValue == null || priceValue <= 0))
        'Giá',
      if (images.isEmpty) 'Ảnh',
    ];
    if (missingFields.isNotEmpty) {
      setState(() {
        _message = 'Vui lòng nhập: ${missingFields.join(', ')}.';
        _isSuccess = false;
      });
      return null;
    }

    return AdminProductDraft(
      title: title,
      category: category,
      priceValue: priceValue ?? 0,
      description: description,
      images: images,
      sku: sku,
      stockStatus: stockStatus,
      weight: weight,
      storageNote: storageNote,
      deliveryNote: deliveryNote,
      detailBullets: detailBullets,
      ingredientsText: ingredientsText,
      optionGroups: optionGroups,
    );
  }

  List<ProductOptionGroup>? _parseOptionGroupsJson() {
    final raw = _optionGroupsController.text.trim();
    if (raw.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('root must be list');
      }
      return decoded
          .map(
            (item) => ProductOptionGroup.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .where((group) => group.label.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      setState(() {
        _message =
            'Tùy chọn sản phẩm phải là JSON array hợp lệ. Ví dụ: [{"id":"sauce","label":"Chọn sốt","options":[{"id":"both","label":"2 loại sốt","priceDelta":0,"isDefault":true}]}]';
        _isSuccess = false;
      });
      return null;
    }
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
    } on ApiException catch (error) {
      setState(() {
        _isSaving = false;
        _message = error.message;
        _isSuccess = false;
      });
    } catch (_) {
      setState(() {
        _isSaving = false;
        _message = 'Không thể lưu sản phẩm lúc này.';
        _isSuccess = false;
      });
    }
  }

  Future<void> _pickImages() async {
    if (_isUploadingImages) return;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif'],
      withData: true,
    );
    if (result == null) return;

    final repository = AppServices.instance.adminRepository;
    final uploadedUrls = <String>[];
    final failedFiles = <String>[];

    setState(() {
      _isUploadingImages = true;
      _uploadingImageIndex = 0;
      _uploadingImageTotal = result.files.length;
    });

    try {
      for (var i = 0; i < result.files.length; i++) {
        final file = result.files[i];
        if (mounted) {
          setState(() => _uploadingImageIndex = i + 1);
        }
        final bytes = file.bytes;
        if (bytes == null) continue;

        final isHeic = _isHeicImage(file.name, file.extension);

        Uint8List finalBytes = bytes;
        var mime = _imageMimeType(file.name, file.extension);
        var fname = file.name;

        // HEIC/HEIF is converted by the backend because Flutter web cannot decode it.
        if (!isHeic && mounted) {
          final edited = await showDialog<Uint8List>(
            context: context,
            barrierDismissible: false,
            builder: (_) =>
                ImageEditorDialog(bytes: bytes, filename: file.name),
          );
          if (edited == null) continue; // User cancelled
          finalBytes = edited;
          mime = 'image/jpeg'; // editor always outputs JPEG
          fname = file.name.replaceAll(RegExp(r'\.[^.]+$'), '.jpg');
        }

        try {
          final url = await repository.uploadImage(finalBytes, fname, mime);
          uploadedUrls.add(url);
        } on ApiException catch (error) {
          failedFiles.add('${file.name} (${error.message})');
        } catch (_) {
          failedFiles.add(file.name);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImages = false;
          _uploadingImageIndex = 0;
          _uploadingImageTotal = 0;
        });
      }
    }

    if (uploadedUrls.isNotEmpty) {
      _appendImageUrls(uploadedUrls);
    }

    if (failedFiles.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload thất bại: ${failedFiles.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() {});
  }

  bool _isHeicImage(String filename, String? extension) {
    final ext = (extension ?? filename.split('.').last).trim().toLowerCase();
    return ext == 'heic' || ext == 'heif';
  }

  void _appendImageUrls(List<String> urls) {
    final cleanUrls = urls
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (cleanUrls.isEmpty) return;
    final existing = _imagesController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    _imagesController.text = [...existing, ...cleanUrls].join('\n');
    setState(() {});
  }

  Future<void> _selectDriveImages() async {
    final selected = await showDialog<List<String>>(
      context: context,
      builder: (_) => const _DriveImagePickerDialog(),
    );
    if (selected == null || selected.isEmpty) return;
    _appendImageUrls(selected);
  }

  String _imageMimeType(String filename, String? extension) {
    final ext = (extension ?? filename.split('.').last).trim().toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'heic' => 'image/heic',
      'heif' => 'image/heif',
      _ => 'image/jpeg',
    };
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return Align(
      alignment: Alignment.topCenter,
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
                const Center(
                    child: Padding(
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
    final showWebSaleFields = !_isSelectedSemiFinishedCategory;
    return [
      Row(
        children: [
          Expanded(child: _field('Tên sản phẩm', _titleController)),
          const SizedBox(width: 12),
          Expanded(child: _categoryDropdown()),
        ],
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          if (showWebSaleFields) ...[
            Expanded(
                child: _field('Giá', _priceController,
                    keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
          ],
          Expanded(child: _field('SKU', _skuController)),
          if (showWebSaleFields) ...[
            const SizedBox(width: 12),
            Expanded(child: _field('Trạng thái', _stockStatusController)),
          ],
        ],
      ),
      const SizedBox(height: 12),
      if (showWebSaleFields) ...[
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
        _field('Thành phần', _ingredientsTextController, maxLines: 3),
        const SizedBox(height: 12),
      ] else ...[
        _field('Khối lượng', _weightController),
        const SizedBox(height: 12),
      ],
      _imageField(),
      const SizedBox(height: 12),
      _field('Điểm nổi bật, mỗi dòng 1 ý', _detailBulletsController,
          maxLines: 5),
      if (showWebSaleFields) ...[
        const SizedBox(height: 12),
        _field(
          'Tùy chọn sản phẩm (JSON)',
          _optionGroupsController,
          maxLines: 8,
          hintText: _optionGroupsJsonHint,
        ),
      ],
    ];
  }

  List<Widget> _mobileFields() {
    final showWebSaleFields = !_isSelectedSemiFinishedCategory;
    return [
      _field('Tên sản phẩm', _titleController),
      const SizedBox(height: 12),
      _categoryDropdown(),
      if (showWebSaleFields) ...[
        const SizedBox(height: 12),
        _field('Giá', _priceController, keyboardType: TextInputType.number),
      ],
      const SizedBox(height: 12),
      _field('SKU', _skuController),
      if (showWebSaleFields) ...[
        const SizedBox(height: 12),
        _field('Trạng thái', _stockStatusController),
      ],
      const SizedBox(height: 12),
      _field('Khối lượng', _weightController),
      if (showWebSaleFields) ...[
        const SizedBox(height: 12),
        _field('Ghi chú bảo quản', _storageNoteController),
        const SizedBox(height: 12),
        _field('Ghi chú giao hàng', _deliveryNoteController),
        const SizedBox(height: 12),
        _field('Mô tả', _descriptionController, maxLines: 4),
        const SizedBox(height: 12),
        _field('Thành phần', _ingredientsTextController, maxLines: 3),
      ],
      const SizedBox(height: 12),
      _imageField(),
      const SizedBox(height: 12),
      _field('Điểm nổi bật, mỗi dòng 1 ý', _detailBulletsController,
          maxLines: 5),
      if (showWebSaleFields) ...[
        const SizedBox(height: 12),
        _field(
          'Tùy chọn sản phẩm (JSON)',
          _optionGroupsController,
          maxLines: 8,
          hintText: _optionGroupsJsonHint,
        ),
      ],
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
              onPressed: _isUploadingImages ? null : _selectDriveImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Chọn từ Drive'),
            ),
            const SizedBox(width: 6),
            TextButton.icon(
              onPressed: _isUploadingImages ? null : _pickImages,
              icon: _isUploadingImages
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                _isUploadingImages
                    ? 'Đang upload $_uploadingImageIndex/$_uploadingImageTotal'
                    : 'Upload ảnh',
              ),
            ),
          ],
        ),
        if (_isUploadingImages) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _uploadingImageTotal == 0
                ? null
                : _uploadingImageIndex / _uploadingImageTotal,
          ),
        ],
        const SizedBox(height: 6),
        _field('Danh sách ảnh, mỗi dòng 1 URL hoặc data URL', _imagesController,
            maxLines: 5),
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

  Widget _categoryDropdown() {
    final values = <String>{
      for (final item in _categories) item.category,
      if ((_selectedCategory ?? '').trim().isNotEmpty)
        _selectedCategory!.trim(),
    }.toList(growable: false);
    final selected =
        values.contains(_selectedCategory) ? _selectedCategory : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Danh mục',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey(selected ?? 'category-empty'),
          initialValue: selected,
          items: values
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(_categoryLabel(value)),
                ),
              )
              .toList(growable: false),
          onChanged: values.isEmpty
              ? null
              : (value) {
                  setState(() {
                    _selectedCategory = value;
                    if (_isSelectedSemiFinishedCategory) {
                      _stockStatusController.text = 'Tạm ẩn';
                    }
                  });
                },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        if (_isSelectedSemiFinishedCategory) ...[
          const SizedBox(height: 6),
          const Text(
            'Danh mục bán thành phẩm sẽ tự đặt sản phẩm ở trạng thái Tạm ẩn.',
            style: TextStyle(
              color: Color(0xFFD97706),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  String _categoryLabel(String value) {
    for (final item in _categories) {
      if (item.category == value) {
        final badges = [
          if (item.isSemiFinished) 'bán TP',
          if (!item.isVisibleOnWeb) 'ẩn web',
        ];
        if (badges.isEmpty) {
          return item.label;
        }
        return '${item.label} (${badges.join(', ')})';
      }
    }
    return value;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? hintText,
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
            hintText: hintText,
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
            color:
                _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
          ),
        ),
        child: Text(
          _message!,
          style: TextStyle(
            color:
                _isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFE53935),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _DriveImagePickerDialog extends StatefulWidget {
  const _DriveImagePickerDialog();

  @override
  State<_DriveImagePickerDialog> createState() =>
      _DriveImagePickerDialogState();
}

class _DriveImagePickerDialogState extends State<_DriveImagePickerDialog> {
  bool _isLoading = true;
  String? _errorMessage;
  List<AdminDriveImageModel> _images = const [];
  final Set<String> _selectedUrls = <String>{};

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final images =
          await AppServices.instance.adminRepository.fetchDriveImages();
      if (!mounted) return;
      setState(() {
        _images = images;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Không thể tải danh sách ảnh Google Drive.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Chọn ảnh từ Google Drive',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isLoading ? null : _loadImages,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Tải lại',
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(child: _body()),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Đã chọn ${_selectedUrls.length} ảnh',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Hủy'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _selectedUrls.isEmpty
                        ? null
                        : () => Navigator.of(context)
                            .pop(_selectedUrls.toList(growable: false)),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Thêm ảnh'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFE53935),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    if (_images.isEmpty) {
      return const Center(
        child: Text(
          'Chưa có ảnh nào trong folder Google Drive.',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return GridView.builder(
      itemCount: _images.length,
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.88,
      ),
      itemBuilder: (context, index) {
        final image = _images[index];
        final isSelected = _selectedUrls.contains(image.url);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedUrls.remove(image.url);
              } else {
                _selectedUrls.add(image.url);
              }
            });
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF1E88E5)
                    : const Color(0xFFE5E7EB),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(7)),
                    child: Image.network(
                      image.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFF3F4F6),
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(7),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isSelected
                            ? const Color(0xFF1E88E5)
                            : const Color(0xFF9CA3AF),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          image.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
