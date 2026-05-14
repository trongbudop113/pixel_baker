import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/menu_models.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';
import '../menu/menu_state.dart';
import '../shared/app_header.dart';
import '../shared/pixel_empty_state.dart';

class WishlistColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
}

class ResponsiveWishlistScreen extends StatefulWidget {
  const ResponsiveWishlistScreen({super.key, this.showTopHeader = true});

  final bool showTopHeader;

  @override
  State<ResponsiveWishlistScreen> createState() =>
      _ResponsiveWishlistScreenState();
}

class _ResponsiveWishlistScreenState extends State<ResponsiveWishlistScreen> {
  late final MenuState _state;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = MenuState(
      repository: AppServices.instance.menuRepository,
      wishlistSession: AppServices.instance.wishlistSession,
    );
    _state.setFavoritesOnly(true);
    _state.loadMenuPage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    return isMobile
        ? _WishlistMobileLayout(
            state: _state,
            searchController: _searchController,
            showTopHeader: widget.showTopHeader,
          )
        : _WishlistWebLayout(
            state: _state,
            searchController: _searchController,
            showTopHeader: widget.showTopHeader,
          );
  }
}

class _WishlistWebLayout extends StatelessWidget {
  const _WishlistWebLayout({
    required this.state,
    required this.searchController,
    required this.showTopHeader,
  });

