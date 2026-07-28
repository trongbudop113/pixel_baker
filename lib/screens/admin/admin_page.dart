import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import '../../app/excel/admin_excel_core.dart';
import '../../app/models/admin_models.dart';
import '../../app/models/auth_page_models.dart';
import '../../app/models/contact_models.dart';
import '../../app/models/home_models.dart';
import '../../app/models/story_models.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';
import '../shared/app_header.dart';
import 'admin_state.dart';

class AdminColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF00A86B);
  static const gray = Color(0xFF8A8A8A);
  static const line = Color(0xFFDCE1EA);
  static const textDark = Color(0xFF111827);
  static const orange = Color(0xFFD97706);
  static const borderSoft = Color(0xFFCFCFCF);
  static const textSoft = Color(0xFF6B7280);
}

class ResponsiveAdminScreen extends StatefulWidget {
  const ResponsiveAdminScreen({
    super.key,
    this.showTopHeader = true,
    this.initialSidebarIndex = 0,
  });
  final bool showTopHeader;
  final int initialSidebarIndex;

  @override
  State<ResponsiveAdminScreen> createState() => _ResponsiveAdminScreenState();
}

class _ResponsiveAdminScreenState extends State<ResponsiveAdminScreen> {
  final AdminState _adminState = AdminState();

  @override
  void initState() {
    super.initState();
    _adminState.selectSidebar(widget.initialSidebarIndex);
    _adminState.load();
  }

  @override
  void dispose() {
    _adminState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return isMobile
            ? _AdminMobileLayout(
                state: _adminState, showTopHeader: widget.showTopHeader)
            : _AdminWebLayout(
                state: _adminState, showTopHeader: widget.showTopHeader);
      },
    );
  }
}

