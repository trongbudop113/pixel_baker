import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/models/cart_models.dart';
import '../../app/models/menu_models.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';
import '../../app/routing/app_router.dart';
import '../shared/app_header.dart';
import '../shared/back_to_top_button.dart';
import '../shared/pixel_footer.dart';
import '../shared/pressable.dart';
import '../shared/shimmer_box.dart';
import 'menu_state.dart';

class MenuColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
}

class ResponsiveMenuScreen extends StatefulWidget {
  const ResponsiveMenuScreen({super.key, this.showTopHeader = true});

  final bool showTopHeader;

  @override
  State<ResponsiveMenuScreen> createState() => _ResponsiveMenuScreenState();
}

class _ResponsiveMenuScreenState extends State<ResponsiveMenuScreen> {
  late final MenuState _menuState;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<List<int>> _compareIds = ValueNotifier(const []);
  String? _lastCategoryQuery;
  Timer? _searchDebounce;
  Timer? _autoRefreshTimer;

  static const _kDebounceDelay = Duration(milliseconds: 300);
  static const _kAutoRefreshInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _menuState = MenuState(
      repository: AppServices.instance.menuRepository,
      wishlistSession: AppServices.instance.wishlistSession,
    );
    _menuState.loadMenuPage();
    _autoRefreshTimer = Timer.periodic(_kAutoRefreshInterval, (_) {
      _menuState.forceRefresh();
    });
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_kDebounceDelay, () {
      _menuState.setSearchQuery(value);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final category = GoRouterState.of(context).uri.queryParameters['category'];
    if (category == _lastCategoryQuery) return;
    _lastCategoryQuery = category;
    _menuState.applyCategoryFocus(category);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _autoRefreshTimer?.cancel();
    _menuState.clearMooncakeBoxPurchase();
    _searchController.dispose();
    _scrollController.dispose();
    _compareIds.dispose();
    _menuState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isTablet = width >= 600 && width < 900;
        final isMobile = width < 600;
        if (isMobile || isTablet) {
          return MobileMenuLayout(
              state: _menuState,
              searchController: _searchController,
              scrollController: _scrollController,
              onSearchChanged: _onSearchChanged,
              isTablet: isTablet,
              showTopHeader: widget.showTopHeader,
              compareIds: _compareIds);
        }
        return WebMenuLayout(
            state: _menuState,
            searchController: _searchController,
            scrollController: _scrollController,
            onSearchChanged: _onSearchChanged,
            showTopHeader: widget.showTopHeader,
            compareIds: _compareIds);
      },
    );
  }
}