  final MenuState state;
  final TextEditingController searchController;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1200,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: WishlistColors.gray, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                rightLabel: 'yêu thích',
                showBack: true,
                showBrand: false,
              ),
            if (showTopHeader) const SizedBox(height: 12),
            _header(),
            const SizedBox(height: 12),
            _filters(context),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    state,
                    AppServices.instance.wishlistSession,
                  ]),
                  builder: (context, _) {
                    final items = state.filteredProducts;
                    if (state.isLoading && items.isEmpty) {
                      return const _WishlistSkeleton();
                    }
                    if (state.errorMessage != null && items.isEmpty) {
                      return _WishlistFeedback(
                        message: state.errorMessage!,
                        actionLabel: 'Tải lại',
                        onTap: state.loadMenuPage,
                      );
                    }
                    if (AppServices.instance.wishlistSession.itemCount == 0) {
                      return PixelEmptyState(
                        icon: Icons.favorite_border_rounded,
                        title: 'Danh sách yêu thích trống',
                        subtitle: 'Nhấn ♡ trên sản phẩm để lưu lại',
                        actionLabel: 'Xem thực đơn',
                        onAction: () => context.go('/menu'),
                      );
                    }
                    if (items.isEmpty) {
                      return const PixelEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Không tìm thấy sản phẩm',
                        subtitle: 'Không tìm thấy sản phẩm yêu thích phù hợp với bộ lọc hiện tại.',
                      );
                    }
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: items
                          .map(
                            (item) => SizedBox(
                              width: 376,
                              child: _WishlistProductCard(product: item),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
        padding: const EdgeInsets.all(14),
        decoration: _boxDec(),
        child: AnimatedBuilder(
          animation: AppServices.instance.wishlistSession,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Danh sách yêu thích',
                style: TextStyle(
                  color: WishlistColors.blue,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bạn đang lưu ${AppServices.instance.wishlistSession.itemCount} sản phẩm để xem lại nhanh hơn.',
                style: const TextStyle(
                  color: WishlistColors.gray,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _filters(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) => Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE4EF)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: state.setSearchQuery,
                      decoration: _wishlistFieldDecoration(
                        hintText: 'Tìm trong sản phẩm yêu thích...',
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String>(
                      value: state.sortKey,
                      style: _wishlistDropdownTextStyle(),
                      items: const [
                        DropdownMenuItem(value: 'featured', child: Text('Nổi bật')),
                        DropdownMenuItem(value: 'rating_desc', child: Text('Đánh giá cao')),
                        DropdownMenuItem(value: 'price_asc', child: Text('Giá tăng dần')),
                        DropdownMenuItem(value: 'price_desc', child: Text('Giá giảm dần')),
                      ],
                      onChanged: (value) {
                        if (value != null) state.setSortKey(value);
                      },
                      decoration: _wishlistFieldDecoration(labelText: 'Sắp xếp'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 170,
                    child: DropdownButtonFormField<String>(
                      value: state.priceRangeKey,
                      style: _wishlistDropdownTextStyle(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Mọi mức giá')),
                        DropdownMenuItem(value: 'under_100k', child: Text('Dưới 100k')),
                        DropdownMenuItem(value: '100k_200k', child: Text('100k - 200k')),
                        DropdownMenuItem(value: 'over_200k', child: Text('Trên 200k')),
                      ],
                      onChanged: (value) {
                        if (value != null) state.setPriceRangeKey(value);
                      },
                      decoration: _wishlistFieldDecoration(labelText: 'Giá'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 160,
                    child: DropdownButtonFormField<double>(
                      value: state.minimumRating,
                      style: _wishlistDropdownTextStyle(),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Mọi đánh giá')),
                        DropdownMenuItem(value: 4, child: Text('Từ 4.0 sao')),
                        DropdownMenuItem(value: 4.5, child: Text('Từ 4.5 sao')),
                      ],
                      onChanged: (value) {
                        if (value != null) state.setMinimumRating(value);
                      },
                      decoration: _wishlistFieldDecoration(labelText: 'Đánh giá'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _WishlistActionButton(
                    label: 'Xóa lọc',
                    onTap: () {
                      searchController.clear();
                      state.clearSearchFilters();
                      state.setFavoritesOnly(true);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: _boxDec(),
              child: Row(
                children: List.generate(state.filters.length * 2 - 1, (index) {
                  if (index.isOdd) return const SizedBox(width: 6);
                  final filter = state.filters[index ~/ 2];
                  final filterIndex = index ~/ 2;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => state.selectFilter(filterIndex),
                      child: Container(
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: state.selectedFilterIndex == filterIndex
                              ? const Color(0xFFEAF3FF)
                              : const Color(0xFFFCFDFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: state.selectedFilterIndex == filterIndex
                                ? WishlistColors.blue
                                : const Color(0xFFD7DEE8),
                            width:
                                state.selectedFilterIndex == filterIndex ? 1.8 : 1.2,
                          ),
                        ),
                        child: Text(
                          filter.label,
                          style: TextStyle(
                            color: state.selectedFilterIndex == filterIndex
                                ? WishlistColors.blue
                                : const Color(0xFF374151),
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      );

  BoxDecoration _boxDec() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WishlistColors.gray, width: 2),
      );
}

class _WishlistMobileLayout extends StatelessWidget {
  const _WishlistMobileLayout({
    required this.state,
    required this.searchController,
    required this.showTopHeader,
  });

  final MenuState state;
  final TextEditingController searchController;
  final bool showTopHeader;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 390,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: WishlistColors.gray, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                rightLabel: 'yêu thích',
                showBack: true,
                showBrand: false,
              ),
            if (showTopHeader) const SizedBox(height: 10),
            _WishlistWebLayout(
              state: state,
              searchController: searchController,
              showTopHeader: false,
            )._header(),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDCE4EF)),
                      ),
                      child: Column(
                        children: [
                          TextField(
                      controller: searchController,
                      onChanged: state.setSearchQuery,
                      decoration: _wishlistFieldDecoration(
                        hintText: 'Tìm trong yêu thích...',
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: state.sortKey,
                      style: _wishlistDropdownTextStyle(),
                      items: const [
                        DropdownMenuItem(value: 'featured', child: Text('Nổi bật')),
                        DropdownMenuItem(value: 'rating_desc', child: Text('Đánh giá cao')),
                        DropdownMenuItem(value: 'price_asc', child: Text('Giá tăng dần')),
                        DropdownMenuItem(value: 'price_desc', child: Text('Giá giảm dần')),
                      ],
                      onChanged: (value) {
                        if (value != null) state.setSortKey(value);
                      },
                      decoration: _wishlistFieldDecoration(labelText: 'Sắp xếp'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: state.priceRangeKey,
                      style: _wishlistDropdownTextStyle(),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('Mọi mức giá')),
                        DropdownMenuItem(value: 'under_100k', child: Text('Dưới 100k')),
                        DropdownMenuItem(value: '100k_200k', child: Text('100k - 200k')),
                        DropdownMenuItem(value: 'over_200k', child: Text('Trên 200k')),
                      ],
                      onChanged: (value) {
                        if (value != null) state.setPriceRangeKey(value);
                      },
                      decoration: _wishlistFieldDecoration(labelText: 'Giá'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<double>(
                      value: state.minimumRating,
                      style: _wishlistDropdownTextStyle(),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Mọi đánh giá')),
                        DropdownMenuItem(value: 4, child: Text('Từ 4.0 sao')),
                        DropdownMenuItem(value: 4.5, child: Text('Từ 4.5 sao')),
                      ],
                      onChanged: (value) {
                        if (value != null) state.setMinimumRating(value);
                      },
                      decoration: _wishlistFieldDecoration(labelText: 'Đánh giá'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _WishlistActionButton(
                            label: 'Xóa lọc',
                            onTap: () {
                              searchController.clear();
                              state.clearSearchFilters();
                              state.setFavoritesOnly(true);
                            },
                          ),
                        ),
                      ],
                    ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    AnimatedBuilder(
                      animation: Listenable.merge([
                        state,
                        AppServices.instance.wishlistSession,
                      ]),
                      builder: (context, _) {
                        final items = state.filteredProducts;
                        if (state.isLoading && items.isEmpty) {
                          return const _WishlistSkeleton(mobile: true);
                        }
                        if (state.errorMessage != null && items.isEmpty) {
                          return _WishlistFeedback(
                            message: state.errorMessage!,
                            actionLabel: 'Tải lại',
                            onTap: state.loadMenuPage,
                          );
                        }
                        if (AppServices.instance.wishlistSession.itemCount == 0) {
                          return PixelEmptyState(
                            icon: Icons.favorite_border_rounded,
                            title: 'Danh sách yêu thích trống',
                            subtitle: 'Nhấn ♡ trên sản phẩm để lưu lại',
                            actionLabel: 'Xem thực đơn',
                            onAction: () => context.go('/menu'),
                          );
                        }
                        if (items.isEmpty) {
                          return const PixelEmptyState(
                            icon: Icons.search_off_rounded,
                            title: 'Không tìm thấy sản phẩm',
                            subtitle: 'Không tìm thấy sản phẩm yêu thích phù hợp.',
                          );
                        }
                        return Column(
                          children: items
                              .map(
                                (item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _WishlistProductCard(
                                    product: item,
                                    compact: true,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _wishlistFieldDecoration({
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
      color: WishlistColors.blue,
      fontWeight: FontWeight.w700,
    ),
    floatingLabelStyle: const TextStyle(
      color: WishlistColors.blue,
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
      borderSide: const BorderSide(color: WishlistColors.blue, width: 1.5),
    ),
  );
}

TextStyle _wishlistDropdownTextStyle() {
  return const TextStyle(
    color: Color(0xFF1F2937),
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
}

class _WishlistActionButton extends StatelessWidget {
  const _WishlistActionButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: const BorderSide(color: Color(0xFFD6E4FF)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: WishlistColors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WishlistProductCard extends StatelessWidget {
  const _WishlistProductCard({
    required this.product,
    this.compact = false,
  });

  final MenuProduct product;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isFavorite =
        AppServices.instance.wishlistSession.contains(product.id);
    final accent =
        product.category == 'Cookie' ? WishlistColors.red : WishlistColors.blue;
    final tone = product.category == 'Cookie'
        ? const Color(0xFFFFF1F1)
        : const Color(0xFFEAF3FF);
    return GestureDetector(
      onTap: () => context.go('${AppRoutePaths.productDetail}?id=${product.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: WishlistColors.gray, width: 2),
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
                    border: Border.all(color: WishlistColors.gray, width: 2),
                    image: product.images.isEmpty
                        ? null
                        : DecorationImage(
                            image: NetworkImage(product.images.first),
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () =>
                        AppServices.instance.wishlistSession.toggle(product.id),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: WishlistColors.gray, width: 2),
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: isFavorite
                            ? WishlistColors.red
                            : WishlistColors.blue,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              product.title,
              style: TextStyle(
                color: accent,
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.star, size: compact ? 14 : 16, color: Colors.amber.shade700),
                const SizedBox(width: 4),
                Text(
                  product.averageRating <= 0
                      ? 'Mới'
                      : product.averageRating.toStringAsFixed(1),
                  style: TextStyle(
                    color: WishlistColors.blue,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${product.reviewCount})',
                  style: TextStyle(
                    color: WishlistColors.gray,
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              product.price,
              style: TextStyle(
                color: WishlistColors.green,
                fontSize: compact ? 18 : 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                AppServices.instance.cartSession.addProduct(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã thêm ${product.title} vào giỏ hàng'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: compact ? 34 : 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: WishlistColors.red,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: WishlistColors.gray, width: 2),
                ),
                child: Text(
                  'Thêm vào giỏ',
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
    );
  }
}

class _WishlistEmptyState extends StatelessWidget {
  const _WishlistEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WishlistColors.gray, width: 2),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: WishlistColors.gray,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _WishlistFeedback extends StatelessWidget {
  const _WishlistFeedback({
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return _WishlistEmptyState(message: message);
  }
}

class _WishlistSkeleton extends StatelessWidget {
  const _WishlistSkeleton({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(mobile ? 3 : 2, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: mobile ? 260 : 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: WishlistColors.gray, width: 2),
          ),
        );
      }),
    );
  }
}
