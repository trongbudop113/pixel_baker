import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/admin_models.dart';
import '../../app/repositories/admin_repository.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';

class ResponsiveAdminRecipeFormScreen extends StatefulWidget {
  const ResponsiveAdminRecipeFormScreen({
    super.key,
    this.recipeId,
    this.showTopHeader = true,
    this.returnSidebarIndex = 5,
  });

  final String? recipeId;
  final bool showTopHeader;
  final int returnSidebarIndex;

  @override
  State<ResponsiveAdminRecipeFormScreen> createState() =>
      _ResponsiveAdminRecipeFormScreenState();
}

class _ResponsiveAdminRecipeFormScreenState
    extends State<ResponsiveAdminRecipeFormScreen> {
  static const List<String> _yieldUnits = ['phần', 'ổ', 'ly', 'bánh', 'hộp'];
  static const List<String> _recipeTypes = ['finished', 'semi_finished'];

  final AdminRepository _repository = AppServices.instance.adminRepository;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _message;
  AdminRecipeOptionsModel? _options;
  int? _selectedProductId;
  String _selectedRecipeType = _recipeTypes.first;
  String _selectedYieldUnit = _yieldUnits.first;
  final TextEditingController _yieldQuantityController =
      TextEditingController(text: '10');
  final List<_RecipeIngredientRowState> _ingredientRows = [];

  bool get _isEditMode => widget.recipeId != null && widget.recipeId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _yieldQuantityController.dispose();
    for (final row in _ingredientRows) {
      row.quantityController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await _repository.fetchRecipeOptions(recipeId: widget.recipeId);
      AdminRecipeModel? recipe;
      if (_isEditMode) {
        recipe = await _repository.fetchRecipe(widget.recipeId!);
      }
      setState(() {
        _options = options;
        _selectedProductId = recipe?.productId ??
            (options.products.isNotEmpty ? options.products.first.id : null);
        if (recipe != null) {
          _selectedRecipeType = recipe.recipeType;
          _selectedYieldUnit = recipe.yieldUnit;
          _yieldQuantityController.text = recipe.yieldQuantity.toString();
          for (final row in _ingredientRows) {
            row.quantityController.dispose();
            row.wasteController.dispose();
          }
          _ingredientRows
            ..clear()
            ..addAll(
              recipe.ingredients.map(
                (ingredient) => _RecipeIngredientRowState(
                  sourceType: ingredient.sourceType,
                  ingredientId: ingredient.ingredientId,
                  quantityController: TextEditingController(
                    text: ingredient.quantity.toString(),
                  ),
                  wasteController: TextEditingController(
                    text: ingredient.wastePercent.toString(),
                  ),
                ),
              ),
            );
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _isLoading = false;
        _message = 'Không thể tải dữ liệu tạo công thức.';
      });
    }
  }

  Future<void> _submit() async {
    final productId = _selectedProductId;
    final yieldQuantity = int.tryParse(_yieldQuantityController.text.trim()) ?? 0;
    if (productId == null) {
      setState(() {
        _message = 'Không còn sản phẩm nào để tạo công thức.';
      });
      return;
    }
    if (yieldQuantity <= 0) {
      setState(() {
        _message = 'Số phần tạo ra của một mẻ phải lớn hơn 0.';
      });
      return;
    }

    final ingredients = <AdminRecipeIngredientDraft>[];
    final usedIngredientIds = <String>{};
    for (final row in _ingredientRows) {
      final ingredientId = row.ingredientId;
      final quantity = int.tryParse(row.quantityController.text.trim()) ?? 0;
      final wastePercent = int.tryParse(row.wasteController.text.trim()) ?? 0;
      if (ingredientId != null && quantity > 0) {
        final key = '${row.sourceType}:$ingredientId';
        if (usedIngredientIds.contains(key)) {
          setState(() {
            _message = 'Mỗi nguồn chỉ nên xuất hiện một lần trong công thức.';
          });
          return;
        }
        usedIngredientIds.add(key);
        ingredients.add(
          AdminRecipeIngredientDraft(
            ingredientId: ingredientId,
            sourceType: row.sourceType,
            quantity: quantity,
            wastePercent: wastePercent < 0 ? 0 : wastePercent,
          ),
        );
      }
    }

    if (ingredients.isEmpty) {
      setState(() {
        _message = 'Vui lòng chọn ít nhất một nguyên liệu với số lượng hợp lệ.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _message = null;
    });
    try {
      final draft = AdminRecipeDraft(
        productId: productId,
        recipeType: _selectedRecipeType,
        yieldQuantity: yieldQuantity,
        yieldUnit: _selectedYieldUnit,
        ingredients: ingredients,
      );
      if (_isEditMode) {
        await _repository.updateRecipe(widget.recipeId!, draft);
      } else {
        await _repository.createRecipe(draft);
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
        _message = _isEditMode
            ? 'Không thể cập nhật công thức.'
            : 'Không thể tạo công thức.';
      });
    }
  }

  void _addIngredientRow() {
    setState(() {
      _ingredientRows.add(
        _RecipeIngredientRowState(
          sourceType: 'ingredient',
          ingredientId: null,
          quantityController: TextEditingController(),
          wasteController: TextEditingController(text: '0'),
        ),
      );
    });
  }

  void _removeIngredientRow(int index) {
    final row = _ingredientRows.removeAt(index);
    row.quantityController.dispose();
    row.wasteController.dispose();
    setState(() {});
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
              _isEditMode ? 'Sửa công thức' : 'Tạo công thức',
              style: TextStyle(
                color: Color(0xFF1E88E5),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isSaving ? null : _submit,
            child: Text(
              _isSaving
                  ? 'Đang lưu...'
                  : (_isEditMode ? 'Cập nhật công thức' : 'Lưu công thức'),
            ),
          ),
        ],
      );

  Widget _formCard() {
    final options = _options;
    if (options == null) {
      return _banner('Không thể tải dữ liệu.');
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCFCFCF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tên công thức',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            value: _selectedProductId,
            items: options.products.map((product) {
              return DropdownMenuItem<int>(
                value: product.id,
                child: Text('${product.title} • ${product.category}'),
              );
            }).toList(growable: false),
            onChanged: (value) => setState(() => _selectedProductId = value),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Loại công thức',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _selectedRecipeType,
            items: const [
              DropdownMenuItem(
                value: 'finished',
                child: Text('Thành phẩm'),
              ),
              DropdownMenuItem(
                value: 'semi_finished',
                child: Text('Bán thành phẩm'),
              ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedRecipeType = value);
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Thành phẩm theo mẻ',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _yieldQuantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: 10',
                    labelText: 'Số lượng tạo ra',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedYieldUnit,
                  items: _yieldUnits.map((unit) {
                    return DropdownMenuItem<String>(
                      value: unit,
                      child: Text(unit),
                    );
                  }).toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selectedYieldUnit = value);
                  },
                  decoration: InputDecoration(
                    labelText: 'Đơn vị',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ví dụ: 1 mẻ tạo ra 10 $_selectedYieldUnit. Định lượng nguyên liệu bên dưới được hiểu cho toàn bộ mẻ này.',
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nguyên liệu cho cả mẻ',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _addIngredientRow,
              icon: const Icon(Icons.add),
              label: const Text('Thêm nguyên liệu'),
            ),
          ),
          const SizedBox(height: 8),
          if (_ingredientRows.isEmpty)
            const Text(
              'Nhấn + để thêm nguyên liệu và nhập định lượng dùng cho cả mẻ.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ...List.generate(_ingredientRows.length, (index) {
            final row = _ingredientRows[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: row.ingredientId,
                      items: _buildSourceItems(options, row.sourceType),
                      onChanged: (value) {
                        setState(() {
                          row.ingredientId = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Chọn nguyên liệu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 130,
                    child: DropdownButtonFormField<String>(
                      value: row.sourceType,
                      items: const [
                        DropdownMenuItem(
                          value: 'ingredient',
                          child: Text('Nguyên liệu'),
                        ),
                        DropdownMenuItem(
                          value: 'recipe',
                          child: Text('Bán thành phẩm'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          row.sourceType = value;
                          row.ingredientId = null;
                        });
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: row.quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Định lượng / mẻ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 86,
                    child: TextField(
                      controller: row.wasteController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '% hao hụt',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 52,
                    child: Text(
                      _sourceUnitLabel(options, row) ?? '--',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeIngredientRow(index),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
      );
  }

  AdminIngredientModel? _findIngredient(
    AdminRecipeOptionsModel options,
    String ingredientId,
  ) {
    for (final ingredient in options.ingredients) {
      if (ingredient.id == ingredientId) {
        return ingredient;
      }
    }
    return null;
  }

  List<DropdownMenuItem<String>> _buildSourceItems(
    AdminRecipeOptionsModel options,
    String sourceType,
  ) {
    if (sourceType == 'recipe') {
      return options.recipeReferences.map((recipe) {
        return DropdownMenuItem<String>(
          value: recipe.id,
          child: Text('${recipe.productTitle} • ${recipe.yieldQuantity} ${recipe.yieldUnit}'),
        );
      }).toList(growable: false);
    }
    return options.ingredients.map((ingredient) {
      return DropdownMenuItem<String>(
        value: ingredient.id,
        child: Text('${ingredient.name} • ${ingredient.category}'),
      );
    }).toList(growable: false);
  }

  String? _sourceUnitLabel(
    AdminRecipeOptionsModel options,
    _RecipeIngredientRowState row,
  ) {
    if (row.ingredientId == null) {
      return null;
    }
    if (row.sourceType == 'recipe') {
      for (final item in options.recipeReferences) {
        if (item.id == row.ingredientId) {
          return item.yieldUnit;
        }
      }
      return null;
    }
    return _findIngredient(options, row.ingredientId!)?.unit;
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

class _RecipeIngredientRowState {
  _RecipeIngredientRowState({
    required this.sourceType,
    this.ingredientId,
    required this.quantityController,
    required this.wasteController,
  });

  String sourceType;
  final TextEditingController quantityController;
  final TextEditingController wasteController;
  String? ingredientId;
}
