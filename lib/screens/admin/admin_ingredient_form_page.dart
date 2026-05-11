import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/admin_models.dart';
import '../../app/repositories/admin_repository.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';

class ResponsiveAdminIngredientFormScreen extends StatefulWidget {
  const ResponsiveAdminIngredientFormScreen({
    super.key,
    this.ingredientId,
    this.showTopHeader = true,
    this.returnSidebarIndex = 4,
  });

  final String? ingredientId;
  final bool showTopHeader;
  final int returnSidebarIndex;

  @override
  State<ResponsiveAdminIngredientFormScreen> createState() =>
      _ResponsiveAdminIngredientFormScreenState();
}

class _ResponsiveAdminIngredientFormScreenState
    extends State<ResponsiveAdminIngredientFormScreen> {
  final AdminRepository _repository = AppServices.instance.adminRepository;
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _availableQuantityController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();

  String _unit = 'g';
  bool _isLoading = false;
  bool _isSaving = false;
  String? _message;

  bool get _isEditMode => widget.ingredientId != null && widget.ingredientId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadIngredient();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _unitPriceController.dispose();
    _availableQuantityController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredient() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      final ingredient = await _repository.fetchIngredient(widget.ingredientId!);
      final draft = AdminIngredientDraft.fromIngredient(ingredient);
      _nameController.text = draft.name;
      _categoryController.text = draft.category;
      _unitPriceController.text = draft.unitPrice.toString();
      _availableQuantityController.text = draft.availableQuantity.toString();
      _lowStockThresholdController.text = draft.lowStockThreshold.toString();
      _unit = draft.unit;
      setState(() {
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _message = 'Không thể tải nguyên liệu.';
      });
    }
  }

  AdminIngredientDraft? _buildDraft() {
    final name = _nameController.text.trim();
    final category = _categoryController.text.trim();
    final unitPrice = int.tryParse(_unitPriceController.text.trim());
    final availableQuantity = int.tryParse(_availableQuantityController.text.trim());
    final lowStockThreshold = int.tryParse(_lowStockThresholdController.text.trim());

    if (name.isEmpty ||
        category.isEmpty ||
        unitPrice == null ||
        availableQuantity == null ||
        lowStockThreshold == null) {
      setState(() {
        _message = 'Vui lòng nhập đầy đủ thông tin nguyên liệu.';
      });
      return null;
    }

    return AdminIngredientDraft(
      name: name,
      category: category,
      unit: _unit,
      unitPrice: unitPrice,
      availableQuantity: availableQuantity,
      lowStockThreshold: lowStockThreshold,
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
        await _repository.updateIngredientInfo(widget.ingredientId!, draft);
      } else {
        await _repository.createIngredient(draft);
      }
      if (!mounted) {
        return;
      }
      context.goNamed(
        AppRouteNames.admin,
        queryParameters: {'sidebar': '${widget.returnSidebarIndex}'},
      );
    } catch (_) {
      setState(() {
        _isSaving = false;
        _message = 'Không thể lưu nguyên liệu.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF8F8F8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(context),
            const SizedBox(height: 16),
            if (_message != null) ...[
              _banner(_message!),
              const SizedBox(height: 12),
            ],
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              _formCard(),
          ],
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
              _isEditMode ? 'Sửa nguyên liệu' : 'Thêm nguyên liệu',
              style: const TextStyle(
                color: Color(0xFF1E88E5),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            child: Text(_isSaving ? 'Đang lưu...' : 'Lưu'),
          ),
        ],
      );

  Widget _formCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCFCFCF)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _field('Tên nguyên liệu', _nameController)),
                const SizedBox(width: 12),
                Expanded(child: _field('Danh mục', _categoryController)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field('Đơn giá', _unitPriceController, number: true)),
                const SizedBox(width: 12),
                Expanded(child: _field('Số lượng tồn', _availableQuantityController, number: true)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _unit,
                    items: const [
                      DropdownMenuItem(value: 'g', child: Text('g')),
                      DropdownMenuItem(value: 'ml', child: Text('ml')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _unit = value;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Đơn vị',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: _field('Ngưỡng cảnh báo', _lowStockThresholdController, number: true)),
              ],
            ),
          ],
        ),
      );

  Widget _field(String label, TextEditingController controller, {bool number = false}) {
    return TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _banner(String message) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEAEA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE53935)),
        ),
        child: Text(
          message,
          style: const TextStyle(
            color: Color(0xFFE53935),
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}