class _AdminWebLayout extends StatelessWidget {
  final AdminState state;
  final bool showTopHeader;
  const _AdminWebLayout({required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1280,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F8F8),
          border: Border.all(color: AdminColors.gray, width: 2),
        ),
        child: Column(
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                  rightLabel: 'admin', showBack: true, showBrand: false),
            if (showTopHeader) const SizedBox(height: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sideBar(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _mainWeb(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideBar() {
    final items = state.sidebarItems;
    return Container(
      width: 248,
      padding: const EdgeInsets.all(14),
      decoration: _box(borderWidth: 2),
      child: Column(
        children: [
          _sideItem('PIXEL ADMIN', active: false, h: 56, bold: true),
          const SizedBox(height: 10),
          ...List.generate(items.length * 2 - 1, (i) {
            if (i.isOdd) return const SizedBox(height: 10);
            final item = items[i ~/ 2];
            return GestureDetector(
              onTap: () => state.selectSidebar(item.index),
              child: AnimatedBuilder(
                animation: state,
                builder: (context, _) => _sideItem(
                  item.label,
                  active: state.selectedSidebarIndex == item.index,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _sideItem(String text,
      {bool active = false, double h = 42, bool bold = false}) {
    return Container(
      height: h,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: active ? AdminColors.red : Colors.white,
        borderRadius: BorderRadius.circular(active ? 8 : 8),
        border: active ? null : Border.all(color: AdminColors.gray, width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active
              ? Colors.white
              : (bold ? AdminColors.red : AdminColors.blue),
          fontSize: bold ? 16 : 13,
          fontWeight: bold ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }

  Widget _mainWeb() {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final content = switch (state.selectedSidebarIndex) {
          1 => _OrdersManagementSection(state: state),
          2 => _ProductsManagementSection(state: state),
          3 => _CustomersManagementSection(state: state),
          4 => _IngredientsManagementSection(state: state),
          5 => _RecipesManagementSection(state: state),
          6 => _VouchersManagementSection(state: state),
          7 => _TestimonialsManagementSection(state: state),
          8 => _ContentsManagementSection(state: state),
          9 => _ProfitSummarySection(state: state),
          10 => _ReviewsManagementSection(state: state),
          11 => _SmartAnalyticsSection(state: state),
          12 => _CategoriesManagementSection(state: state),
          _ => _OverviewSection(state: state),
        };
        // Show loading skeleton on first load
        if (state.isLoading) {
          return Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFF8F8F8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AdminLoadingSkeleton(),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFF8F8F8),
          child: DefaultTextStyle.merge(
            style: const TextStyle(
              color: AdminColors.textDark,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            child: IconTheme.merge(
              data: const IconThemeData(color: AdminColors.textDark),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InlineMessage(
                        message: state.errorMessage!,
                        tone: 'danger',
                      ),
                    ),
                  content,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final dashboard = state.dashboard;
    final statCards = dashboard.statCards;
    final tabSummaries = dashboard.tabSummaries;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: _box(borderWidth: 2, radius: 12),
          child: Row(
            children: [
              Text(dashboard.title,
                  style: const TextStyle(
                      color: AdminColors.blue,
                      fontSize: 20,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              const _TopInput('Tìm đơn hàng, khách hàng...', width: 280),
              const SizedBox(width: 10),
              _TopInput(
                dashboard.notificationLabel,
                width: 126,
                color: AdminColors.blue,
                weight: FontWeight.w800,
                centered: true,
                size: 13,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: List.generate(statCards.length * 2 - 1, (index) {
            if (index.isOdd) {
              return const SizedBox(width: 10);
            }
            final item = statCards[index ~/ 2];
            return Expanded(
              child: _StatCard(item.label, item.value, _toneColor(item.tone)),
            );
          }),
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 60,
              child: _OrdersPanel(orders: dashboard.recentOrders),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 40,
              child: _RightPanel(
                alerts: dashboard.alerts,
                salesByHour: dashboard.salesByHour,
                topTrendLabel: dashboard.topTrendLabel,
                topTrendValue: dashboard.topTrendValue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (tabSummaries.length >= 3)
          Row(
            children: [
              Expanded(child: _TabCard.fromModel(tabSummaries[0])),
              const SizedBox(width: 10),
              Expanded(child: _TabCard.fromModel(tabSummaries[1])),
              const SizedBox(width: 10),
              Expanded(child: _TabCard.fromModel(tabSummaries[2])),
            ],
          ),
        if (tabSummaries.length >= 3) const SizedBox(height: 14),
        if (tabSummaries.length >= 5)
          Row(
            children: [
              Expanded(child: _TabCard.fromModel(tabSummaries[3])),
              const SizedBox(width: 10),
              Expanded(child: _TabCard.fromModel(tabSummaries[4])),
            ],
          ),
        if (state.importAuditLogs.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Nhật ký import gần đây',
            child: Column(
              children: state.importAuditLogs.take(5).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ImportAuditLogTile(log: item),
                );
              }).toList(growable: false),
            ),
          ),
        ],
      ],
    );
  }
}

class _OrdersManagementSection extends StatelessWidget {
  const _OrdersManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý đơn hàng',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.canViewOrders) ...[
            _MiniActionButton(
              label: 'Template',
              onTap: () => AdminExcelCore.exportOrderTemplate(),
            ),
            _MiniActionButton(
              label: 'Xuất Excel',
              onTap: () => _exportOrders(context),
            ),
          ],
          if (state.canManageOrders) ...[
            _MiniActionButton(
              label: 'Nhập Excel',
              onTap: state.isUpdating ? null : () => _importOrders(context),
            ),
            _MiniActionButton(
              label: 'Bulk xử lý',
              onTap: state.isUpdating
                  ? null
                  : () => state.bulkAdvanceFilteredOrders(),
            ),
          ],
        ],
      ),
      child: Column(
        children: [
          _SearchSortRow(
            hintText: 'Tìm mã đơn, khách hàng, trạng thái',
            currentValue: state.orderSearch,
            sortValue: state.orderSort,
            sortItems: const [
              DropdownMenuItem(value: 'latest', child: Text('Mới nhất')),
              DropdownMenuItem(
                  value: 'total_desc', child: Text('Tổng tiền giảm dần')),
            ],
            onChanged: state.setOrderSearch,
            onSortChanged: (value) {
              if (value != null) state.setOrderSort(value);
            },
          ),
          const SizedBox(height: 10),
          _AdminTableHeader(
            columns: const [
              'Mã đơn',
              'Khách hàng',
              'Tổng',
              'Trạng thái',
              'Thao tác'
            ],
            widths: const [2, 3, 2, 2, 2],
          ),
          const SizedBox(height: 10),
          if (state.filteredOrders.isEmpty)
            const _EmptyAdminState(message: 'Chưa có đơn hàng nào.')
          else
            ...List.generate(state.filteredOrders.length, (index) {
              final order = state.filteredOrders[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == state.filteredOrders.length - 1 ? 0 : 8),
                child: _AdminOrderRow(
                  order: order,
                  isUpdating: state.isUpdating,
                  onAdvance: state.canManageOrders
                      ? () => _handleAdvanceOrderStatus(context, state, order)
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _exportOrders(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchOrderExcelRows();
      await AdminExcelCore.exportOrders(rows);
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Đã xuất file Excel đơn hàng.');
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể xuất file Excel đơn hàng.',
          isError: true);
    }
  }

  Future<void> _importOrders(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importOrders();
      if (rows == null) return;
      final result =
          await AppServices.instance.adminRepository.importOrderExcelRows(rows);
      await state.forceReload();
      if (!context.mounted) return;
      await _showImportResultDialog(context, 'đơn hàng', result);
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể import đơn hàng từ file Excel.',
          isError: true);
    }
  }
}

class _ProductsManagementSection extends StatelessWidget {
  const _ProductsManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý sản phẩm',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.canViewProducts) ...[
            _MiniActionButton(
              label: 'Template',
              onTap: () => AdminExcelCore.exportProductTemplate(),
            ),
            _MiniActionButton(
              label: 'Xuất Excel',
              onTap: () => _exportProducts(context),
            ),
          ],
          if (state.canManageProducts) ...[
            _MiniActionButton(
              label: 'Nhập Excel',
              onTap: state.isUpdating ? null : () => _importProducts(context),
            ),
            _MiniActionButton(
              label: 'Thêm sản phẩm',
              onTap: () => context.goNamed(
                AppRouteNames.adminProductForm,
                queryParameters: const {'sidebar': '2'},
              ),
            ),
            _MiniActionButton(
              label: 'Bulk ẩn',
              onTap: state.isUpdating
                  ? null
                  : () => state.bulkHideFilteredProducts(),
            ),
          ],
        ],
      ),
      child: Column(
        children: [
          _SearchSortRow(
            hintText: 'Tìm ID, tên, danh mục',
            currentValue: state.productSearch,
            sortValue: state.productSort,
            sortItems: const [
              DropdownMenuItem(value: 'name', child: Text('Tên A-Z')),
              DropdownMenuItem(
                  value: 'price_desc', child: Text('Giá giảm dần')),
              DropdownMenuItem(value: 'price_asc', child: Text('Giá tăng dần')),
            ],
            onChanged: state.setProductSearch,
            onSortChanged: (value) {
              if (value != null) state.setProductSort(value);
            },
          ),
          const SizedBox(height: 10),
          _AdminTableHeader(
            columns: const [
              'ID',
              'Tên sản phẩm',
              'Danh mục',
              'Giá',
              'Tồn kho',
              'Thao tác'
            ],
            widths: const [1, 3, 2, 2, 2, 3],
          ),
          const SizedBox(height: 10),
          if (state.filteredProducts.isEmpty)
            const _EmptyAdminState(message: 'Chưa có sản phẩm nào.')
          else
            ...List.generate(state.filteredProducts.length, (index) {
              final product = state.filteredProducts[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom: index == state.filteredProducts.length - 1 ? 0 : 8),
                child: _AdminProductRow(
                  product: product,
                  isUpdating: state.isUpdating,
                  onEdit: state.canManageProducts
                      ? () => context.goNamed(
                            AppRouteNames.adminProductForm,
                            queryParameters: {
                              'id': '${product.id}',
                              'sidebar': '2'
                            },
                          )
                      : null,
                  onToggle: state.canManageProducts
                      ? () => state.toggleProductStock(product)
                      : null,
                  onDelete: state.canManageProducts
                      ? () => _confirmDangerAction(
                            context,
                            message: 'Xóa sản phẩm "${product.title}"?',
                            onConfirm: () => state.deleteProduct(product),
                          )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _exportProducts(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchProductExcelRows();
      await AdminExcelCore.exportProducts(rows);
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Đã xuất file Excel sản phẩm.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể xuất file Excel sản phẩm.',
          isError: true);
    }
  }

  Future<void> _importProducts(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importProducts();
      if (rows == null) {
        return;
      }
      if (rows.isEmpty) {
        if (!context.mounted) {
          return;
        }
        _showAdminSnackBar(
            context, 'File Excel không có dữ liệu sản phẩm hợp lệ.',
            isError: true);
        return;
      }
      final result = await AppServices.instance.adminRepository
          .importProductExcelRows(rows);
      await state.refreshProductsSection();
      if (!context.mounted) {
        return;
      }
      await _showImportResultDialog(context, 'sản phẩm', result);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể import sản phẩm từ file Excel.',
          isError: true);
    }
  }
}

class _CategoriesManagementSection extends StatelessWidget {
  const _CategoriesManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý danh mục',
      action: state.canManageProducts
          ? _MiniActionButton(
              label: 'Thêm danh mục',
              onTap: () => _showCategoryDialog(context, state),
            )
          : null,
      child: Column(
        children: [
          _AdminTableHeader(
            columns: const [
              'Ảnh',
              'Tên hiển thị',
              'Giá trị',
              'Thứ tự',
              'Thao tác'
            ],
            widths: const [1, 3, 3, 1, 3],
          ),
          const SizedBox(height: 10),
          if (state.categories.isEmpty)
            const _EmptyAdminState(message: 'Chưa có danh mục nào.')
          else
            ...List.generate(state.categories.length, (index) {
              final category = state.categories[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index == state.categories.length - 1 ? 0 : 8,
                ),
                child: _AdminCategoryRow(
                  category: category,
                  isUpdating: state.isUpdating,
                  onEdit: state.canManageProducts
                      ? () => _showCategoryDialog(context, state,
                          category: category)
                      : null,
                  onDelete: state.canManageProducts
                      ? () => _confirmDangerAction(
                            context,
                            message: 'Xóa danh mục "${category.label}"?',
                            onConfirm: () => state.deleteCategory(category),
                          )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _CustomersManagementSection extends StatelessWidget {
  const _CustomersManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý khách hàng',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.canViewCustomers) ...[
            _MiniActionButton(
              label: 'Template',
              onTap: () => AdminExcelCore.exportCustomerTemplate(),
            ),
            _MiniActionButton(
              label: 'Xuất Excel',
              onTap: () => _exportCustomers(context),
            ),
          ],
          if (state.canManageCustomers)
            _MiniActionButton(
              label: 'Nhập Excel',
              onTap: state.isUpdating ? null : () => _importCustomers(context),
            ),
        ],
      ),
      child: Column(
        children: [
          _SearchSortRow(
            hintText: 'Tìm tên, email, số điện thoại',
            currentValue: state.customerSearch,
            sortValue: state.customerSort,
            sortItems: const [
              DropdownMenuItem(value: 'name', child: Text('Tên A-Z')),
              DropdownMenuItem(
                  value: 'orders_desc', child: Text('Nhiều đơn nhất')),
            ],
            onChanged: state.setCustomerSearch,
            onSortChanged: (value) {
              if (value != null) state.setCustomerSort(value);
            },
          ),
          const SizedBox(height: 10),
          _AdminTableHeader(
            columns: const ['Họ tên', 'Email', 'SĐT', 'Đơn hàng', 'Vai trò'],
            widths: const [3, 3, 2, 1, 1],
          ),
          const SizedBox(height: 10),
          if (state.filteredCustomers.isEmpty)
            const _EmptyAdminState(message: 'Chưa có khách hàng nào.')
          else
            ...List.generate(state.filteredCustomers.length, (index) {
              final customer = state.filteredCustomers[index];
              return Padding(
                padding: EdgeInsets.only(
                    bottom:
                        index == state.filteredCustomers.length - 1 ? 0 : 8),
                child: _AdminCustomerRow(
                  customer: customer,
                  onEdit: state.canManageCustomers
                      ? () => context.goNamed(
                            AppRouteNames.adminCustomerForm,
                            queryParameters: {
                              'id': customer.id,
                              'sidebar': '3'
                            },
                          )
                      : null,
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _exportCustomers(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchCustomerExcelRows();
      await AdminExcelCore.exportCustomers(rows);
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Đã xuất file Excel khách hàng.');
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể xuất file Excel khách hàng.',
          isError: true);
    }
  }

  Future<void> _importCustomers(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importCustomers();
      if (rows == null) return;
      final result = await AppServices.instance.adminRepository
          .importCustomerExcelRows(rows);
      await state.forceReload();
      if (!context.mounted) return;
      await _showImportResultDialog(context, 'khách hàng', result);
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể import khách hàng từ file Excel.',
          isError: true);
    }
  }
}

class _IngredientsManagementSection extends StatelessWidget {
  const _IngredientsManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    final lowStockCount = state.ingredients
        .where((item) => item.status.toLowerCase() != 'đủ hàng')
        .length;
    final totalQuantity = state.ingredients.fold<int>(
      0,
      (sum, item) => sum + item.availableQuantity,
    );
    final totalInventoryValue = state.ingredients.fold<int>(
      0,
      (sum, item) => sum + (item.unitPrice * item.availableQuantity),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                'Nguyên liệu theo dõi',
                '${state.ingredients.length}',
                AdminColors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                'Cần nhập thêm',
                '$lowStockCount',
                lowStockCount > 0 ? AdminColors.orange : AdminColors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                'Tổng số lượng',
                '$totalQuantity',
                AdminColors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                'Giá trị tồn',
                _formatCurrency(totalInventoryValue),
                AdminColors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Kho nguyên liệu',
          action: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (state.canViewInventory) ...[
                _MiniActionButton(
                  label: 'Template',
                  onTap: () => AdminExcelCore.exportIngredientTemplate(),
                ),
                _MiniActionButton(
                  label: 'Xuất Excel',
                  onTap: () => _exportIngredients(context),
                ),
              ],
              if (state.canManageInventory) ...[
                _MiniActionButton(
                  label: 'Nhập Excel',
                  onTap: state.isUpdating
                      ? null
                      : () => _importIngredients(context),
                ),
                _MiniActionButton(
                  label: 'Thêm nguyên liệu',
                  onTap: () => context.goNamed(
                    AppRouteNames.adminIngredientForm,
                    queryParameters: const {'sidebar': '4'},
                  ),
                ),
              ],
            ],
          ),
          child: Column(
            children: [
              _SearchSortRow(
                hintText: 'Tìm tên, danh mục, trạng thái',
                currentValue: state.ingredientSearch,
                sortValue: state.ingredientSort,
                sortItems: const [
                  DropdownMenuItem(value: 'name', child: Text('Tên A-Z')),
                  DropdownMenuItem(
                      value: 'stock_asc', child: Text('Tồn thấp nhất')),
                  DropdownMenuItem(
                      value: 'stock_desc', child: Text('Tồn cao nhất')),
                ],
                onChanged: state.setIngredientSearch,
                onSortChanged: (value) {
                  if (value != null) state.setIngredientSort(value);
                },
              ),
              const SizedBox(height: 10),
              _AdminTableHeader(
                columns: const [
                  'Tên',
                  'Danh mục',
                  'Giá',
                  'Đơn vị',
                  'Đơn giá',
                  'Tồn',
                  'Ngưỡng',
                  'Trạng thái',
                  'Thao tác'
                ],
                widths: const [3, 2, 2, 1, 2, 1, 1, 2, 3],
              ),
              const SizedBox(height: 10),
              if (state.filteredIngredients.isEmpty)
                const _EmptyAdminState(message: 'Chưa có nguyên liệu nào.')
              else
                ...List.generate(state.filteredIngredients.length, (index) {
                  final ingredient = state.filteredIngredients[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom:
                          index == state.filteredIngredients.length - 1 ? 0 : 8,
                    ),
                    child: _AdminIngredientRow(
                      ingredient: ingredient,
                      isUpdating: state.isUpdating,
                      onEdit: state.canManageInventory
                          ? () => context.goNamed(
                                AppRouteNames.adminIngredientForm,
                                queryParameters: {
                                  'id': ingredient.id,
                                  'sidebar': '4'
                                },
                              )
                          : null,
                      onDelete: state.canManageInventory
                          ? () => _confirmDangerAction(
                                context,
                                message:
                                    'Xóa nguyên liệu "${ingredient.name}"?',
                                onConfirm: () =>
                                    state.deleteIngredient(ingredient),
                              )
                          : null,
                      onAdd: state.canManageInventory
                          ? () =>
                              state.restockIngredient(ingredient, quantity: 5)
                          : null,
                      onConsume: state.canManageInventory
                          ? () =>
                              state.consumeIngredient(ingredient, quantity: 1)
                          : null,
                    ),
                  );
                }),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Lịch sử nhập/xuất kho',
          child: state.inventoryTransactions.isEmpty
              ? const _EmptyAdminState(
                  message: 'Chưa có giao dịch kho nào.',
                )
              : Column(
                  children: state.inventoryTransactions.take(8).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _InventoryTransactionTile(transaction: item),
                    );
                  }).toList(growable: false),
                ),
        ),
      ],
    );
  }

  Future<void> _exportIngredients(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchIngredientExcelRows();
      await AdminExcelCore.exportIngredients(rows);
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Đã xuất file Excel nguyên liệu.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể xuất file Excel nguyên liệu.',
          isError: true);
    }
  }

  Future<void> _importIngredients(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importIngredients();
      if (rows == null) {
        return;
      }
      if (rows.isEmpty) {
        if (!context.mounted) {
          return;
        }
        _showAdminSnackBar(
            context, 'File Excel không có dữ liệu nguyên liệu hợp lệ.',
            isError: true);
        return;
      }
      final result = await AppServices.instance.adminRepository
          .importIngredientExcelRows(rows);
      await state.refreshIngredientsSection();
      if (!context.mounted) {
        return;
      }
      await _showImportResultDialog(context, 'nguyên liệu', result);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể import nguyên liệu từ file Excel.',
          isError: true);
    }
  }
}

class _RecipesManagementSection extends StatelessWidget {
  const _RecipesManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý công thức',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.canViewRecipes) ...[
            _MiniActionButton(
              label: 'Template',
              onTap: () => AdminExcelCore.exportRecipeTemplate(),
            ),
            _MiniActionButton(
              label: 'Xuất Excel',
              onTap: () => _exportRecipes(context),
            ),
          ],
          if (state.canManageRecipes) ...[
            _MiniActionButton(
              label: 'Nhập Excel',
              onTap: state.isUpdating ? null : () => _importRecipes(context),
            ),
            _MiniActionButton(
              label: 'Tạo công thức',
              onTap: () => context.goNamed(
                AppRouteNames.adminRecipeForm,
                queryParameters: const {'sidebar': '5'},
              ),
            ),
          ],
        ],
      ),
      child: state.recipes.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có công thức nào.')
          : Column(
              children: state.recipes.map((recipe) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: const Color(0xFFE5E7EB), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.productTitle,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AdminColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _recipeYieldLabel(recipe),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.textSoft,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.recipeType == 'semi_finished'
                              ? 'Loại: Bán thành phẩm'
                              : 'Loại: Thành phẩm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: recipe.recipeType == 'semi_finished'
                                ? AdminColors.orange
                                : AdminColors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cost theo mẻ: ${_formatCurrency(recipe.totalCost)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cost / ${recipe.yieldUnit}: ${_formatCurrency(recipe.costPerUnit)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lợi nhuận gộp ước tính: ${_formatCurrency(recipe.grossProfitEstimate)} • ${recipe.grossMarginPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AdminColors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...recipe.ingredients.map((ingredient) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• ${ingredient.ingredientName}: ${ingredient.quantity} ${ingredient.unit} / mẻ • hao hụt ${ingredient.wastePercent}%'
                              '${ingredient.sourceType == 'recipe' ? ' • bán thành phẩm' : ''}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniActionButton(
                              label: 'Sửa',
                              onTap: state.canManageRecipes
                                  ? () => context.goNamed(
                                        AppRouteNames.adminRecipeForm,
                                        queryParameters: {
                                          'id': recipe.id,
                                          'sidebar': '5'
                                        },
                                      )
                                  : null,
                            ),
                            _MiniActionButton(
                              label: 'Copy',
                              onTap: state.canManageRecipes
                                  ? () => _openCopyRecipeDialog(
                                      context, state, recipe)
                                  : null,
                            ),
                            _MiniActionButton(
                              label: 'Xóa',
                              onTap: !state.canManageRecipes || state.isUpdating
                                  ? null
                                  : () => _confirmDangerAction(
                                        context,
                                        message:
                                            'Xóa công thức của "${recipe.productTitle}"?',
                                        onConfirm: () =>
                                            state.deleteRecipe(recipe),
                                      ),
                              backgroundColor: AdminColors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }

  Future<void> _exportRecipes(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchRecipeExcelRows();
      await AdminExcelCore.exportRecipes(rows);
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Đã xuất file Excel công thức.');
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể xuất file Excel công thức.',
          isError: true);
    }
  }

  Future<void> _importRecipes(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importRecipes();
      if (rows == null) return;
      final result = await AppServices.instance.adminRepository
          .importRecipeExcelRows(rows);
      await state.reloadRecipes();
      if (!context.mounted) return;
      await _showImportResultDialog(context, 'công thức', result);
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể import công thức từ file Excel.',
          isError: true);
    }
  }
}

class _ProfitSummarySection extends StatelessWidget {
  const _ProfitSummarySection({required this.state});

  final AdminState state;

  static const _ranges = [
    ('today', 'Hôm nay'),
    ('yesterday', 'Hôm qua'),
    ('7d', '7 ngày'),
    ('30d', '30 ngày'),
    ('this_month', 'Tháng này'),
    ('last_month', 'Tháng trước'),
  ];

  @override
  Widget build(BuildContext context) {
    final summary = state.revenueSummary;
    final selectedRange = state.revenueRange;

    return _SectionCard(
      title: 'Doanh số',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Filter chips ──
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _ranges.map((r) {
              final (key, label) = r;
              final active = key == selectedRange;
              return GestureDetector(
                onTap: () => state.refreshRevenueSummary(range: key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active ? AdminColors.blue : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active ? AdminColors.blue : AdminColors.borderSoft,
                    ),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AdminColors.textSoft,
                    ),
                  ),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 16),

          // ── Summary KPI cards ──
          LayoutBuilder(builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 480;
            final cards = [
              _RevenueKpiCard(
                label: 'Tổng doanh thu',
                value: _formatCurrency(summary.totalRevenue),
                color: AdminColors.blue,
              ),
              _RevenueKpiCard(
                label: 'Số đơn hàng',
                value: '${summary.totalOrders}',
                color: AdminColors.green,
              ),
              _RevenueKpiCard(
                label: 'Giá trị TB / đơn',
                value: summary.totalOrders > 0
                    ? _formatCurrency(summary.avgOrderValue)
                    : '—',
                color: AdminColors.orange,
              ),
            ];
            if (isNarrow) {
              return Column(
                children: cards
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: SizedBox(width: double.infinity, child: c),
                        ))
                    .toList(growable: false),
              );
            }
            return Row(
              children: cards
                  .expand((c) => [Expanded(child: c), const SizedBox(width: 8)])
                  .take(cards.length * 2 - 1)
                  .toList(growable: false),
            );
          }),
          const SizedBox(height: 20),

          // ── Bar chart ──
          if (summary.days.isEmpty)
            Container(
              height: 140,
              alignment: Alignment.center,
              child: const Text(
                'Chưa có dữ liệu trong khoảng thời gian này.',
                style: TextStyle(color: AdminColors.textSoft, fontSize: 13),
              ),
            )
          else
            _RevenueBarChart(days: summary.days),

          const SizedBox(height: 24),

          // ── Cost report per product ──
          const Divider(color: AdminColors.line),
          const SizedBox(height: 12),
          const Text(
            'Biên lợi nhuận theo sản phẩm',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AdminColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          if (state.productCostReports.isEmpty)
            const _EmptyAdminState(message: 'Chưa có dữ liệu cost sản phẩm.')
          else
            Column(
              children: state.productCostReports.take(10).map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ProductCostReportTile(report: item),
                );
              }).toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _RevenueKpiCard extends StatelessWidget {
  const _RevenueKpiCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.days});

  final List<AdminRevenueDayModel> days;

  @override
  Widget build(BuildContext context) {
    final maxRevenue =
        days.fold<int>(0, (m, d) => d.revenue > m ? d.revenue : m);

    return SizedBox(
      height: 160,
      child: LayoutBuilder(builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final count = days.length;
        // bar + gap per item
        const gap = 4.0;
        final barWidth =
            ((availableWidth - gap * (count - 1)) / count).clamp(4.0, 40.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(count, (i) {
            final day = days[i];
            final ratio = maxRevenue > 0 ? day.revenue / maxRevenue : 0.0;
            final barHeight = (ratio * 120).clamp(2.0, 120.0);
            final isEmpty = day.revenue == 0;

            // Show label every N days to avoid clutter
            final labelEvery = count <= 7
                ? 1
                : count <= 14
                    ? 2
                    : count <= 31
                        ? 5
                        : 7;
            final showLabel = i % labelEvery == 0 || i == count - 1;

            return Padding(
              padding: EdgeInsets.only(right: i < count - 1 ? gap : 0),
              child: SizedBox(
                width: barWidth,
                height: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Tooltip(
                      message:
                          '${day.date}\n${_formatCurrency(day.revenue)}\n${day.orderCount} đơn',
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: barWidth,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: isEmpty
                              ? AdminColors.line
                              : AdminColors.blue.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (showLabel)
                      Text(
                        _shortDate(day.date),
                        style: const TextStyle(
                          fontSize: 9,
                          color: AdminColors.textSoft,
                        ),
                        overflow: TextOverflow.visible,
                        softWrap: false,
                      )
                    else
                      const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          }),
        );
      }),
    );
  }

  String _shortDate(String date) {
    // date format: "2026-05-13" → "13/5"
    final parts = date.split('-');
    if (parts.length == 3)
      return '${int.tryParse(parts[2]) ?? parts[2]}/${int.tryParse(parts[1]) ?? parts[1]}';
    return date;
  }
}

class _VouchersManagementSection extends StatelessWidget {
  const _VouchersManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý voucher',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.canViewVouchers) ...[
            _MiniActionButton(
              label: 'Template',
              onTap: () => AdminExcelCore.exportVoucherTemplate(),
            ),
            _MiniActionButton(
              label: 'Xuất Excel',
              onTap: () => _exportVouchers(context),
            ),
          ],
          if (state.canManageVouchers) ...[
            _MiniActionButton(
              label: 'Nhập Excel',
              onTap: state.isUpdating ? null : () => _importVouchers(context),
            ),
            _MiniActionButton(
              label: 'Thêm voucher',
              onTap: () => _openVoucherDialog(context, state),
            ),
          ],
        ],
      ),
      child: state.vouchers.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có voucher nào.')
          : Column(
              children: state.vouchers.map((voucher) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _box(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${voucher.code} • ${voucher.title}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${voucher.discountType} • ${voucher.discountValue} • Đơn tối thiểu ${_formatCurrency(voucher.minOrderValue)}',
                                style: const TextStyle(
                                    fontSize: 12, color: AdminColors.textSoft),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            _MiniActionButton(
                              label: 'Sửa',
                              onTap: state.canManageVouchers
                                  ? () => _openVoucherDialog(
                                        context,
                                        state,
                                        initial: AdminVoucherDraft.fromVoucher(
                                            voucher),
                                      )
                                  : null,
                            ),
                            _MiniActionButton(
                              label: 'Xóa',
                              backgroundColor: AdminColors.red,
                              onTap: state.canManageVouchers
                                  ? () => _confirmDangerAction(
                                        context,
                                        message:
                                            'Xóa voucher "${voucher.code}"?',
                                        onConfirm: () =>
                                            state.deleteVoucher(voucher),
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }

  Future<void> _exportVouchers(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchVoucherExcelRows();
      await AdminExcelCore.exportVouchers(rows);
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Đã xuất file Excel voucher.');
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể xuất file Excel voucher.',
          isError: true);
    }
  }

  Future<void> _importVouchers(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importVouchers();
      if (rows == null) return;
      final result = await AppServices.instance.adminRepository
          .importVoucherExcelRows(rows);
      await state.forceReload();
      if (!context.mounted) return;
      await _showImportResultDialog(context, 'voucher', result);
    } catch (_) {
      if (!context.mounted) return;
      _showAdminSnackBar(context, 'Không thể import voucher từ file Excel.',
          isError: true);
    }
  }
}

class _TestimonialsManagementSection extends StatelessWidget {
  const _TestimonialsManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý đánh giá',
      child: state.testimonials.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có đánh giá nào.')
          : Column(
              children: state.testimonials.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _box(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.author,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.textDark,
                                ),
                              ),
                            ),
                            Text(
                              item.isVisible ? 'Đang hiển thị' : 'Đã ẩn',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: item.isVisible
                                    ? AdminColors.green
                                    : AdminColors.orange,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(item.content,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _MiniActionButton(
                              label: item.isVisible ? 'Ẩn' : 'Hiện',
                              onTap: state.canManageTestimonials
                                  ? () => state.toggleTestimonial(item)
                                  : null,
                            ),
                            _MiniActionButton(
                              label: 'Xóa',
                              backgroundColor: AdminColors.red,
                              onTap: state.canManageTestimonials
                                  ? () => _confirmDangerAction(
                                        context,
                                        message:
                                            'Xóa đánh giá của "${item.author}"?',
                                        onConfirm: () =>
                                            state.deleteTestimonial(item),
                                      )
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _ContentsManagementSection extends StatelessWidget {
  const _ContentsManagementSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý nội dung trang',
      child: state.contents.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có nội dung nào.')
          : Column(
              children: state.contents.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _box(),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AdminColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.key,
                                style: const TextStyle(
                                    fontSize: 12, color: AdminColors.textSoft),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniActionButton(
                              label: 'Biểu mẫu',
                              onTap: state.canManageContents
                                  ? () => _openStructuredContentDialog(
                                        context,
                                        state,
                                        item,
                                      )
                                  : null,
                            ),
                            _MiniActionButton(
                              label: 'JSON',
                              onTap: state.canManageContents
                                  ? () =>
                                      _openContentDialog(context, state, item)
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _AdminMobileLayout extends StatelessWidget {
  final AdminState state;
  final bool showTopHeader;
  const _AdminMobileLayout({required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: state,
        builder: (context, _) => SizedBox(
              width: 390,
              height: double.infinity,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  border: Border.all(color: const Color(0xFFD3D8E1), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showTopHeader)
                      const PixelHeaderBar(
                          rightLabel: 'admin',
                          showBack: true,
                          showBrand: false),
                    if (showTopHeader) const SizedBox(height: 10),
                    Expanded(
                      child: state.isLoading
                          ? Padding(
                              padding: const EdgeInsets.all(8),
                              child: _AdminLoadingSkeleton(),
                            )
                          : SingleChildScrollView(
                              child: DefaultTextStyle.merge(
                                style: const TextStyle(
                                  color: AdminColors.textDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                child: IconTheme.merge(
                                  data: const IconThemeData(
                                      color: AdminColors.textDark),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height: 36,
                                        child: ListView(
                                          scrollDirection: Axis.horizontal,
                                          children: state.sidebarItems
                                              .map(
                                                (item) => _MobileSectionChip(
                                                  label: item.label,
                                                  active: state
                                                          .selectedSidebarIndex ==
                                                      item.index,
                                                  onTap: () =>
                                                      state.selectSidebar(
                                                          item.index),
                                                ),
                                              )
                                              .toList(growable: false),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      if (state.selectedSidebarIndex == 1) ...[
                                        _MobileAdminOrdersSection(state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          2) ...[
                                        _MobileAdminProductsSection(
                                            state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          3) ...[
                                        _MobileAdminCustomersSection(
                                            state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          4) ...[
                                        _MobileAdminIngredientsSection(
                                            state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          5) ...[
                                        _MobileAdminRecipesSection(
                                            state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          6) ...[
                                        _VouchersManagementSection(
                                            state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          7) ...[
                                        _TestimonialsManagementSection(
                                            state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          8) ...[
                                        _ContentsManagementSection(
                                            state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          9) ...[
                                        _ProfitSummarySection(state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          10) ...[
                                        _ReviewsManagementSection(state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          11) ...[
                                        _SmartAnalyticsSection(state: state),
                                      ] else if (state.selectedSidebarIndex ==
                                          12) ...[
                                        _MobileAdminCategoriesSection(
                                            state: state),
                                      ] else ...[
                                        AnimatedBuilder(
                                          animation: state,
                                          builder: (context, _) => Container(
                                            height: 56,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: AdminColors.line,
                                                  width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                Text(state.dashboard.title,
                                                    style: const TextStyle(
                                                        color: AdminColors
                                                            .textDark,
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                const Spacer(),
                                                Text(
                                                    state.dashboard
                                                        .notificationLabel,
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFF2563EB),
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedBuilder(
                                          animation: state,
                                          builder: (context, _) {
                                            final cards =
                                                state.dashboard.statCards;
                                            return Row(
                                              children: [
                                                Expanded(
                                                    child: _MobileKpi(
                                                        cards.length > 1
                                                            ? cards[1].label
                                                            : 'Đơn mới',
                                                        cards.length > 1
                                                            ? cards[1].value
                                                            : '0')),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                    child: _MobileKpi(
                                                        cards.isNotEmpty
                                                            ? cards[0].label
                                                            : 'Doanh thu',
                                                        cards.isNotEmpty
                                                            ? cards[0].value
                                                            : '0đ')),
                                              ],
                                            );
                                          },
                                        ),
                                        const SizedBox(height: 10),
                                        const Text('Đơn gần đây',
                                            style: TextStyle(
                                                color: AdminColors.textDark,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 8),
                                        AnimatedBuilder(
                                          animation: state,
                                          builder: (context, _) => _MobileList(
                                              orders:
                                                  state.dashboard.recentOrders),
                                        ),
                                        const SizedBox(height: 10),
                                        const Row(
                                          children: [
                                            Expanded(
                                                child: _ActionButton('Tạo đơn',
                                                    filled: true, h: 42)),
                                            SizedBox(width: 8),
                                            Expanded(
                                                child: _ActionButton('Báo cáo',
                                                    h: 42)),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedBuilder(
                                          animation: state,
                                          builder: (context, _) => Container(
                                            height: 64,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: _toneBackground(state
                                                      .dashboard
                                                      .alerts
                                                      .isNotEmpty
                                                  ? state.dashboard.alerts.first
                                                      .tone
                                                  : 'info'),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  state.dashboard.alerts
                                                          .isNotEmpty
                                                      ? state.dashboard.alerts
                                                          .first.title
                                                      : 'Không có cảnh báo',
                                                  style: TextStyle(
                                                      color: _toneTitleColor(
                                                          state.dashboard.alerts
                                                                  .isNotEmpty
                                                              ? state
                                                                  .dashboard
                                                                  .alerts
                                                                  .first
                                                                  .tone
                                                              : 'info'),
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700),
                                                ),
                                                Text(
                                                  state.dashboard.alerts
                                                          .isNotEmpty
                                                      ? state.dashboard.alerts
                                                          .first.description
                                                      : 'Hệ thống đang ổn định',
                                                  style: TextStyle(
                                                      color: _toneDescColor(
                                                          state.dashboard.alerts
                                                                  .isNotEmpty
                                                              ? state
                                                                  .dashboard
                                                                  .alerts
                                                                  .first
                                                                  .tone
                                                              : 'info'),
                                                      fontSize: 11),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedBuilder(
                                          animation: state,
                                          builder: (context, _) => Container(
                                            height: 212,
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: AdminColors.line,
                                                  width: 1),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    state.dashboard
                                                        .topTrendLabel,
                                                    style: const TextStyle(
                                                        color: AdminColors.blue,
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w800)),
                                                SizedBox(height: 4),
                                                Text(
                                                    '${state.dashboard.topTrendValue} • ${state.dashboard.notificationLabel}',
                                                    style: const TextStyle(
                                                        color:
                                                            AdminColors.green,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                                SizedBox(height: 8),
                                                _MobileBars(
                                                    values: state
                                                        .dashboard.salesByHour),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                        child: _ActionButton(
                                                            'Đơn hàng',
                                                            h: 34)),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                        child: _ActionButton(
                                                            'Sản phẩm',
                                                            h: 34)),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                        child: _ActionButton(
                                                            'Khách hàng',
                                                            h: 34)),
                                                  ],
                                                ),
                                                SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Expanded(
                                                        child: _ActionButton(
                                                            'Nguyên liệu',
                                                            h: 30)),
                                                    SizedBox(width: 8),
                                                    Expanded(
                                                        child: _ActionButton(
                                                            'Doanh số',
                                                            h: 30)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (state.errorMessage != null) ...[
                                          const SizedBox(height: 10),
                                          _InlineMessage(
                                              message: state.errorMessage!,
                                              tone: 'danger'),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ), // end SingleChildScrollView
                  ],
                ),
              ),
            ));
  }
}

class _TopInput extends StatelessWidget {
  final String text;
  final double width;
  final Color color;
  final FontWeight weight;
  final bool centered;
  final double size;
  const _TopInput(
    this.text, {
    required this.width,
    this.color = AdminColors.gray,
    this.weight = FontWeight.w400,
    this.centered = false,
    this.size = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 40,
      alignment: centered ? Alignment.center : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AdminColors.gray, width: 1),
      ),
      child: Text(text,
          style: TextStyle(color: color, fontSize: size, fontWeight: weight)),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.action,
  });

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AdminColors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SearchSortRow extends StatelessWidget {
  const _SearchSortRow({
    required this.hintText,
    required this.currentValue,
    required this.sortValue,
    required this.sortItems,
    required this.onChanged,
    required this.onSortChanged,
  });

  final String hintText;
  final String currentValue;
  final String sortValue;
  final List<DropdownMenuItem<String>> sortItems;
  final ValueChanged<String> onChanged;
  final ValueChanged<String?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: currentValue,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD6DCE5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD6DCE5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AdminColors.blue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: DropdownButtonFormField<String>(
              value: sortValue,
              items: sortItems,
              onChanged: onSortChanged,
              decoration: InputDecoration(
                labelText: 'Sắp xếp',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD6DCE5)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFD6DCE5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AdminColors.blue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminProductRow extends StatelessWidget {
  const _AdminProductRow({
    required this.product,
    required this.isUpdating,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminProductModel product;
  final bool isUpdating;
  final VoidCallback? onToggle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text('${product.id}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(
              flex: 3,
              child: Text(product.title, style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 2,
              child:
                  Text(product.category, style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(_formatCurrency(product.priceValue),
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: Text(
              product.stockStatus,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: product.stockStatus.toLowerCase() == 'còn hàng'
                    ? AdminColors.green
                    : AdminColors.orange,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  _MiniActionButton(
                    label: 'Sửa',
                    onTap: onEdit,
                  ),
                  _MiniActionButton(
                    label: isUpdating
                        ? 'Đang cập nhật'
                        : (product.stockStatus.toLowerCase() == 'còn hàng'
                            ? 'Tạm ẩn'
                            : 'Mở bán'),
                    onTap: isUpdating ? null : onToggle,
                  ),
                  _MiniActionButton(
                    label: 'Xóa',
                    onTap: isUpdating ? null : onDelete,
                    backgroundColor: AdminColors.red,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCategoryRow extends StatelessWidget {
  const _AdminCategoryRow({
    required this.category,
    required this.isUpdating,
    this.onEdit,
    this.onDelete,
  });

  final AdminCategoryModel category;
  final bool isUpdating;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _CategoryImageThumb(imageUrl: category.imageUrl),
          ),
          Expanded(
            flex: 3,
            child: Text(
              category.label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          Expanded(
              flex: 3,
              child: Text(category.category,
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 1,
              child: Text('${category.sortOrder}',
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _MiniActionButton(
                    label: 'Sửa', onTap: isUpdating ? null : onEdit),
                _MiniActionButton(
                  label: 'Xóa',
                  onTap: isUpdating ? null : onDelete,
                  backgroundColor: AdminColors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryImageThumb extends StatelessWidget {
  const _CategoryImageThumb({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = (imageUrl ?? '').trim();
    const size = 42.0;
    if (url.isEmpty) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Icon(Icons.image_outlined,
            size: 18, color: AdminColors.textSoft),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          color: const Color(0xFFFCEAEA),
          child: const Icon(Icons.broken_image_outlined,
              size: 18, color: AdminColors.red),
        ),
      ),
    );
  }
}

class _AdminTableHeader extends StatelessWidget {
  const _AdminTableHeader({
    required this.columns,
    required this.widths,
  });

  final List<String> columns;
  final List<int> widths;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: List.generate(columns.length, (index) {
          return Expanded(
            flex: widths[index],
            child: Text(
              columns[index],
              style: const TextStyle(
                fontSize: 12,
                color: AdminColors.textSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _AdminOrderRow extends StatelessWidget {
  const _AdminOrderRow({
    required this.order,
    required this.isUpdating,
    required this.onAdvance,
  });

  final AdminOrderModel order;
  final bool isUpdating;
  final VoidCallback? onAdvance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text('#${order.orderId}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(
              flex: 3,
              child: Text(order.customerName,
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(_formatCurrency(order.total),
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: Text(order.status,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(order.status))),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _MiniActionButton(
                label: isUpdating ? 'Đang cập nhật' : 'Cập nhật',
                onTap: isUpdating ? null : onAdvance,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminCustomerRow extends StatelessWidget {
  const _AdminCustomerRow({
    required this.customer,
    required this.onEdit,
  });

  final AdminCustomerModel customer;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
              flex: 3,
              child: Text(customer.fullName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700))),
          Expanded(
              flex: 3,
              child:
                  Text(customer.email, style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 2,
              child: Text(customer.phone ?? '-',
                  style: const TextStyle(fontSize: 12))),
          Expanded(
              flex: 1,
              child: Text('${customer.orderCount}',
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  customer.isAdmin ? 'Admin' : 'User',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color:
                        customer.isAdmin ? AdminColors.red : AdminColors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                _MiniActionButton(
                  label: 'Sửa',
                  onTap: onEdit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminIngredientRow extends StatelessWidget {
  const _AdminIngredientRow({
    required this.ingredient,
    required this.isUpdating,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
    required this.onConsume,
  });

  final AdminIngredientModel ingredient;
  final bool isUpdating;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAdd;
  final VoidCallback? onConsume;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              ingredient.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
              flex: 2,
              child: Text(ingredient.category,
                  style: const TextStyle(fontSize: 12))),
          Expanded(
            flex: 2,
            child: Text(
              _formatCurrency(ingredient.price),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${ingredient.priceUnitQuantity} ${ingredient.unit}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${_formatCurrency(ingredient.unitPrice)}/${ingredient.unit}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${ingredient.availableQuantity} ${ingredient.unit}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${ingredient.lowStockThreshold}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ingredient.status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _ingredientStatusColor(ingredient.status),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                _MiniActionButton(
                  label: 'Sửa',
                  onTap: isUpdating ? null : onEdit,
                ),
                _MiniActionButton(
                  label: '-1',
                  onTap: isUpdating || ingredient.availableQuantity <= 0
                      ? null
                      : onConsume,
                ),
                _MiniActionButton(
                  label: isUpdating ? 'Đang cập nhật' : '+5',
                  onTap: isUpdating ? null : onAdd,
                ),
                _MiniActionButton(
                  label: 'Xóa',
                  onTap: isUpdating ? null : onDelete,
                  backgroundColor: AdminColors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.onTap,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: onTap == null
              ? const Color(0xFFE5E7EB)
              : (backgroundColor ?? const Color(0xFF2563EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap == null ? AdminColors.textDark : Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: AdminColors.textSoft,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MobileSectionChip extends StatelessWidget {
  const _MobileSectionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: active ? AdminColors.red : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: active ? AdminColors.red : AdminColors.line, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AdminColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 122,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AdminColors.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w400)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 20, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _OrdersPanel extends StatelessWidget {
  const _OrdersPanel({required this.orders});

  final List<AdminRecentOrderModel> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Đơn hàng gần đây',
              style: TextStyle(
                  color: AdminColors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _orderRow('#Mã', 'Tổng', 'Trạng thái', const Color(0xFFF8F8F8),
              const Color(0xFF8A8A8A),
              bordered: true, h: 34),
          if (orders.isEmpty) ...[
            const SizedBox(height: 8),
            const Text('Chưa có đơn hàng nào.',
                style: TextStyle(fontSize: 12, color: AdminColors.textSoft)),
          ] else
            ...List.generate(orders.length, (index) {
              final order = orders[index];
              return Padding(
                padding: EdgeInsets.only(top: index == 0 ? 8 : 8),
                child: _orderRow(
                  '#${order.orderId}',
                  _formatCurrency(order.total),
                  order.status,
                  Colors.white,
                  _statusColor(order.status),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _orderRow(
      String code, String total, String status, Color bg, Color statusColor,
      {bool bordered = true, double h = 40}) {
    return Container(
      height: h,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: bordered
            ? Border.all(color: const Color(0xFFE0E0E0), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(code,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AdminColors.textDark,
                      fontWeight: FontWeight.w700))),
          Expanded(
              child: Text(total,
                  style: const TextStyle(
                      fontSize: 12, color: AdminColors.textDark))),
          Expanded(
              child: Text(status,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _RightPanel extends StatelessWidget {
  const _RightPanel({
    required this.alerts,
    required this.salesByHour,
    required this.topTrendLabel,
    required this.topTrendValue,
  });

  final List<AdminAlertModel> alerts;
  final List<int> salesByHour;
  final String topTrendLabel;
  final String topTrendValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.borderSoft, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cảnh báo nhanh',
              style: TextStyle(
                  color: AdminColors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...List.generate(alerts.length, (index) {
            final alert = alerts[index];
            return Padding(
              padding:
                  EdgeInsets.only(bottom: index == alerts.length - 1 ? 0 : 10),
              child: _alertBox(
                alert.title,
                alert.description,
                _toneBackground(alert.tone),
                _toneTitleColor(alert.tone),
                _toneDescColor(alert.tone),
              ),
            );
          }),
          const SizedBox(height: 10),
          Container(
            height: 122,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFD6E4FF), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topTrendLabel,
                    style: const TextStyle(
                        color: AdminColors.blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                SizedBox(height: 6),
                Expanded(child: _ChartBars(values: salesByHour)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(topTrendValue,
              style: const TextStyle(
                  color: AdminColors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          const _ActionButton('Tạo đơn nhanh', filled: true, h: 44),
        ],
      ),
    );
  }

  Widget _alertBox(
      String title, String desc, Color bg, Color titleColor, Color descColor) {
    return Container(
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title,
              style: TextStyle(
                  color: titleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: descColor, fontSize: 11)),
        ],
      ),
    );
  }
}

class _TabCard extends StatelessWidget {
  final String title;
  final List<String> rows;
  final String? button;
  final bool compact;
  const _TabCard({
    required this.title,
    required this.rows,
    this.button,
    this.compact = false,
  });

  factory _TabCard.fromModel(AdminTabSummaryModel model) {
    return _TabCard(
      title: model.title,
      rows: model.rows,
      button: model.buttonLabel,
      compact: model.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minHeight: compact ? 160 : 250,
      ),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.borderSoft, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AdminColors.blue,
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...rows.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(e,
                    style: const TextStyle(
                        color: Color(0xFF222222), fontSize: 12)),
              )),
          if (button != null)
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: Text(button!,
                  style: const TextStyle(
                      color: AdminColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _ChartBars extends StatelessWidget {
  const _ChartBars({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ...List.generate(values.length == 4 ? values.length : 4, (index) {
          final resolvedValues =
              values.length == 4 ? values : const [0, 0, 0, 0];
          const colors = [
            Color(0xFF93C5FD),
            Color(0xFF60A5FA),
            Color(0xFF3B82F6),
            Color(0xFF1D4ED8),
          ];
          final maxValue = resolvedValues.fold<int>(
              0, (max, item) => item > max ? item : max);
          final normalizedHeight = maxValue == 0
              ? 18.0
              : 18 + (resolvedValues[index] / maxValue) * 28;
          return _bar(normalizedHeight, colors[index]);
        }),
      ],
    );
  }

  Widget _bar(double h, Color c) {
    return Container(
      width: 52,
      height: h,
      decoration:
          BoxDecoration(color: c, borderRadius: BorderRadius.circular(4)),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final bool filled;
  final double h;
  const _ActionButton(this.text, {this.filled = false, this.h = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: filled ? const Color(0xFF2563EB) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: filled ? Colors.white : AdminColors.textDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MobileKpi extends StatelessWidget {
  final String t;
  final String v;
  const _MobileKpi(this.t, this.v);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(t,
              style: const TextStyle(
                  color: AdminColors.gray,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(v,
              style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _MobileAdminOrdersSection extends StatelessWidget {
  const _MobileAdminOrdersSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý đơn hàng',
      child: state.orders.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có đơn hàng nào.')
          : Column(
              children: state.orders.map((order) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('#${order.orderId}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.textDark)),
                        const SizedBox(height: 4),
                        Text(order.customerName,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(order.total),
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(order.status,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _statusColor(order.status))),
                        const SizedBox(height: 8),
                        _MiniActionButton(
                          label: state.isUpdating
                              ? 'Đang cập nhật'
                              : 'Cập nhật trạng thái',
                          onTap: state.isUpdating
                              ? null
                              : () => _handleAdvanceOrderStatus(
                                  context, state, order),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _MobileAdminProductsSection extends StatelessWidget {
  const _MobileAdminProductsSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý sản phẩm',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.canViewProducts)
            _MiniActionButton(
              label: 'Xuất',
              onTap: () => _exportProducts(context),
            ),
          if (state.canManageProducts) ...[
            _MiniActionButton(
              label: 'Nhập',
              onTap: state.isUpdating ? null : () => _importProducts(context),
            ),
            _MiniActionButton(
              label: 'Thêm',
              onTap: () => context.goNamed(
                AppRouteNames.adminProductForm,
                queryParameters: const {'sidebar': '2'},
              ),
            ),
          ],
        ],
      ),
      child: state.filteredProducts.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có sản phẩm nào.')
          : Column(
              children: state.filteredProducts.map((product) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.title,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.textDark)),
                        const SizedBox(height: 4),
                        Text(product.category,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(product.priceValue),
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(product.stockStatus,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: product.stockStatus.toLowerCase() ==
                                        'còn hàng'
                                    ? AdminColors.green
                                    : AdminColors.orange)),
                        const SizedBox(height: 8),
                        _MiniActionButton(
                          label: 'Sửa',
                          onTap: state.canManageProducts
                              ? () => context.goNamed(
                                    AppRouteNames.adminProductForm,
                                    queryParameters: {
                                      'id': '${product.id}',
                                      'sidebar': '2'
                                    },
                                  )
                              : null,
                        ),
                        const SizedBox(height: 8),
                        _MiniActionButton(
                          label: state.isUpdating
                              ? 'Đang cập nhật'
                              : (product.stockStatus.toLowerCase() == 'còn hàng'
                                  ? 'Tạm ẩn'
                                  : 'Mở bán'),
                          onTap: !state.canManageProducts || state.isUpdating
                              ? null
                              : () => state.toggleProductStock(product),
                        ),
                        const SizedBox(height: 8),
                        _MiniActionButton(
                          label: 'Xóa',
                          onTap: !state.canManageProducts || state.isUpdating
                              ? null
                              : () => _confirmDangerAction(
                                    context,
                                    message: 'Xóa sản phẩm "${product.title}"?',
                                    onConfirm: () =>
                                        state.deleteProduct(product),
                                  ),
                          backgroundColor: AdminColors.red,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }

  Future<void> _exportProducts(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchProductExcelRows();
      await AdminExcelCore.exportProducts(rows);
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Đã xuất file Excel sản phẩm.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể xuất file Excel sản phẩm.',
          isError: true);
    }
  }

  Future<void> _importProducts(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importProducts();
      if (rows == null) {
        return;
      }
      if (rows.isEmpty) {
        if (!context.mounted) {
          return;
        }
        _showAdminSnackBar(
            context, 'File Excel không có dữ liệu sản phẩm hợp lệ.',
            isError: true);
        return;
      }
      final result = await AppServices.instance.adminRepository
          .importProductExcelRows(rows);
      await state.refreshProductsSection();
      if (!context.mounted) {
        return;
      }
      await _showImportResultDialog(context, 'sản phẩm', result);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể import sản phẩm từ file Excel.',
          isError: true);
    }
  }
}

class _MobileAdminCategoriesSection extends StatelessWidget {
  const _MobileAdminCategoriesSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý danh mục',
      action: state.canManageProducts
          ? _MiniActionButton(
              label: 'Thêm',
              onTap: () => _showCategoryDialog(context, state),
            )
          : null,
      child: state.categories.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có danh mục nào.')
          : Column(
              children: state.categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CategoryImageThumb(imageUrl: category.imageUrl),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    category.label,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: AdminColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(category.category,
                                      style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Thứ tự: ${category.sortOrder}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if ((category.imageUrl ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            category.imageUrl!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AdminColors.textSoft,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniActionButton(
                              label: 'Sửa',
                              onTap:
                                  !state.canManageProducts || state.isUpdating
                                      ? null
                                      : () => _showCategoryDialog(
                                            context,
                                            state,
                                            category: category,
                                          ),
                            ),
                            _MiniActionButton(
                              label: 'Xóa',
                              onTap:
                                  !state.canManageProducts || state.isUpdating
                                      ? null
                                      : () => _confirmDangerAction(
                                            context,
                                            message:
                                                'Xóa danh mục "${category.label}"?',
                                            onConfirm: () =>
                                                state.deleteCategory(category),
                                          ),
                              backgroundColor: AdminColors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _MobileAdminCustomersSection extends StatelessWidget {
  const _MobileAdminCustomersSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý khách hàng',
      child: state.filteredCustomers.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có khách hàng nào.')
          : Column(
              children: state.filteredCustomers.map((customer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer.fullName,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.textDark)),
                        const SizedBox(height: 4),
                        Text(customer.email,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('SĐT: ${customer.phone ?? '-'}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('Đơn hàng: ${customer.orderCount}',
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                            customer.isAdmin
                                ? 'Vai trò: Admin'
                                : 'Vai trò: User',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: customer.isAdmin
                                    ? AdminColors.red
                                    : AdminColors.blue)),
                        const SizedBox(height: 8),
                        _MiniActionButton(
                          label: 'Sửa',
                          onTap: state.canManageCustomers
                              ? () => context.goNamed(
                                    AppRouteNames.adminCustomerForm,
                                    queryParameters: {
                                      'id': customer.id,
                                      'sidebar': '3'
                                    },
                                  )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

class _MobileAdminIngredientsSection extends StatelessWidget {
  const _MobileAdminIngredientsSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Kho nguyên liệu',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (state.canViewInventory)
            _MiniActionButton(
              label: 'Xuất',
              onTap: () => _exportIngredients(context),
            ),
          if (state.canManageInventory) ...[
            _MiniActionButton(
              label: 'Nhập',
              onTap:
                  state.isUpdating ? null : () => _importIngredients(context),
            ),
            _MiniActionButton(
              label: 'Thêm',
              onTap: () => context.goNamed(
                AppRouteNames.adminIngredientForm,
                queryParameters: const {'sidebar': '4'},
              ),
            ),
          ],
        ],
      ),
      child: Column(
        children: [
          if (state.filteredIngredients.isEmpty)
            const _EmptyAdminState(message: 'Chưa có nguyên liệu nào.')
          else
            ...state.filteredIngredients.map((ingredient) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ingredient.name,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AdminColors.textDark)),
                      const SizedBox(height: 4),
                      Text(
                        '${ingredient.category} • ${_formatCurrency(ingredient.price)} / ${ingredient.priceUnitQuantity} ${ingredient.unit}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đơn giá: ${_formatCurrency(ingredient.unitPrice)} / ${ingredient.unit}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text('${ingredient.availableQuantity} ${ingredient.unit}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                          'Chuẩn: ${ingredient.availableNormalizedQuantity} ${ingredient.standardUnit}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('Ngưỡng cảnh báo: ${ingredient.lowStockThreshold}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        ingredient.status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _ingredientStatusColor(ingredient.status),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniActionButton(
                              label: 'Sửa',
                              onTap:
                                  !state.canManageInventory || state.isUpdating
                                      ? null
                                      : () => context.goNamed(
                                            AppRouteNames.adminIngredientForm,
                                            queryParameters: {
                                              'id': ingredient.id,
                                              'sidebar': '4',
                                            },
                                          ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniActionButton(
                              label: '-1',
                              onTap: !state.canManageInventory ||
                                      state.isUpdating ||
                                      ingredient.availableQuantity <= 0
                                  ? null
                                  : () => state.consumeIngredient(ingredient,
                                      quantity: 1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniActionButton(
                              label: state.isUpdating ? 'Đang cập nhật' : '+5',
                              onTap: !state.canManageInventory ||
                                      state.isUpdating
                                  ? null
                                  : () => state.restockIngredient(ingredient,
                                      quantity: 5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _MiniActionButton(
                              label: 'Xóa',
                              onTap: !state.canManageInventory ||
                                      state.isUpdating
                                  ? null
                                  : () => _confirmDangerAction(
                                        context,
                                        message:
                                            'Xóa nguyên liệu "${ingredient.name}"?',
                                        onConfirm: () =>
                                            state.deleteIngredient(ingredient),
                                      ),
                              backgroundColor: AdminColors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          if (state.inventoryTransactions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...state.inventoryTransactions.take(6).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _InventoryTransactionTile(transaction: item),
                )),
          ],
        ],
      ),
    );
  }

  Future<void> _exportIngredients(BuildContext context) async {
    try {
      final rows =
          await AppServices.instance.adminRepository.fetchIngredientExcelRows();
      await AdminExcelCore.exportIngredients(rows);
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Đã xuất file Excel nguyên liệu.');
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể xuất file Excel nguyên liệu.',
          isError: true);
    }
  }

  Future<void> _importIngredients(BuildContext context) async {
    try {
      final rows = await AdminExcelCore.importIngredients();
      if (rows == null) {
        return;
      }
      if (rows.isEmpty) {
        if (!context.mounted) {
          return;
        }
        _showAdminSnackBar(
            context, 'File Excel không có dữ liệu nguyên liệu hợp lệ.',
            isError: true);
        return;
      }
      final result = await AppServices.instance.adminRepository
          .importIngredientExcelRows(rows);
      await state.refreshIngredientsSection();
      if (!context.mounted) {
        return;
      }
      await _showImportResultDialog(context, 'nguyên liệu', result);
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      _showAdminSnackBar(context, 'Không thể import nguyên liệu từ file Excel.',
          isError: true);
    }
  }
}

class _MobileAdminRecipesSection extends StatelessWidget {
  const _MobileAdminRecipesSection({required this.state});

  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý công thức',
      action: _MiniActionButton(
        label: 'Tạo',
        onTap: state.canManageRecipes
            ? () => context.goNamed(
                  AppRouteNames.adminRecipeForm,
                  queryParameters: const {'sidebar': '5'},
                )
            : null,
      ),
      child: state.recipes.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có công thức nào.')
          : Column(
              children: state.recipes.map((recipe) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(recipe.productTitle,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AdminColors.textDark)),
                        const SizedBox(height: 4),
                        Text(_recipeYieldLabel(recipe),
                            style: const TextStyle(
                                fontSize: 12,
                                color: AdminColors.textSoft,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                            'Cost theo mẻ: ${_formatCurrency(recipe.totalCost)}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AdminColors.green,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                            'Cost / ${recipe.yieldUnit}: ${_formatCurrency(recipe.costPerUnit)}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AdminColors.blue,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          recipe.recipeType == 'semi_finished'
                              ? 'Loại: Bán thành phẩm'
                              : 'Loại: Thành phẩm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: recipe.recipeType == 'semi_finished'
                                ? AdminColors.orange
                                : AdminColors.blue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lợi nhuận gộp: ${_formatCurrency(recipe.grossProfitEstimate)} • ${recipe.grossMarginPercent.toStringAsFixed(1)}%',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AdminColors.green,
                              fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        ...recipe.ingredients.map((ingredient) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${ingredient.ingredientName}: ${ingredient.quantity} ${ingredient.unit} / mẻ • hao hụt ${ingredient.wastePercent}%'
                                '${ingredient.sourceType == 'recipe' ? ' • bán thành phẩm' : ''}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            )),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _MiniActionButton(
                                label: 'Sửa',
                                onTap: state.canManageRecipes
                                    ? () => context.goNamed(
                                          AppRouteNames.adminRecipeForm,
                                          queryParameters: {
                                            'id': recipe.id,
                                            'sidebar': '5'
                                          },
                                        )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniActionButton(
                                label: 'Copy',
                                onTap: state.canManageRecipes
                                    ? () => _openCopyRecipeDialog(
                                        context, state, recipe)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MiniActionButton(
                                label: 'Xóa',
                                onTap: state.isUpdating
                                    ? null
                                    : () => _confirmDangerAction(
                                          context,
                                          message:
                                              'Xóa công thức của "${recipe.productTitle}"?',
                                          onConfirm: () =>
                                              state.deleteRecipe(recipe),
                                        ),
                                backgroundColor: AdminColors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }
}

String _recipeYieldLabel(AdminRecipeModel recipe) {
  return '1 mẻ tạo ra ${recipe.yieldQuantity} ${recipe.yieldUnit}';
}

class _MobileList extends StatelessWidget {
  const _MobileList({required this.orders});

  final List<AdminRecentOrderModel> orders;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 238,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AdminColors.line, width: 1),
      ),
      child: Column(
        children: orders.isEmpty
            ? const [
                Text('Chưa có đơn hàng nào.',
                    style:
                        TextStyle(color: AdminColors.textSoft, fontSize: 12)),
              ]
            : List.generate(orders.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const SizedBox(height: 8);
                }
                final order = orders[index ~/ 2];
                return _Row(
                  '#${order.orderId}',
                  _formatCurrency(order.total),
                  order.status,
                  _statusColor(order.status),
                );
              }),
      ),
    );
  }
}

void _showAdminSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? AdminColors.red : AdminColors.blue,
      content: Text(message),
    ),
  );
}

class _Row extends StatelessWidget {
  final String code;
  final String price;
  final String status;
  final Color statusColor;
  const _Row(this.code, this.price, this.status, this.statusColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(code,
              style: const TextStyle(
                  color: AdminColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(price,
              style: const TextStyle(
                  color: AdminColors.textDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MobileBars extends StatelessWidget {
  const _MobileBars({required this.values});

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(3, (index) {
          final source = values.isEmpty
              ? [0, 0, 0]
              : values.take(3).toList(growable: false);
          final maxValue =
              source.fold<int>(0, (max, item) => item > max ? item : max);
          final resolvedHeight =
              maxValue == 0 ? 24.0 : 24 + (source[index] / maxValue) * 20;
          final colors = [
            const Color(0xFF93C5FD),
            const Color(0xFF3B82F6),
            AdminColors.red
          ];
          return Container(
              width: 72,
              height: resolvedHeight,
              decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(4)));
        }),
      ),
    );
  }
}

class _InventoryTransactionTile extends StatelessWidget {
  const _InventoryTransactionTile({required this.transaction});

  final AdminInventoryTransactionModel transaction;

  @override
  Widget build(BuildContext context) {
    final isOut = transaction.normalizedQuantityDelta < 0;
    final color = isOut ? AdminColors.red : AdminColors.green;
    final quantityLabel =
        '${isOut ? '' : '+'}${transaction.quantityDelta} ${transaction.unit}';
    final normalizedLabel =
        '${isOut ? '' : '+'}${transaction.normalizedQuantityDelta} ${transaction.normalizedUnit}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(borderWidth: 1, radius: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.ingredientName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${transaction.transactionType} • $quantityLabel • $normalizedLabel',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tồn sau giao dịch: ${transaction.balanceQuantity} ${transaction.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textSoft,
                  ),
                ),
                if ((transaction.referenceId ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tham chiếu: ${transaction.referenceType ?? '-'} • ${transaction.referenceId}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AdminColors.textSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCostReportTile extends StatelessWidget {
  const _ProductCostReportTile({required this.report});

  final AdminProductCostReportModel report;

  @override
  Widget build(BuildContext context) {
    final hasRecipe = report.recipeType != 'unmapped';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(borderWidth: 1, radius: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.productTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasRecipe
                      ? 'Cost ${_formatCurrency(report.estimatedCost)} • Lãi gộp ${_formatCurrency(report.grossProfit)}'
                      : 'Chưa map cost theo công thức',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        hasRecipe ? AdminColors.textSoft : AdminColors.orange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            hasRecipe
                ? '${report.grossMarginPercent.toStringAsFixed(1)}%'
                : '--',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: hasRecipe ? AdminColors.green : AdminColors.orange,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reviews Management ───────────────────────────────────────────────────────

class _ReviewsManagementSection extends StatelessWidget {
  const _ReviewsManagementSection({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Quản lý Reviews',
      child: state.reviews.isEmpty
          ? const _EmptyAdminState(message: 'Chưa có review nào.')
          : Column(
              children: state.reviews.map((review) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ReviewTile(
                    review: review,
                    onDelete: state.isUpdating
                        ? null
                        : () => _confirmDelete(context, state, review),
                  ),
                );
              }).toList(growable: false),
            ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    AdminState state,
    AdminProductReviewModel review,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa review?'),
        content: Text(
          'Review của "${review.author}" cho "${review.productTitle}" sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              state.deleteReview(review.productId, review.createdAt);
            },
            child: const Text('Xóa', style: TextStyle(color: AdminColors.red)),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review, this.onDelete});
  final AdminProductReviewModel review;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final stars =
        '★' * review.rating.clamp(1, 5) + '☆' * (5 - review.rating.clamp(1, 5));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(borderWidth: 1, radius: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        review.productTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AdminColors.blue,
                        ),
                      ),
                    ),
                    Text(
                      stars,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AdminColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${review.author} • ${_shortDate(review.createdAt)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AdminColors.textSoft,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  review.content,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textDark,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniActionButton(
            label: 'Xóa',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }

  String _shortDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }
}

class _ImportAuditLogTile extends StatelessWidget {
  const _ImportAuditLogTile({required this.log});

  final AdminImportAuditLogModel log;

  @override
  Widget build(BuildContext context) {
    final toneColor = switch (log.status) {
      'success' => AdminColors.green,
      'partial' => AdminColors.orange,
      _ => AdminColors.red,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(borderWidth: 1, radius: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Import ${log.entityType}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AdminColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tạo ${log.createdCount} • Cập nhật ${log.updatedCount} • Lỗi ${log.errorCount}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AdminColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
          Text(
            log.status,
            style: TextStyle(
              color: toneColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.tone});

  final String message;
  final String tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _toneBackground(tone),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _toneTitleColor(tone), width: 1),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: _toneTitleColor(tone),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Smart Analytics ──────────────────────────────────────────────────────────

class _SmartAnalyticsSection extends StatelessWidget {
  const _SmartAnalyticsSection({required this.state});
  final AdminState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          title: 'Top sản phẩm bán chạy',
          child: _BestSellersList(items: state.bestSellers),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Phân loại khách hàng',
          child: _CustomerSegmentsSummary(items: state.customerSegments),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Dự báo doanh thu',
          child: _RevenueForecastSummary(forecast: state.revenueForecast),
        ),
      ],
    );
  }
}

class _BestSellersList extends StatelessWidget {
  const _BestSellersList({required this.items});
  final List<AdminBestSellerModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Chưa có dữ liệu bán hàng.',
            style: TextStyle(color: AdminColors.textSoft)),
      );
    }
    final maxSold = items.fold(0, (m, i) => i.totalSold > m ? i.totalSold : m);
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final barFraction = maxSold > 0 ? item.totalSold / maxSold : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: index == 0
                        ? AdminColors.orange
                        : index == 1
                            ? AdminColors.blue
                            : AdminColors.textSoft,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barFraction.toDouble(),
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AdminColors.green),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.totalSold} cái',
                style:
                    const TextStyle(fontSize: 11, color: AdminColors.textSoft),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: Text(
                  _formatCurrency(item.revenue),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AdminColors.green),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _CustomerSegmentsSummary extends StatelessWidget {
  const _CustomerSegmentsSummary({required this.items});
  final List<AdminCustomerSegmentModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Chưa có dữ liệu khách hàng.',
            style: TextStyle(color: AdminColors.textSoft)),
      );
    }
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.segment] = (counts[item.segment] ?? 0) + 1;
    }
    final segmentOrder = ['VIP', 'Thường xuyên', 'Mới', 'Tiềm năng'];
    final segmentColors = {
      'VIP': AdminColors.orange,
      'Thường xuyên': AdminColors.blue,
      'Mới': AdminColors.green,
      'Tiềm năng': AdminColors.gray,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: segmentOrder.where((s) => counts.containsKey(s)).map((seg) {
            final color = segmentColors[seg] ?? AdminColors.gray;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color, width: 1),
              ),
              child: Text(
                '${counts[seg]} $seg',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color),
              ),
            );
          }).toList(growable: false),
        ),
        const SizedBox(height: 12),
        Text(
          'Tổng: ${items.length} khách hàng',
          style: const TextStyle(fontSize: 11, color: AdminColors.textSoft),
        ),
      ],
    );
  }
}

class _RevenueForecastSummary extends StatelessWidget {
  const _RevenueForecastSummary({required this.forecast});
  final AdminRevenueForecastModel forecast;

  @override
  Widget build(BuildContext context) {
    if (forecast.forecast.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Chưa có dữ liệu dự báo.',
            style: TextStyle(color: AdminColors.textSoft)),
      );
    }
    final trendIcon = forecast.trend == 'up'
        ? '↑'
        : forecast.trend == 'down'
            ? '↓'
            : '→';
    final trendColor = forecast.trend == 'up'
        ? AdminColors.green
        : forecast.trend == 'down'
            ? AdminColors.red
            : AdminColors.gray;
    final totalForecast = forecast.totalForecastRevenue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Xu hướng: ',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              '$trendIcon ${forecast.trend == 'up' ? 'Tăng' : forecast.trend == 'down' ? 'Giảm' : 'Ổn định'}',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w800, color: trendColor),
            ),
            const SizedBox(width: 12),
            Text(
              '(${forecast.dailyGrowth > 0 ? '+' : ''}${forecast.dailyGrowth.toStringAsFixed(1)}%/ngày)',
              style: TextStyle(fontSize: 11, color: trendColor),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Dự báo 7 ngày tới: ',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            Text(
              _formatCurrency(totalForecast),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AdminColors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...forecast.forecast.map((day) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(
                    day.date,
                    style: const TextStyle(
                        fontSize: 11, color: AdminColors.textSoft),
                  ),
                ),
                Text(
                  _formatCurrency(day.predicted),
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// ─── Admin Loading Skeleton ───────────────────────────────────────────────────

class _AdminLoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Stat cards row
        SizedBox(
          height: 80,
          child: Row(
            children: List.generate(
                4,
                (i) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: i < 3 ? 10 : 0),
                        child: _skelBox(80),
                      ),
                    )),
          ),
        ),
        const SizedBox(height: 12),
        // Main content area
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 5, child: _skelBox(300)),
            const SizedBox(width: 12),
            Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _skelBox(140),
                    const SizedBox(height: 12),
                    _skelBox(140),
                  ],
                )),
          ],
        ),
        const SizedBox(height: 12),
        _skelBox(120),
      ],
    );
  }

  Widget _skelBox(double height) => _ShimmerAdmin(
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AdminColors.gray.withOpacity(0.3), width: 1.5),
          ),
        ),
      );
}

class _ShimmerAdmin extends StatefulWidget {
  const _ShimmerAdmin({required this.child});
  final Widget child;
  @override
  State<_ShimmerAdmin> createState() => _ShimmerAdminState();
}

class _ShimmerAdminState extends State<_ShimmerAdmin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end: Alignment(_anim.value + 1, 0),
          colors: const [
            Color(0xFFF0F0F0),
            Color(0xFFE0E0E0),
            Color(0xFFF0F0F0)
          ],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

BoxDecoration _box({double borderWidth = 2, double radius = 10}) =>
    BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AdminColors.gray, width: borderWidth),
    );

String _formatCurrency(int amount) =>
    '${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')}đ';

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('mới')) return const Color(0xFF2563EB);
  if (normalized.contains('xử lý')) return AdminColors.orange;
  if (normalized.contains('giao') || normalized.contains('hoàn tất'))
    return const Color(0xFF059669);
  if (normalized.contains('huỷ') || normalized.contains('lỗi'))
    return AdminColors.red;
  return AdminColors.gray;
}

Color _ingredientStatusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('đủ')) return AdminColors.green;
  if (normalized.contains('sắp')) return AdminColors.orange;
  if (normalized.contains('hết')) return AdminColors.red;
  return AdminColors.gray;
}

Color _toneColor(String tone) {
  switch (tone) {
    case 'success':
      return const Color(0xFF059669);
    case 'danger':
      return const Color(0xFFDC2626);
    default:
      return AdminColors.textDark;
  }
}

Color _toneBackground(String tone) {
  switch (tone) {
    case 'danger':
      return const Color(0xFFFFF1F1);
    case 'warning':
      return const Color(0xFFFFF8E8);
    default:
      return const Color(0xFFF0F9FF);
  }
}

Color _toneTitleColor(String tone) {
  switch (tone) {
    case 'danger':
      return const Color(0xFFB91C1C);
    case 'warning':
      return const Color(0xFF92400E);
    default:
      return const Color(0xFF1D4ED8);
  }
}

Color _toneDescColor(String tone) {
  switch (tone) {
    case 'danger':
      return const Color(0xFFDC2626);
    case 'warning':
      return const Color(0xFFD97706);
    default:
      return const Color(0xFF2563EB);
  }
}

Future<void> _showCategoryDialog(
  BuildContext context,
  AdminState state, {
  AdminCategoryModel? category,
}) async {
  final labelController = TextEditingController(text: category?.label ?? '');
  final categoryController =
      TextEditingController(text: category?.category ?? '');
  final imageUrlController =
      TextEditingController(text: category?.imageUrl ?? '');
  final sortOrderController = TextEditingController(
      text: '${category?.sortOrder ?? state.categories.length}');
  final isEdit = category != null;

  final draft = await showDialog<AdminCategoryDraft>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(isEdit ? 'Sửa danh mục' : 'Thêm danh mục'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Tên hiển thị'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(labelText: 'Giá trị danh mục'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: imageUrlController,
              decoration: const InputDecoration(labelText: 'URL hình ảnh'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: sortOrderController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Thứ tự'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            final label = labelController.text.trim();
            final value = categoryController.text.trim();
            if (label.isEmpty || value.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              AdminCategoryDraft(
                label: label,
                category: value,
                imageUrl: imageUrlController.text.trim().isEmpty
                    ? null
                    : imageUrlController.text.trim(),
                sortOrder: int.tryParse(sortOrderController.text.trim()) ?? 0,
              ),
            );
          },
          child: const Text('Lưu'),
        ),
      ],
    ),
  );

  labelController.dispose();
  categoryController.dispose();
  imageUrlController.dispose();
  sortOrderController.dispose();

  if (draft == null) {
    return;
  }
  if (isEdit) {
    await state.updateCategory(category.id, draft);
  } else {
    await state.createCategory(draft);
  }
}

Future<void> _confirmDangerAction(
  BuildContext context, {
  required String message,
  required Future<void> Function() onConfirm,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Xác nhận'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Xóa'),
        ),
      ],
    ),
  );
  if (confirmed == true) {
    await onConfirm();
  }
}

Future<void> _showImportResultDialog(
  BuildContext context,
  String entityLabel,
  AdminBulkImportResultModel result,
) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Kết quả import $entityLabel'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(result.message),
              const SizedBox(height: 8),
              Text(
                'Tạo mới: ${result.createdCount} • Cập nhật: ${result.updatedCount} • Lỗi: ${result.errorCount}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              if (result.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Chi tiết lỗi',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...result.errors.take(12).map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'Dòng ${item.rowNumber} • ${item.field}: ${item.message}${item.value == null || item.value!.isEmpty ? '' : ' (${item.value})'}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    ),
  );
}

Future<void> _openCopyRecipeDialog(
  BuildContext context,
  AdminState state,
  AdminRecipeModel recipe,
) async {
  final options =
      await AppServices.instance.adminRepository.fetchRecipeOptions();
  final candidates = options.products;
  if (!context.mounted) {
    return;
  }
  if (candidates.isEmpty) {
    _showAdminSnackBar(
      context,
      'Không còn sản phẩm đích để sao chép công thức.',
      isError: true,
    );
    return;
  }
  int selectedProductId = candidates.first.id;
  final confirmed = await showDialog<int>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        title: const Text('Sao chép công thức'),
        content: SizedBox(
          width: 520,
          child: DropdownButtonFormField<int>(
            value: selectedProductId,
            items: candidates.map((product) {
              return DropdownMenuItem<int>(
                value: product.id,
                child: Text('${product.title} • ${product.category}'),
              );
            }).toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setModalState(() => selectedProductId = value);
            },
            decoration: const InputDecoration(
              labelText: 'Chọn sản phẩm đích',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(selectedProductId),
            child: const Text('Sao chép'),
          ),
        ],
      ),
    ),
  );
  if (confirmed == null) {
    return;
  }
  await state.copyRecipe(recipe, confirmed);
  if (!context.mounted) {
    return;
  }
  _showAdminSnackBar(context, 'Đã sao chép công thức.');
}

Future<void> _openVoucherDialog(
  BuildContext context,
  AdminState state, {
  AdminVoucherDraft? initial,
}) async {
  final codeController = TextEditingController(text: initial?.code ?? '');
  final titleController = TextEditingController(text: initial?.title ?? '');
  final noteController = TextEditingController(text: initial?.note ?? '');
  final valueController =
      TextEditingController(text: '${initial?.discountValue ?? 0}');
  final minOrderController =
      TextEditingController(text: '${initial?.minOrderValue ?? 0}');
  var accent = initial?.accent ?? 'red';
  var discountType = initial?.discountType ?? 'percent';
  final submitted = await showDialog<AdminVoucherDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        title: Text(initial == null ? 'Thêm voucher' : 'Sửa voucher'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Mã voucher')),
                TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Tiêu đề')),
                TextField(
                    controller: noteController,
                    decoration: const InputDecoration(labelText: 'Ghi chú')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: accent,
                  items: const [
                    DropdownMenuItem(value: 'red', child: Text('Red')),
                    DropdownMenuItem(value: 'blue', child: Text('Blue')),
                    DropdownMenuItem(value: 'green', child: Text('Green')),
                    DropdownMenuItem(value: 'orange', child: Text('Orange')),
                  ],
                  onChanged: (value) =>
                      setModalState(() => accent = value ?? 'red'),
                  decoration: const InputDecoration(labelText: 'Accent'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: discountType,
                  items: const [
                    DropdownMenuItem(value: 'percent', child: Text('Percent')),
                    DropdownMenuItem(
                        value: 'shipping', child: Text('Shipping')),
                  ],
                  onChanged: (value) =>
                      setModalState(() => discountType = value ?? 'percent'),
                  decoration: const InputDecoration(labelText: 'Loại giảm giá'),
                ),
                TextField(
                  controller: valueController,
                  decoration: const InputDecoration(labelText: 'Giá trị giảm'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: minOrderController,
                  decoration: const InputDecoration(labelText: 'Đơn tối thiểu'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(
                AdminVoucherDraft(
                  code: codeController.text.trim().toUpperCase(),
                  title: titleController.text.trim(),
                  note: noteController.text.trim(),
                  accent: accent,
                  discountType: discountType,
                  discountValue: int.tryParse(valueController.text.trim()) ?? 0,
                  minOrderValue:
                      int.tryParse(minOrderController.text.trim()) ?? 0,
                ),
              );
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    ),
  );
  if (submitted == null) return;
  if (initial == null) {
    await state.createVoucher(submitted);
  } else {
    await state.updateVoucher(initial.code, submitted);
  }
}

Future<void> _openContentDialog(
  BuildContext context,
  AdminState state,
  AdminContentDocumentModel content,
) async {
  final controller = TextEditingController(text: content.jsonContent);
  final submitted = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Chỉnh sửa ${content.title}'),
      content: SizedBox(
        width: 720,
        child: TextField(
          controller: controller,
          maxLines: 24,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Nhập JSON content',
          ),
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  if (submitted == null) return;
  await state.updateContent(content.key, submitted);
}

Future<void> _handleAdvanceOrderStatus(
  BuildContext context,
  AdminState state,
  AdminOrderModel order,
) async {
  try {
    final check = await state.getOrderAdvanceCheck(order);
    if (!context.mounted) return;
    if (!check.canAdvance) {
      _showAdminSnackBar(context, check.message, isError: true);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Chuyển sang ${check.nextStatus}?'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đơn #${check.orderId}: ${check.message}',
                  style: TextStyle(
                    fontSize: 13,
                    color: check.shortages.isEmpty
                        ? AdminColors.textDark
                        : AdminColors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (check.shortages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Thiếu nguyên liệu:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AdminColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...check.shortages.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• ${item.ingredientName}: cần ${item.requiredQuantity} ${item.unit}, hiện có ${item.availableQuantity} ${item.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AdminColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(check.shortages.isEmpty ? 'Xác nhận' : 'Vẫn tiếp tục'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await state.advanceOrderStatus(order);
    }
  } catch (_) {
    if (!context.mounted) return;
    _showAdminSnackBar(
      context,
      'Không thể kiểm tra tồn kho trước khi xử lý đơn.',
      isError: true,
    );
  }
}

Future<void> _openStructuredContentDialog(
  BuildContext context,
  AdminState state,
  AdminContentDocumentModel content,
) async {
  final raw = jsonDecode(content.jsonContent);
  if (raw is! Map<String, dynamic>) {
    await _openContentDialog(context, state, content);
    return;
  }

  try {
    switch (content.key) {
      case 'home':
        await _openHomeContentFormDialog(context, state, content, raw);
        return;
      case 'story':
        await _openStoryContentFormDialog(context, state, content, raw);
        return;
      case 'contact':
        await _openContactContentFormDialog(context, state, content, raw);
        return;
      case 'login':
      case 'register':
        await _openAuthContentFormDialog(context, state, content, raw);
        return;
      default:
        await _openContentDialog(context, state, content);
        return;
    }
  } catch (_) {
    await _openContentDialog(context, state, content);
  }
}

Future<void> _openHomeContentFormDialog(
  BuildContext context,
  AdminState state,
  AdminContentDocumentModel content,
  Map<String, dynamic> raw,
) async {
  final page = HomePageResponse.fromJson(raw);
  final heroTitleController = TextEditingController(text: page.hero.title);
  final heroDescriptionController =
      TextEditingController(text: page.hero.description);
  final primaryActionController =
      TextEditingController(text: page.hero.primaryAction.label);
  final secondaryActionController =
      TextEditingController(text: page.hero.secondaryAction.label);
  final storyTitleController = TextEditingController(text: page.story.title);
  final storyDescriptionController =
      TextEditingController(text: page.story.description);
  final storyBadgeController =
      TextEditingController(text: page.story.badgeText);
  final promoMessageController =
      TextEditingController(text: page.promo.message);
  final promoActionController =
      TextEditingController(text: page.promo.action.label);
  final footerTaglineController =
      TextEditingController(text: page.footer.tagline);

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Chỉnh sửa ${content.title}'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContentFormField(
                  label: 'Hero title', controller: heroTitleController),
              _ContentFormField(
                label: 'Hero description',
                controller: heroDescriptionController,
                maxLines: 3,
              ),
              _ContentFormField(
                label: 'Nút chính',
                controller: primaryActionController,
              ),
              _ContentFormField(
                label: 'Nút phụ',
                controller: secondaryActionController,
              ),
              _ContentFormField(
                label: 'Story title',
                controller: storyTitleController,
              ),
              _ContentFormField(
                label: 'Story description',
                controller: storyDescriptionController,
                maxLines: 3,
              ),
              _ContentFormField(
                label: 'Story badge',
                controller: storyBadgeController,
              ),
              _ContentFormField(
                label: 'Promo message',
                controller: promoMessageController,
                maxLines: 2,
              ),
              _ContentFormField(
                label: 'Promo action label',
                controller: promoActionController,
              ),
              _ContentFormField(
                label: 'Footer tagline',
                controller: footerTaglineController,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  if (shouldSave != true) return;

  final updated = HomePageResponse(
    hero: HomeHeroSection(
      title: heroTitleController.text.trim(),
      description: heroDescriptionController.text.trim(),
      primaryAction: HomeActionLink(
        label: primaryActionController.text.trim(),
        routeName: page.hero.primaryAction.routeName,
        routePath: page.hero.primaryAction.routePath,
        queryParameters: page.hero.primaryAction.queryParameters,
      ),
      secondaryAction: HomeActionLink(
        label: secondaryActionController.text.trim(),
        routeName: page.hero.secondaryAction.routeName,
        routePath: page.hero.secondaryAction.routePath,
        queryParameters: page.hero.secondaryAction.queryParameters,
      ),
    ),
    highlights: page.highlights,
    featuredProducts: page.featuredProducts,
    story: HomeStorySection(
      title: storyTitleController.text.trim(),
      description: storyDescriptionController.text.trim(),
      badgeText: storyBadgeController.text.trim(),
    ),
    categories: page.categories,
    testimonials: page.testimonials,
    faqs: page.faqs,
    promo: HomePromoBanner(
      message: promoMessageController.text.trim(),
      action: HomeActionLink(
        label: promoActionController.text.trim(),
        routeName: page.promo.action.routeName,
        routePath: page.promo.action.routePath,
        queryParameters: page.promo.action.queryParameters,
      ),
    ),
    footer: HomeFooterSection(
      tagline: footerTaglineController.text.trim(),
      links: page.footer.links,
    ),
  );

  await state.updateContent(
    content.key,
    const JsonEncoder.withIndent('  ').convert(updated.toJson()),
  );
}

Future<void> _openStoryContentFormDialog(
  BuildContext context,
  AdminState state,
  AdminContentDocumentModel content,
  Map<String, dynamic> raw,
) async {
  final page = StoryPageResponse.fromJson(raw);
  final headerTitleController = TextEditingController(text: page.headerTitle);
  final heroTitleController = TextEditingController(text: page.heroTitle);
  final heroDescriptionController =
      TextEditingController(text: page.heroDescription);
  final heroBadgeController = TextEditingController(text: page.heroBadge);
  final timelineTitleController =
      TextEditingController(text: page.timelineTitle);
  final imageTimelineTitleController =
      TextEditingController(text: page.imageTimelineTitle);
  final valuesTitleController = TextEditingController(text: page.values.title);
  final craftTitleController = TextEditingController(text: page.craft.title);
  final craftDescriptionController =
      TextEditingController(text: page.craft.description);
  final ctaDescriptionController =
      TextEditingController(text: page.cta.description);
  final ctaButtonController = TextEditingController(text: page.cta.buttonLabel);
  final footerLabelController = TextEditingController(text: page.footerLabel);

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Chỉnh sửa ${content.title}'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContentFormField(
                  label: 'Header title', controller: headerTitleController),
              _ContentFormField(
                  label: 'Hero title', controller: heroTitleController),
              _ContentFormField(
                label: 'Hero description',
                controller: heroDescriptionController,
                maxLines: 3,
              ),
              _ContentFormField(
                  label: 'Hero badge', controller: heroBadgeController),
              _ContentFormField(
                label: 'Timeline title',
                controller: timelineTitleController,
              ),
              _ContentFormField(
                label: 'Image timeline title',
                controller: imageTimelineTitleController,
              ),
              _ContentFormField(
                label: 'Values title',
                controller: valuesTitleController,
              ),
              _ContentFormField(
                  label: 'Craft title', controller: craftTitleController),
              _ContentFormField(
                label: 'Craft description',
                controller: craftDescriptionController,
                maxLines: 3,
              ),
              _ContentFormField(
                label: 'CTA description',
                controller: ctaDescriptionController,
                maxLines: 3,
              ),
              _ContentFormField(
                label: 'CTA button',
                controller: ctaButtonController,
              ),
              _ContentFormField(
                label: 'Footer label',
                controller: footerLabelController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  if (shouldSave != true) return;

  final updated = StoryPageResponse(
    headerTitle: headerTitleController.text.trim(),
    heroTitle: heroTitleController.text.trim(),
    heroDescription: heroDescriptionController.text.trim(),
    heroBadge: heroBadgeController.text.trim(),
    timelineTitle: timelineTitleController.text.trim(),
    timelineItems: page.timelineItems,
    imageTimelineTitle: imageTimelineTitleController.text.trim(),
    imageTimelineItems: page.imageTimelineItems,
    values: StorySectionModel(
      title: valuesTitleController.text.trim(),
      items: page.values.items,
    ),
    craft: StoryCraftSectionModel(
      title: craftTitleController.text.trim(),
      description: craftDescriptionController.text.trim(),
      previewLabel: page.craft.previewLabel,
    ),
    cta: StoryCtaSectionModel(
      description: ctaDescriptionController.text.trim(),
      buttonLabel: ctaButtonController.text.trim(),
    ),
    footerLabel: footerLabelController.text.trim(),
  );

  await state.updateContent(
    content.key,
    const JsonEncoder.withIndent('  ').convert(updated.toJson()),
  );
}

Future<void> _openContactContentFormDialog(
  BuildContext context,
  AdminState state,
  AdminContentDocumentModel content,
  Map<String, dynamic> raw,
) async {
  final page = ContactPageResponse.fromJson(raw);
  final heroTitleController = TextEditingController(text: page.heroTitle);
  final heroDescriptionController =
      TextEditingController(text: page.heroDescription);
  final formTitleController = TextEditingController(text: page.formTitle);
  final submitLabelController = TextEditingController(text: page.submitLabel);
  final mobileTitleController = TextEditingController(text: page.mobileTitle);
  final mobileBadgeController = TextEditingController(text: page.mobileBadge);

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Chỉnh sửa ${content.title}'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContentFormField(
                  label: 'Hero title', controller: heroTitleController),
              _ContentFormField(
                label: 'Hero description',
                controller: heroDescriptionController,
                maxLines: 3,
              ),
              _ContentFormField(
                  label: 'Form title', controller: formTitleController),
              _ContentFormField(
                label: 'Submit label',
                controller: submitLabelController,
              ),
              _ContentFormField(
                label: 'Mobile title',
                controller: mobileTitleController,
              ),
              _ContentFormField(
                label: 'Mobile badge',
                controller: mobileBadgeController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  if (shouldSave != true) return;

  final updated = ContactPageResponse(
    heroTitle: heroTitleController.text.trim(),
    heroDescription: heroDescriptionController.text.trim(),
    formTitle: formTitleController.text.trim(),
    submitLabel: submitLabelController.text.trim(),
    mobileTitle: mobileTitleController.text.trim(),
    mobileBadge: mobileBadgeController.text.trim(),
    fields: page.fields,
    infoCards: page.infoCards,
    bottomNavLabels: page.bottomNavLabels,
  );

  await state.updateContent(
    content.key,
    const JsonEncoder.withIndent('  ').convert(updated.toJson()),
  );
}

Future<void> _openAuthContentFormDialog(
  BuildContext context,
  AdminState state,
  AdminContentDocumentModel content,
  Map<String, dynamic> raw,
) async {
  final page = AuthPageResponse.fromJson(raw);
  final headerBrandController = TextEditingController(text: page.headerBrand);
  final headerTitleController = TextEditingController(text: page.headerTitle);
  final introTitleController = TextEditingController(text: page.introTitle);
  final introDescriptionController =
      TextEditingController(text: page.introDescription);
  final helpTextController = TextEditingController(text: page.helpText ?? '');
  final primaryActionController =
      TextEditingController(text: page.primaryActionLabel);
  final socialActionController =
      TextEditingController(text: page.socialActionLabel);
  final switchPromptController = TextEditingController(text: page.switchPrompt);
  final switchActionController =
      TextEditingController(text: page.switchActionLabel);
  final footerTaglineController =
      TextEditingController(text: page.footerTagline);

  final shouldSave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Chỉnh sửa ${content.title}'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ContentFormField(
                  label: 'Header brand', controller: headerBrandController),
              _ContentFormField(
                  label: 'Header title', controller: headerTitleController),
              _ContentFormField(
                  label: 'Intro title', controller: introTitleController),
              _ContentFormField(
                label: 'Intro description',
                controller: introDescriptionController,
                maxLines: 3,
              ),
              _ContentFormField(
                  label: 'Help text', controller: helpTextController),
              _ContentFormField(
                label: 'Primary action',
                controller: primaryActionController,
              ),
              _ContentFormField(
                label: 'Social action',
                controller: socialActionController,
              ),
              _ContentFormField(
                label: 'Switch prompt',
                controller: switchPromptController,
              ),
              _ContentFormField(
                label: 'Switch action',
                controller: switchActionController,
              ),
              _ContentFormField(
                label: 'Footer tagline',
                controller: footerTaglineController,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  if (shouldSave != true) return;

  final updated = AuthPageResponse(
    headerBrand: headerBrandController.text.trim(),
    headerTitle: headerTitleController.text.trim(),
    introTitle: introTitleController.text.trim(),
    introDescription: introDescriptionController.text.trim(),
    fields: page.fields,
    helpText: helpTextController.text.trim().isEmpty
        ? null
        : helpTextController.text.trim(),
    primaryActionLabel: primaryActionController.text.trim(),
    socialActionLabel: socialActionController.text.trim(),
    switchPrompt: switchPromptController.text.trim(),
    switchActionLabel: switchActionController.text.trim(),
    footerTagline: footerTaglineController.text.trim(),
  );

  await state.updateContent(
    content.key,
    const JsonEncoder.withIndent('  ').convert(updated.toJson()),
  );
}

class _ContentFormField extends StatelessWidget {
  const _ContentFormField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}