class WebMenuLayout extends StatelessWidget {
  final MenuState state;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final void Function(String) onSearchChanged;
  final bool showTopHeader;
  final ValueNotifier<List<int>> compareIds;
  const WebMenuLayout(
      {super.key,
      required this.state,
      required this.searchController,
      required this.scrollController,
      required this.onSearchChanged,
      required this.compareIds,
      this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1200,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: MenuColors.gray, width: 3),
        ),
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) => Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showTopHeader)
                    const PixelHeaderBar(
                        rightLabel: 'thực đơn',
                        showBack: true,
                        showBrand: false),
                  if (showTopHeader) const SizedBox(height: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _intro(),
                              const SizedBox(height: 10),
                              _searchAndSort(),
                              const SizedBox(height: 10),
                              _filters(),
                              const SizedBox(height: 10),
                              _sectionTitle(),
                              if (state.isMooncakeTabSelected) ...[
                                const SizedBox(height: 10),
                                _mooncakeBoxToolbar(context),
                              ],
                              const SizedBox(height: 8),
                              _recentlyViewed(context),
                              _menuGrid(),
                              const SizedBox(height: 10),
                              _combo(),
                              const SizedBox(height: 10),
                              _faq(),
                              const SizedBox(height: 12),
                              const PixelFooter(
                                  label: 'PIXEL BAKERY | THỰC ĐƠN'),
                            ],
                          ),
                        ),
                        BackToTopButton(scrollController: scrollController),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.isMooncakeBoxMode)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _MooncakeBoxOverlay(
                    state: state,
                    compact: false,
                    onRemove: state.removeMooncakeBoxItemAt,
                    onCancel: state.clearMooncakeBoxPurchase,
                    onSubmit: () {
                      final item = state.buildMooncakeBoxCartItem();
                      if (item == null) {
                        return;
                      }
                      AppServices.instance.cartSession.addCartItem(item);
                      state.clearMooncakeBoxPurchase();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm ${item.title} vào giỏ hàng'),
                        ),
                      );
                    },
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CompareBar(compareIds: compareIds),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _intro() => Container(
        child: ControllerSelector<MenuState, MenuIntroSection>(
          controller: state,
          selector: (controller) => controller.pageResponse.intro,
          builder: (context, intro, _) => Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: _boxDec(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _txt(intro.title, MenuColors.blue, 34, FontWeight.w900),
                const SizedBox(height: 3),
                _txt(intro.description, MenuColors.gray, 13, FontWeight.w500),
              ],
            ),
          ),
        ),
      );

  Widget _filters() => Builder(
      builder: (ctx) => Container(
            padding: const EdgeInsets.all(10),
            decoration: _boxDec(ctx),
            child: ControllerSelector<MenuState, MenuViewState>(
              controller: state,
              selector: (controller) => controller.state,
              builder: (context, menuState, _) => Row(
                children: List.generate(
                    menuState.pageResponse.filters.length * 2 - 1, (index) {
                  if (index.isOdd) {
                    return const SizedBox(width: 6);
                  }
                  final filter = menuState.pageResponse.filters[index ~/ 2];
                  final filterIndex = index ~/ 2;
                  // Count products in this filter category
                  final filterCat = filter.category;
                  final productCount = filterCat == null || filterCat == 'all'
                      ? state.products.length
                      : state.products
                          .where((p) =>
                              state.mapCategory(p.category) ==
                              state.mapCategory(filterCat))
                          .length;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectFilter(context, filterIndex, filter),
                      child: _FilterChip(
                        label: filter.label,
                        selected: menuState.selectedFilterIndex == filterIndex,
                        count: productCount,
                        imageUrl: filter.imageUrl,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ));

  Widget _searchAndSort() => ControllerSelector<MenuState, MenuViewState>(
        controller: state,
        selector: (controller) => controller.state,
        builder: (context, menuState, _) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor ??
                const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDCE4EF)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _AutocompleteSearch(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  products: state.products,
                  hintText: 'Tìm bánh, danh mục, hương vị...',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.end,
                  children: [
                    SizedBox(
                      width: 190,
                      child: DropdownButtonFormField<String>(
                        value: menuState.sortKey,
                        style: _storefrontDropdownTextStyle(),
                        items: const [
                          DropdownMenuItem(
                              value: 'featured', child: Text('Nổi bật')),
                          DropdownMenuItem(
                              value: 'rating_desc',
                              child: Text('Đánh giá cao')),
                          DropdownMenuItem(
                              value: 'price_asc', child: Text('Giá tăng dần')),
                          DropdownMenuItem(
                              value: 'price_desc', child: Text('Giá giảm dần')),
                        ],
                        onChanged: (value) {
                          if (value != null) state.setSortKey(value);
                        },
                        decoration:
                            _storefrontFieldDecoration(labelText: 'Sắp xếp'),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: DropdownButtonFormField<String>(
                        value: menuState.priceRangeKey,
                        style: _storefrontDropdownTextStyle(),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('Mọi mức giá')),
                          DropdownMenuItem(
                              value: 'under_100k', child: Text('Dưới 100k')),
                          DropdownMenuItem(
                              value: '100k_200k', child: Text('100k - 200k')),
                          DropdownMenuItem(
                              value: 'over_200k', child: Text('Trên 200k')),
                        ],
                        onChanged: (value) {
                          if (value != null) state.setPriceRangeKey(value);
                        },
                        decoration:
                            _storefrontFieldDecoration(labelText: 'Giá'),
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<double>(
                        value: menuState.minimumRating,
                        style: _storefrontDropdownTextStyle(),
                        items: const [
                          DropdownMenuItem(
                              value: 0, child: Text('Mọi đánh giá')),
                          DropdownMenuItem(value: 4, child: Text('Từ 4.0 sao')),
                          DropdownMenuItem(
                              value: 4.5, child: Text('Từ 4.5 sao')),
                        ],
                        onChanged: (value) {
                          if (value != null) state.setMinimumRating(value);
                        },
                        decoration:
                            _storefrontFieldDecoration(labelText: 'Đánh giá'),
                      ),
                    ),
                    _StorefrontActionButton(
                      label: 'Yêu thích',
                      isActive: menuState.favoritesOnly,
                      onTap: state.toggleFavoritesOnly,
                    ),
                    _StorefrontActionButton(
                      label: 'Xóa lọc',
                      onTap: () {
                        searchController.clear();
                        state.clearSearchFilters();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _recentlyViewed(BuildContext context) =>
      ValueListenableBuilder<List<int>>(
        valueListenable: AppServices.instance.recentlyViewedSession,
        builder: (context, ids, _) {
          if (ids.isEmpty) return const SizedBox.shrink();
          final products = ids
              .map((id) => state.products.where((p) => p.id == id).firstOrNull)
              .whereType<MenuProduct>()
              .take(5)
              .toList(growable: false);
          if (products.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history_rounded,
                        size: 14, color: MenuColors.blue),
                    const SizedBox(width: 4),
                    _txt(
                        'Đã xem gần đây', MenuColors.blue, 13, FontWeight.w800),
                  ],
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return GestureDetector(
                      onTap: () => context
                          .go('${AppRoutePaths.productDetail}?id=${p.id}'),
                      child: Container(
                        width: 88,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: MenuColors.gray, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: p.images.isEmpty
                                    ? Container(color: const Color(0xFFEAF3FF))
                                    : Image.network(p.images.first,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder: (_, __, ___) => Container(
                                            color: const Color(0xFFEAF3FF))),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(p.title,
                                style: const TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      );

  Widget _sectionTitle() => ControllerSelector<MenuState, String>(
        controller: state,
        selector: (controller) => controller.pageResponse.productsSectionTitle,
        builder: (context, title, _) =>
            _txt(title, MenuColors.blue, 20, FontWeight.w800),
      );

  Widget _mooncakeBoxToolbar(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDCC8F7), width: 1.5),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Mua theo hộp bánh trung thu: chọn hộp trước, sau đó bấm thêm vào giỏ ở từng bánh để nạp vào hộp.',
                style: TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => _showMooncakeBoxPicker(context),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8E44AD),
                minimumSize: const Size(150, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                state.isMooncakeBoxMode ? 'Đổi hộp' : 'Mua theo hộp',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );

  Widget _menuGrid() => AnimatedBuilder(
        animation: Listenable.merge(
            [state, AppServices.instance.wishlistSession, compareIds]),
        builder: (context, _) {
          final items = state.filteredProducts;
          final selectedIds = compareIds.value;
          if (state.isLoading && items.isEmpty) {
            return const _MenuGridSkeleton();
          }

          if (state.errorMessage != null && items.isEmpty) {
            return _MenuFeedback(
              message: 'Không tải được dữ liệu menu.',
              actionLabel: 'Tải lại',
              onTap: state.loadMenuPage,
            );
          }
          if (items.isEmpty) {
            return const _MenuEmptyState(
              message: 'Không tìm thấy sản phẩm phù hợp với bộ lọc hiện tại.',
            );
          }

          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += 3) {
            final rowItems = items.skip(i).take(3).toList();
            rows.add(
              Row(
                children: List.generate(rowItems.length * 2 - 1, (index) {
                  if (index.isOdd) return const SizedBox(width: 10);
                  final item = rowItems[index ~/ 2];
                  final isSelectedForCompare = selectedIds.contains(item.id);
                  return Expanded(
                    child: _MenuItemCard(
                      productId: item.id,
                      title: item.title,
                      price: item.price,
                      imageUrl: item.images.isEmpty ? null : item.images.first,
                      averageRating: item.averageRating,
                      reviewCount: item.reviewCount,
                      tone: _toneFor(item),
                      accent: _accentFor(item),
                      isMooncake: item.mooncakeConfig != null,
                      isAddingToBox: state.isMooncakeBoxMode &&
                          item.mooncakeConfig != null,
                      isFavorite: AppServices.instance.wishlistSession
                          .contains(item.id),
                      isSelectedForCompare: isSelectedForCompare,
                      onTap: () => _openDetail(context, item),
                      onAddToCart: () => _addToCart(context, item),
                      onToggleFavorite: () =>
                          AppServices.instance.wishlistSession.toggle(item.id),
                      onToggleCompare: () => _toggleCompare(item.id),
                    ),
                  );
                }),
              ),
            );
            if (i + 3 < items.length) {
              rows.add(const SizedBox(height: 10));
            }
          }
          return Column(children: rows);
        },
      );

  void _toggleCompare(int productId) {
    final current = List<int>.from(compareIds.value);
    if (current.contains(productId)) {
      current.remove(productId);
    } else if (current.length < 3) {
      current.add(productId);
    }
    compareIds.value = List<int>.unmodifiable(current);
  }

  Widget _combo() => ControllerSelector<MenuState, MenuComboSection>(
        controller: state,
        selector: (controller) => controller.pageResponse.combo,
        builder: (context, combo, _) => Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: MenuColors.gray, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _txt(combo.title, MenuColors.blue, 24, FontWeight.w800),
              const SizedBox(height: 4),
              _txt(combo.description, MenuColors.gray, 12, FontWeight.w500),
              const SizedBox(height: 8),
              Container(
                width: 120,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MenuColors.red,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: MenuColors.gray, width: 2),
                ),
                child:
                    _txt(combo.actionLabel, Colors.white, 13, FontWeight.w800),
              ),
            ],
          ),
        ),
      );

  Widget _faq() => ControllerSelector<MenuState, List<MenuFaqItem>>(
        controller: state,
        selector: (controller) => controller.pageResponse.faqs,
        builder: (context, faqs, _) => Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: _boxDec(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _txt('FAQ nhanh', MenuColors.blue, 22, FontWeight.w800),
              const SizedBox(height: 4),
              ...faqs.map(
                (faq) => _txt(
                  '- ${faq.question} ${faq.answer}',
                  MenuColors.gray,
                  11,
                  FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _footer() => ControllerSelector<MenuState, String>(
        controller: state,
        selector: (controller) => controller.pageResponse.footer.tagline,
        builder: (context, tagline, _) => Container(
          height: 34,
          alignment: Alignment.center,
          decoration: _boxDec(context),
          child: _txt(tagline, MenuColors.gray, 9, FontWeight.w600),
        ),
      );

  BoxDecoration _boxDec([BuildContext? ctx]) {
    final bg = ctx != null ? Theme.of(ctx).cardColor : Colors.white;
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: MenuColors.gray, width: 2),
    );
  }

  Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      );

  Color _toneFor(MenuProduct item) {
    if (item.category == 'Cookie') return const Color(0xFFFFF1F1);
    if (item.category == 'Combo') return const Color(0xFFF1FAF1);
    return const Color(0xFFEAF3FF);
  }

  Color _accentFor(MenuProduct item) {
    if (item.category == 'Cookie') return MenuColors.red;
    if (item.category == 'Combo') return MenuColors.green;
    return MenuColors.blue;
  }

  void _openDetail(BuildContext context, MenuProduct item) {
    context.go('${AppRoutePaths.productDetail}?id=${item.id}');
  }

  void _selectFilter(
    BuildContext context,
    int filterIndex,
    MenuFilterOption filter,
  ) {
    state.selectFilter(filterIndex);
    final category = _routeCategoryFor(filter.category);
    if (category == null) {
      context.goNamed(AppRouteNames.menu);
      return;
    }
    context.goNamed(
      AppRouteNames.menu,
      queryParameters: {'category': category},
    );
  }

  void _addToCart(BuildContext context, MenuProduct item) {
    if (item.mooncakeConfig != null) {
      _handleMooncakeAction(context, item);
      return;
    }
    AppServices.instance.cartSession.addProduct(item);
    final cartCount = AppServices.instance.cartSession.itemCount;
    final combo = state.pageResponse.combo;
    // Gợi ý combo khi giỏ có ≥ 2 sản phẩm
    final showComboHint = cartCount >= 2 && combo.title.isNotEmpty;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: showComboHint
            ? Row(children: [
                Expanded(child: Text('Đã thêm ${item.title} vào giỏ 🛒')),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.go('${AppRoutePaths.menu}?category=combo');
                  },
                  child: const Text('Xem combo',
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.w800)),
                ),
              ])
            : Text('Đã thêm ${item.title} vào giỏ hàng'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _showMooncakeBoxPicker(BuildContext context) async {
    final boxOptions = state.mooncakeConfig?.boxOptions ?? const [];
    if (boxOptions.isEmpty) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn hộp bánh trung thu'),
        content: SizedBox(
          width: 720,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: boxOptions.map((box) {
              return GestureDetector(
                onTap: () {
                  state.startMooncakeBoxPurchase(box.code);
                  Navigator.of(dialogContext).pop();
                },
                child: Container(
                  width: 210,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDCC8F7),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          box.imageUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        box.label,
                        style: const TextStyle(
                          color: MenuColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${box.cakeCount} bánh • Phụ phí ${box.packagePrice}',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMooncakeAction(
      BuildContext context, MenuProduct item) async {
    final config = item.mooncakeConfig;
    if (config == null) {
      return;
    }
    final selection = await _showMooncakeVariantPicker(
      context,
      product: item,
      config: config,
    );
    if (selection == null) {
      return;
    }
    if (state.isMooncakeBoxMode) {
      final added = state.addMooncakeItemToBox(
        item,
        weight: selection.$1,
        egg: selection.$2,
      );
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Hộp đã đủ số lượng bánh. Hãy xóa bớt hoặc thêm vào giỏ.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${item.title} (${selection.$1.label} - ${selection.$2.label}) vào hộp.',
          ),
        ),
      );
      return;
    }
    final cartItem = CartItem(
      productId: item.id,
      title: item.title,
      price: selection.$2.price,
      priceValue: selection.$2.priceValue,
      category: item.category,
      imageUrl: item.images.isEmpty ? '' : item.images.first,
      quantity: 1,
      variantKey: 'single:${selection.$1.code}:${selection.$2.count}',
      variantLabel: '${selection.$1.label} • ${selection.$2.label}',
    );
    AppServices.instance.cartSession.addCartItem(cartItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Đã thêm ${item.title} (${cartItem.variantLabel}) vào giỏ hàng'),
      ),
    );
  }

  Future<(MooncakeWeightOption, MooncakeEggOption)?> _showMooncakeVariantPicker(
    BuildContext context, {
    required MenuProduct product,
    required MooncakeProductConfig config,
  }) async {
    var selectedWeight = config.weightOptions.first;
    var selectedEgg = selectedWeight.eggOptions.first;
    return showDialog<(MooncakeWeightOption, MooncakeEggOption)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chọn phiên bản ${product.title}'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khối lượng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: config.weightOptions.map((weight) {
                    final selected = selectedWeight.code == weight.code;
                    return ChoiceChip(
                      label: Text(weight.label),
                      selected: selected,
                      onSelected: (_) {
                        selectedWeight = weight;
                        selectedEgg = weight.eggOptions.first;
                        setDialogState(() {});
                      },
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Số trứng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedWeight.eggOptions.map((egg) {
                    final selected = selectedEgg.count == egg.count;
                    return ChoiceChip(
                      label: Text('${egg.label} • ${egg.price}'),
                      selected: selected,
                      onSelected: (_) {
                        selectedEgg = egg;
                        setDialogState(() {});
                      },
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop((selectedWeight, selectedEgg)),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  String? _routeCategoryFor(String category) {
    final normalized = category.trim().toLowerCase();
    if (normalized.isEmpty || normalized == 'all') {
      return null;
    }
    if (normalized.contains('trung thu') || normalized == 'mooncake') {
      return 'mooncake';
    }
    if (normalized.contains('bánh kem') || normalized == 'cake') {
      return 'cake';
    }
    if (normalized.contains('bánh pía') || normalized.contains('pia')) {
      return 'pia';
    }
    return normalized;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final int? count;
  final String? imageUrl;

  const _FilterChip({
    required this.label,
    this.selected = false,
    this.count,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEAF3FF) : const Color(0xFFFCFDFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? MenuColors.blue : const Color(0xFFD7DEE8),
          width: selected ? 1.8 : 1.2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if ((imageUrl ?? '').trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Image.network(
                imageUrl!.trim(),
                width: 22,
                height: 22,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            label,
            style: TextStyle(
              color: selected
                  ? MenuColors.blue
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (count != null)
            Text(
              '$count SP',
              style: TextStyle(
                color: selected
                    ? MenuColors.blue.withOpacity(0.7)
                    : const Color(0xFF8A8A8A),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

InputDecoration _storefrontFieldDecoration({
  String? hintText,
  String? labelText,
  Widget? prefixIcon,
}) {
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    prefixIcon: prefixIcon,
    filled: true,
    fillColor: Colors.white,
    hintStyle: const TextStyle(
      color: Color(0xFF6B7280),
      fontWeight: FontWeight.w500,
    ),
    labelStyle: const TextStyle(
      color: MenuColors.blue,
      fontWeight: FontWeight.w700,
    ),
    floatingLabelStyle: const TextStyle(
      color: MenuColors.blue,
      fontWeight: FontWeight.w800,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
      borderSide: const BorderSide(color: MenuColors.blue, width: 1.5),
    ),
  );
}

TextStyle _storefrontDropdownTextStyle() {
  return const TextStyle(
    color: Color(0xFF1F2937),
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
}

// ─── Search Autocomplete ──────────────────────────────────────────────────────

class _AutocompleteSearch extends StatefulWidget {
  const _AutocompleteSearch({
    required this.controller,
    required this.onChanged,
    required this.products,
    this.hintText = 'Tìm kiếm...',
  });

  final TextEditingController controller;
  final void Function(String) onChanged;
  final List<MenuProduct> products;
  final String hintText;

  @override
  State<_AutocompleteSearch> createState() => _AutocompleteSearchState();
}

class _AutocompleteSearchState extends State<_AutocompleteSearch> {
  final FocusNode _focusNode = FocusNode();
  OverlayEntry? _overlay;
  final LayerLink _layerLink = LayerLink();
  List<MenuProduct> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _removeOverlay();
    });
  }

  @override
  void dispose() {
    _removeOverlay();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    widget.onChanged(value);
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) {
      _removeOverlay();
      return;
    }
    final matches = widget.products
        .where((p) =>
            p.title.toLowerCase().contains(trimmed) ||
            p.category.toLowerCase().contains(trimmed))
        .take(6)
        .toList(growable: false);
    if (matches.isEmpty) {
      _removeOverlay();
      return;
    }
    setState(() => _suggestions = matches);
    _showOverlay();
  }

  void _select(MenuProduct product) {
    widget.controller.text = product.title;
    widget.onChanged(product.title);
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _showOverlay() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: context.findRenderObject() != null
            ? (context.findRenderObject() as RenderBox).size.width
            : 260,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 48),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _suggestions.map((p) {
                return InkWell(
                  onTap: () => _select(p),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            size: 14, color: MenuColors.gray),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p.title,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          p.category,
                          style: const TextStyle(
                              fontSize: 11, color: MenuColors.gray),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(growable: false),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlay!);
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        decoration: _storefrontFieldDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
    );
  }
}

class _StorefrontActionButton extends StatelessWidget {
  const _StorefrontActionButton({
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        backgroundColor: isActive ? const Color(0xFFEAF3FF) : Colors.white,
        side: BorderSide(
          color: isActive ? MenuColors.blue : const Color(0xFFD6E4FF),
          width: isActive ? 1.5 : 1.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive
              ? MenuColors.blue
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class MobileMenuLayout extends StatelessWidget {
  final MenuState state;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final void Function(String) onSearchChanged;
  final bool showTopHeader;
  final bool isTablet;
  final ValueNotifier<List<int>> compareIds;
  const MobileMenuLayout(
      {super.key,
      required this.state,
      required this.searchController,
      required this.scrollController,
      required this.onSearchChanged,
      required this.compareIds,
      this.showTopHeader = true,
      this.isTablet = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border.all(color: MenuColors.gray, width: 3),
        ),
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) => Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showTopHeader)
                    const PixelHeaderBar(
                        rightLabel: 'thực đơn',
                        showBack: true,
                        showBrand: false),
                  if (showTopHeader) const SizedBox(height: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          controller: scrollController,
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              _mobileSearchAndSort(),
                              if (state.isMooncakeTabSelected) ...[
                                const SizedBox(height: 12),
                                _mobileMooncakeBoxToolbar(context),
                              ],
                              const SizedBox(height: 12),
                              AnimatedBuilder(
                                animation: Listenable.merge(
                                  [
                                    state,
                                    AppServices.instance.wishlistSession,
                                    compareIds
                                  ],
                                ),
                                builder: (context, _) {
                                  final items = state.filteredProducts;
                                  return Column(
                                    children: items.isEmpty
                                        ? [
                                            if (state.isLoading)
                                              const _MenuGridSkeleton(
                                                  mobile: true)
                                            else if (state.errorMessage != null)
                                              _MenuFeedback(
                                                message: state.errorMessage ??
                                                    'Chưa có sản phẩm để hiển thị.',
                                                actionLabel: 'Tải lại',
                                                onTap: state.loadMenuPage,
                                              )
                                            else
                                              const _MenuEmptyState(
                                                message:
                                                    'Không tìm thấy sản phẩm phù hợp.',
                                              ),
                                          ]
                                        : isTablet
                                            ? _buildTabletGrid(context, items)
                                            : List<Widget>.generate(
                                                items.length * 2 - 1, (index) {
                                                if (index.isOdd) {
                                                  return const SizedBox(
                                                      height: 10);
                                                }
                                                return _buildMobileCard(
                                                    context, items[index ~/ 2]);
                                              }),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              const PixelFooter(
                                  label: 'PIXEL BAKERY | THỰC ĐƠN',
                                  mobile: true),
                            ],
                          ),
                        ),
                        BackToTopButton(scrollController: scrollController),
                      ],
                    ),
                  ),
                ],
              ),
              if (state.isMooncakeBoxMode)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _MooncakeBoxOverlay(
                    state: state,
                    compact: true,
                    onRemove: state.removeMooncakeBoxItemAt,
                    onCancel: state.clearMooncakeBoxPurchase,
                    onSubmit: () {
                      final item = state.buildMooncakeBoxCartItem();
                      if (item == null) {
                        return;
                      }
                      AppServices.instance.cartSession.addCartItem(item);
                      state.clearMooncakeBoxPurchase();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã thêm ${item.title} vào giỏ hàng'),
                        ),
                      );
                    },
                  ),
                ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _CompareBar(compareIds: compareIds),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleCompare(int productId) {
    final current = List<int>.from(compareIds.value);
    if (current.contains(productId)) {
      current.remove(productId);
    } else if (current.length < 3) {
      current.add(productId);
    }
    compareIds.value = List<int>.unmodifiable(current);
  }

  void _openDetail(BuildContext context, MenuProduct item) {
    context.go('${AppRoutePaths.productDetail}?id=${item.id}');
  }

  void _addToCart(BuildContext context, MenuProduct item) {
    if (item.mooncakeConfig != null) {
      _handleMooncakeAction(context, item);
      return;
    }
    AppServices.instance.cartSession.addProduct(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${item.title} vào giỏ hàng'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMobileCard(BuildContext context, MenuProduct item) {
    final isSelectedForCompare = compareIds.value.contains(item.id);
    return _MenuItemCard(
      productId: item.id,
      title: item.title,
      price: item.price,
      imageUrl: item.images.isEmpty ? null : item.images.first,
      averageRating: item.averageRating,
      reviewCount: item.reviewCount,
      tone: item.category == 'Cookie'
          ? const Color(0xFFFFF1F1)
          : const Color(0xFFEAF3FF),
      accent: item.category == 'Cookie' ? MenuColors.red : MenuColors.blue,
      isMooncake: item.mooncakeConfig != null,
      isAddingToBox: state.isMooncakeBoxMode && item.mooncakeConfig != null,
      isFavorite: AppServices.instance.wishlistSession.contains(item.id),
      isSelectedForCompare: isSelectedForCompare,
      compact: true,
      onTap: () => _openDetail(context, item),
      onAddToCart: () => _addToCart(context, item),
      onToggleFavorite: () =>
          AppServices.instance.wishlistSession.toggle(item.id),
      onToggleCompare: () => _toggleCompare(item.id),
    );
  }

  List<Widget> _buildTabletGrid(BuildContext context, List<MenuProduct> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      final rowItems = items.skip(i).take(2).toList();
      rows.add(Row(
        children: List<Widget>.generate(rowItems.length * 2 - 1, (index) {
          if (index.isOdd) return const SizedBox(width: 10);
          return Expanded(
              child: _buildMobileCard(context, rowItems[index ~/ 2]));
        }),
      ));
      if (i + 2 < items.length) rows.add(const SizedBox(height: 10));
    }
    return rows;
  }

  Widget _mobileSearchAndSort() => ControllerSelector<MenuState, MenuViewState>(
        controller: state,
        selector: (controller) => controller.state,
        builder: (context, menuState, _) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDCE4EF), width: 1.5),
          ),
          child: Column(
            children: [
              _AutocompleteSearch(
                controller: searchController,
                onChanged: onSearchChanged,
                products: state.products,
                hintText: 'Tìm sản phẩm...',
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: menuState.sortKey,
                style: _storefrontDropdownTextStyle(),
                items: const [
                  DropdownMenuItem(value: 'featured', child: Text('Nổi bật')),
                  DropdownMenuItem(
                      value: 'rating_desc', child: Text('Đánh giá cao')),
                  DropdownMenuItem(
                      value: 'price_asc', child: Text('Giá tăng dần')),
                  DropdownMenuItem(
                      value: 'price_desc', child: Text('Giá giảm dần')),
                ],
                onChanged: (value) {
                  if (value != null) state.setSortKey(value);
                },
                decoration: _storefrontFieldDecoration(labelText: 'Sắp xếp'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: menuState.priceRangeKey,
                style: _storefrontDropdownTextStyle(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Mọi mức giá')),
                  DropdownMenuItem(
                      value: 'under_100k', child: Text('Dưới 100k')),
                  DropdownMenuItem(
                      value: '100k_200k', child: Text('100k - 200k')),
                  DropdownMenuItem(
                      value: 'over_200k', child: Text('Trên 200k')),
                ],
                onChanged: (value) {
                  if (value != null) state.setPriceRangeKey(value);
                },
                decoration: _storefrontFieldDecoration(labelText: 'Giá'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                value: menuState.minimumRating,
                style: _storefrontDropdownTextStyle(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Mọi đánh giá')),
                  DropdownMenuItem(value: 4, child: Text('Từ 4.0 sao')),
                  DropdownMenuItem(value: 4.5, child: Text('Từ 4.5 sao')),
                ],
                onChanged: (value) {
                  if (value != null) state.setMinimumRating(value);
                },
                decoration: _storefrontFieldDecoration(labelText: 'Đánh giá'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _StorefrontActionButton(
                      label: 'Chỉ yêu thích',
                      isActive: menuState.favoritesOnly,
                      onTap: state.toggleFavoritesOnly,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StorefrontActionButton(
                    label: 'Xóa lọc',
                    onTap: () {
                      searchController.clear();
                      state.clearSearchFilters();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _mobileMooncakeBoxToolbar(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F0FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDCC8F7), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mua theo hộp bánh trung thu',
              style: TextStyle(
                color: MenuColors.blue,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn hộp trước, sau đó dùng nút thêm trên từng bánh để nạp vào hộp.',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _showMooncakeBoxPicker(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8E44AD),
                  minimumSize: const Size(0, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  state.isMooncakeBoxMode ? 'Đổi hộp' : 'Mua theo hộp',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _showMooncakeBoxPicker(BuildContext context) async {
    final boxOptions = state.mooncakeConfig?.boxOptions ?? const [];
    if (boxOptions.isEmpty) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn hộp bánh trung thu'),
        content: SizedBox(
          width: 720,
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: boxOptions.map((box) {
              return GestureDetector(
                onTap: () {
                  state.startMooncakeBoxPurchase(box.code);
                  Navigator.of(dialogContext).pop();
                },
                child: Container(
                  width: 210,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDCC8F7),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          box.imageUrl,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        box.label,
                        style: const TextStyle(
                          color: MenuColors.blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${box.cakeCount} bánh • Phụ phí ${box.packagePrice}',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ),
      ),
    );
  }

  Future<void> _handleMooncakeAction(
      BuildContext context, MenuProduct item) async {
    final config = item.mooncakeConfig;
    if (config == null) {
      return;
    }
    final selection = await _showMooncakeVariantPicker(
      context,
      product: item,
      config: config,
    );
    if (selection == null) {
      return;
    }
    if (state.isMooncakeBoxMode) {
      final added = state.addMooncakeItemToBox(
        item,
        weight: selection.$1,
        egg: selection.$2,
      );
      if (!added) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Hộp đã đủ số lượng bánh. Hãy xóa bớt hoặc thêm vào giỏ.'),
          ),
        );
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Đã thêm ${item.title} (${selection.$1.label} - ${selection.$2.label}) vào hộp.',
          ),
        ),
      );
      return;
    }
    final cartItem = CartItem(
      productId: item.id,
      title: item.title,
      price: selection.$2.price,
      priceValue: selection.$2.priceValue,
      category: item.category,
      imageUrl: item.images.isEmpty ? '' : item.images.first,
      quantity: 1,
      variantKey: 'single:${selection.$1.code}:${selection.$2.count}',
      variantLabel: '${selection.$1.label} • ${selection.$2.label}',
    );
    AppServices.instance.cartSession.addCartItem(cartItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Đã thêm ${item.title} (${cartItem.variantLabel}) vào giỏ hàng'),
      ),
    );
  }

  Future<(MooncakeWeightOption, MooncakeEggOption)?> _showMooncakeVariantPicker(
    BuildContext context, {
    required MenuProduct product,
    required MooncakeProductConfig config,
  }) async {
    var selectedWeight = config.weightOptions.first;
    var selectedEgg = selectedWeight.eggOptions.first;
    return showDialog<(MooncakeWeightOption, MooncakeEggOption)>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Chọn phiên bản ${product.title}'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Khối lượng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: config.weightOptions.map((weight) {
                    final selected = selectedWeight.code == weight.code;
                    return ChoiceChip(
                      label: Text(weight.label),
                      selected: selected,
                      onSelected: (_) {
                        selectedWeight = weight;
                        selectedEgg = weight.eggOptions.first;
                        setDialogState(() {});
                      },
                    );
                  }).toList(growable: false),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Số trứng',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedWeight.eggOptions.map((egg) {
                    final selected = selectedEgg.count == egg.count;
                    return ChoiceChip(
                      label: Text('${egg.label} • ${egg.price}'),
                      selected: selected,
                      onSelected: (_) {
                        selectedEgg = egg;
                        setDialogState(() {});
                      },
                    );
                  }).toList(growable: false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext)
                  .pop((selectedWeight, selectedEgg)),
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final int productId;
  final String title;
  final String price;
  final String? imageUrl;
  final double averageRating;
  final int reviewCount;
  final Color tone;
  final Color accent;
  final bool compact;
  final bool isMooncake;
  final bool isAddingToBox;
  final bool isFavorite;
  final bool isSelectedForCompare;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onToggleCompare;

  const _MenuItemCard({
    required this.productId,
    required this.title,
    required this.price,
    this.imageUrl,
    required this.averageRating,
    required this.reviewCount,
    required this.tone,
    required this.accent,
    this.compact = false,
    this.isMooncake = false,
    this.isAddingToBox = false,
    this.isFavorite = false,
    this.isSelectedForCompare = false,
    this.onTap,
    this.onAddToCart,
    this.onToggleFavorite,
    this.onToggleCompare,
  });

  @override
  Widget build(BuildContext context) {
    final width = compact ? double.infinity : 376.0;
    return Pressable(
      onTap: onTap,
      child: RepaintBoundary(
        child: Container(
          width: width,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: MenuColors.gray, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: compact ? 120 : 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: MenuColors.gray, width: 2),
                      image: imageUrl == null
                          ? null
                          : DecorationImage(
                              image: NetworkImage(imageUrl!),
                              fit: BoxFit.cover,
                              onError: (_, __) {},
                            ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: onToggleFavorite,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: MenuColors.gray, width: 2),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 18,
                              color:
                                  isFavorite ? MenuColors.red : MenuColors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: onToggleCompare,
                          child: Tooltip(
                            message:
                                isSelectedForCompare ? 'Bỏ so sánh' : 'So sánh',
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelectedForCompare
                                    ? MenuColors.blue
                                    : Theme.of(context).cardColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: MenuColors.gray, width: 2),
                              ),
                              child: Icon(
                                Icons.compare_arrows,
                                size: 18,
                                color: isSelectedForCompare
                                    ? Colors.white
                                    : MenuColors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                      color: accent,
                      fontSize: compact ? 14 : 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.star,
                      size: compact ? 14 : 16, color: Colors.amber.shade700),
                  const SizedBox(width: 4),
                  Text(
                    averageRating <= 0
                        ? 'Mới'
                        : averageRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: MenuColors.blue,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($reviewCount)',
                    style: TextStyle(
                      color: MenuColors.gray,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(price,
                  style: TextStyle(
                      color: MenuColors.green,
                      fontSize: compact ? 18 : 22,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onAddToCart,
                child: Container(
                  width: double.infinity,
                  height: compact ? 34 : 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isAddingToBox
                        ? const Color(0xFF8E44AD)
                        : MenuColors.red,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: MenuColors.gray, width: 2),
                  ),
                  child: Text(
                    isAddingToBox ? 'Thêm vào hộp' : 'Thêm vào giỏ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MooncakeBoxOverlay extends StatelessWidget {
  const _MooncakeBoxOverlay({
    required this.state,
    required this.onRemove,
    required this.onCancel,
    required this.onSubmit,
    this.compact = false,
  });

  final MenuState state;
  final ValueChanged<int> onRemove;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final box = state.activeMooncakeBoxOption;
    if (box == null) {
      return const SizedBox.shrink();
    }

    final width = compact ? double.infinity : 360.0;
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        margin: EdgeInsets.only(top: 16, left: compact ? 0 : 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCC8F7), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        box.label,
                        style: const TextStyle(
                          color: Color(0xFF8E44AD),
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Đã chọn ${state.mooncakeBoxItems.length}/${box.cakeCount} bánh',
                        style: const TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F0FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${state.remainingMooncakeBoxSlots} chỗ trống',
                    style: const TextStyle(
                      color: Color(0xFF8E44AD),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: compact ? 200 : 260),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(box.cakeCount, (index) {
                    final hasItem = index < state.mooncakeBoxItems.length;
                    if (!hasItem) {
                      return Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(
                          bottom: index == box.cakeCount - 1 ? 0 : 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD7DEE8),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          'Ô bánh ${index + 1}: Chưa chọn bánh',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }

                    final item = state.mooncakeBoxItems[index];
                    return Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(
                        bottom: index == box.cakeCount - 1 ? 0 : 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F0FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDCC8F7),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: item.imageUrl.isEmpty
                                ? Container(
                                    width: 48,
                                    height: 48,
                                    color: const Color(0xFFE5E7EB),
                                  )
                                : Image.network(
                                    item.imageUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bánh ${index + 1}: ${item.title}',
                                  style: const TextStyle(
                                    color: Color(0xFF1F2937),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.variantLabel,
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item.price,
                                  style: const TextStyle(
                                    color: MenuColors.green,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => onRemove(index),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: MenuColors.red,
                            ),
                            tooltip: 'Xóa bánh khỏi hộp',
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tạm tính hộp: ${_formatCurrency(state.mooncakeBoxSubtotal)}',
                    style: const TextStyle(
                      color: MenuColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 46),
                      side: const BorderSide(color: Color(0xFFD6DCE5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy hộp',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: state.canSubmitMooncakeBox ? onSubmit : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF8E44AD),
                      minimumSize: const Size(0, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Thêm hộp vào giỏ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reversedIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()}đ';
  }
}

class _CompareBar extends StatelessWidget {
  const _CompareBar({required this.compareIds});

  final ValueNotifier<List<int>> compareIds;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<int>>(
      valueListenable: compareIds,
      builder: (context, ids, _) {
        if (ids.length < 2) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: MenuColors.blue,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MenuColors.gray, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.compare_arrows, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã chọn ${ids.length} sản phẩm để so sánh',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  compareIds.value = const [];
                },
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  final idsStr = ids.join(',');
                  context.go('${AppRoutePaths.compare}?ids=$idsStr');
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: MenuColors.gray, width: 1.5),
                  ),
                  child: Text(
                    'So sánh (${ids.length})',
                    style: const TextStyle(
                      color: MenuColors.blue,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MenuGridSkeleton extends StatelessWidget {
  const _MenuGridSkeleton({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(mobile ? 3 : 2, (rowIndex) {
        final children = List.generate(mobile ? 1 : 3, (index) {
          return Expanded(
            child: Container(
              height: mobile ? 230 : 290,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: MenuColors.gray, width: 2),
              ),
              child: Column(
                children: [
                  ShimmerBox(
                      width: double.infinity,
                      height: mobile ? 120 : 150,
                      borderRadius: 6),
                  const SizedBox(height: 10),
                  const ShimmerBox(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  const ShimmerBox(width: 100, height: 14),
                  const Spacer(),
                  const ShimmerBox(
                      width: double.infinity, height: 36, borderRadius: 6),
                ],
              ),
            ),
          );
        });
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: List.generate(children.length * 2 - 1, (index) {
              if (index.isOdd) return const SizedBox(width: 10);
              return children[index ~/ 2];
            }),
          ),
        );
      }),
    );
  }
}

class _MenuEmptyState extends StatelessWidget {
  const _MenuEmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MenuColors.gray, width: 2),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: MenuColors.gray,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MenuFeedback extends StatelessWidget {
  const _MenuFeedback({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MenuColors.gray, width: 2),
      ),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: MenuColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => onTap(),
            child: Container(
              width: 110,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MenuColors.blue,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: MenuColors.gray, width: 2),
              ),
              child: const Text(
                'Tải lại',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
