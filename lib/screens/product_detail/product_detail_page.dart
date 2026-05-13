import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:universal_html/html.dart' as html;

import '../../app/models/menu_models.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';
import '../shared/app_header.dart';
import 'product_detail_state.dart';

class ProductDetailColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
  static const soft = Color(0xFFF8F8F8);
}

class ResponsiveProductDetailScreen extends StatefulWidget {
  final int productId;
  final bool showTopHeader;
  final bool autoOpenMooncakeBox;
  const ResponsiveProductDetailScreen({
    super.key,
    required this.productId,
    this.showTopHeader = true,
    this.autoOpenMooncakeBox = false,
  });

  @override
  State<ResponsiveProductDetailScreen> createState() =>
      _ResponsiveProductDetailScreenState();
}

class _ResponsiveProductDetailScreenState
    extends State<ResponsiveProductDetailScreen> {
  late final ProductDetailState detailState;
  bool _didAutoOpenMooncakeBox = false;

  @override
  void initState() {
    super.initState();
    detailState = ProductDetailState(
      repository: AppServices.instance.menuRepository,
      productId: widget.productId,
    );
    detailState.load();
  }

  @override
  void dispose() {
    detailState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.autoOpenMooncakeBox &&
        !_didAutoOpenMooncakeBox &&
        !detailState.isLoading &&
        detailState.isMooncake) {
      _didAutoOpenMooncakeBox = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showMooncakeBoxSelectorDialog(context, detailState);
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return isMobile
            ? _MobileProductDetail(
                state: detailState, showTopHeader: widget.showTopHeader)
            : _WebProductDetail(
                state: detailState, showTopHeader: widget.showTopHeader);
      },
    );
  }
}

class _WebProductDetail extends StatelessWidget {
  final ProductDetailState state;
  final bool showTopHeader;
  const _WebProductDetail({required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (state.isLoading) {
          return _ProductDetailLoading(showTopHeader: showTopHeader);
        }

        if (state.product == null) {
          return _ProductDetailError(
            showTopHeader: showTopHeader,
            message: state.errorMessage ?? 'Không tìm thấy sản phẩm.',
            onRetry: state.load,
          );
        }

        return SizedBox(
          width: 1200,
          height: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ProductDetailColors.gray, width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTopHeader)
                  const PixelHeaderBar(
                    rightLabel: 'chi tiết sản phẩm',
                    showBack: true,
                    showBrand: false,
                    backFallbackRoute: '/menu',
                  ),
                if (showTopHeader) const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: _gallery(state)),
                            const SizedBox(width: 14),
                            Expanded(flex: 6, child: _infoPanel(context, state)),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _descriptionPanel(state),
                        const SizedBox(height: 14),
                        _reviewsPanel(context),
                        const SizedBox(height: 14),
                        _relatedPanel(context, state),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _gallery(ProductDetailState s) {
    return _card(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                  border:
                      Border.all(color: ProductDetailColors.gray, width: 2)),
              child: Image.network(s.images[s.selectedImage],
                  fit: BoxFit.cover, width: double.infinity),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(s.images.length * 2 - 1, (i) {
              if (i.isOdd) return const SizedBox(width: 10);
              final idx = i ~/ 2;
              final selected = s.selectedImage == idx;
              return Expanded(
                child: GestureDetector(
                  onTap: () => s.selectImage(idx),
                  child: Container(
                    height: 92,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: selected
                              ? ProductDetailColors.blue
                              : ProductDetailColors.gray,
                          width: 2),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(s.images[idx], fit: BoxFit.cover),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _infoPanel(BuildContext context, ProductDetailState s) {
    final product = s.product!;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _txt(
                  product.title,
                  ProductDetailColors.red,
                  30,
                  FontWeight.w900,
                ),
              ),
              IconButton(
                onPressed: () => _shareProduct(context, product.id, product.title),
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Chia sẻ sản phẩm',
                color: ProductDetailColors.blue,
              ),
              AnimatedBuilder(
                animation: AppServices.instance.wishlistSession,
                builder: (context, _) {
                  final isFavorite =
                      AppServices.instance.wishlistSession.contains(product.id);
                  return IconButton(
                    onPressed: () =>
                        AppServices.instance.wishlistSession.toggle(product.id),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite
                          ? ProductDetailColors.red
                          : ProductDetailColors.blue,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _txt(
            'Mã SP: ${product.sku}',
            ProductDetailColors.gray,
            12,
            FontWeight.w700,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _txt(s.displayPrice, ProductDetailColors.green, 30,
                  FontWeight.w900),
              const SizedBox(width: 10),
              _chip(product.stockStatus, ProductDetailColors.blue),
              const SizedBox(width: 10),
              _ratingChip(product.averageRating, product.reviewCount),
            ],
          ),
          const SizedBox(height: 12),
          _txt(product.description, ProductDetailColors.gray, 14,
              FontWeight.w500),
          if (s.isMooncake) ...[
            const SizedBox(height: 14),
            _mooncakeConfigurator(context, s),
          ],
          const SizedBox(height: 14),
          _line('Danh mục', product.category),
          const SizedBox(height: 8),
          _line('Khối lượng', product.weight),
          const SizedBox(height: 8),
          _line('Bảo quản', product.storageNote),
          const SizedBox(height: 8),
          _line('Giao hàng', product.deliveryNote),
          const SizedBox(height: 8),
          _line('Thư viện ảnh', '${product.images.length} ảnh'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ProductDetailColors.soft,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ProductDetailColors.gray, width: 2),
            ),
            child: Row(
              children: [
                _qtyBtn('-', s.decreaseQty),
                Container(
                  width: 52,
                  height: 38,
                  alignment: Alignment.center,
                  child: _txt('${s.qty}', ProductDetailColors.blue, 18,
                      FontWeight.w900),
                ),
                _qtyBtn('+', s.increaseQty),
                const Spacer(),
                _txt('Tạm tính: ', ProductDetailColors.gray, 14,
                    FontWeight.w700),
                _txt(_formatCurrency(s.total), ProductDetailColors.red, 16,
                    FontWeight.w900),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _cta(
                  'THÊM VÀO GIỎ',
                  ProductDetailColors.red,
                  onTap: () => _addToCart(context, s),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _cta(
                  'MUA NGAY',
                  ProductDetailColors.blue,
                  onTap: () => _buyNow(context, s),
                ),
              ),
            ],
          ),
          if (s.isMooncake) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: _cta(
                'MUA THEO HỘP',
                const Color(0xFF8E44AD),
                onTap: () => _showMooncakeBoxDialog(context, s),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mooncakeConfigurator(BuildContext context, ProductDetailState s) {
    final weightOptions = s.mooncakeConfig?.weightOptions ?? const [];
    final eggOptions = s.availableEggOptions;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5C07B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt('Tùy chọn bánh trung thu', ProductDetailColors.blue, 15,
              FontWeight.w900),
          const SizedBox(height: 10),
          _txt('Chọn khối lượng', ProductDetailColors.gray, 12, FontWeight.w800),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weightOptions.map((option) {
              final selected = s.selectedWeightCode == option.code;
              return _optionChip(
                option.label,
                selected: selected,
                onTap: () => s.selectWeight(option.code),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
          _txt('Chọn số trứng', ProductDetailColors.gray, 12, FontWeight.w800),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: eggOptions.map((option) {
              final selected = s.selectedEggCount == option.count;
              return _optionChip(
                '${option.label} • ${option.price}',
                selected: selected,
                onTap: () => s.selectEggCount(option.count),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _descriptionPanel(ProductDetailState s) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Mô tả chi tiết', ProductDetailColors.blue, 18,
                FontWeight.w800),
            const SizedBox(height: 8),
            _txt(
              _buildDetailedDescription(s.product!),
              ProductDetailColors.gray,
              14,
              FontWeight.w500,
            ),
          ],
        ),
      );

  Widget _reviewsPanel(BuildContext context) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _txt('Đánh giá khách hàng', ProductDetailColors.blue, 18,
                    FontWeight.w800),
                const Spacer(),
                _ctaMini(
                  'Viết đánh giá',
                  ProductDetailColors.blue,
                  onTap: () => _openReviewDialog(context, state),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.product!.reviews.isEmpty)
              _txt(
                'Chưa có đánh giá.',
                ProductDetailColors.gray,
                13,
                FontWeight.w500,
              )
            else
              ...List.generate(state.product!.reviews.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const SizedBox(height: 8);
                }
                final review = state.product!.reviews[index ~/ 2];
                final accent =
                    index == 0 ? ProductDetailColors.red : ProductDetailColors.blue;
                return _review(review, accent);
              }),
          ],
        ),
      );

  Widget _relatedPanel(BuildContext context, ProductDetailState s) => _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Sản phẩm liên quan', ProductDetailColors.blue, 18,
                FontWeight.w800),
            const SizedBox(height: 8),
            if (s.relatedProducts.isEmpty)
              _txt(
                'Chưa có sản phẩm liên quan trong cùng danh mục.',
                ProductDetailColors.gray,
                13,
                FontWeight.w500,
              )
            else
              Row(
                children: List.generate(s.relatedProducts.length * 2 - 1, (i) {
                  if (i.isOdd) return const SizedBox(width: 10);
                  final item = s.relatedProducts[i ~/ 2];
                  return Expanded(
                    child: _RelatedCard(
                      product: item,
                      tone: _relatedTone(item),
                      onTap: () => context.go(
                        '${AppRoutePaths.productDetail}?id=${item.id}',
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      );

  Widget _review(MenuReviewItem review, Color accent) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ProductDetailColors.gray, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _txt(review.author, accent, 14, FontWeight.w800),
                const SizedBox(width: 8),
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _txt('“${review.content}”', ProductDetailColors.gray, 13, FontWeight.w500),
            if (review.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: review.mediaUrls.map((url) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      url,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  );
                }).toList(growable: false),
              ),
            ],
          ],
        ),
      );

  Widget _line(String k, String v) => Row(
        children: [
          SizedBox(
              width: 90,
              child: _txt(k, ProductDetailColors.gray, 13, FontWeight.w700)),
          Expanded(child: _txt(v, Colors.black87, 13, FontWeight.w600)),
        ],
      );

  Widget _qtyBtn(String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ProductDetailColors.gray, width: 2),
          ),
          child: _txt(text, ProductDetailColors.blue, 18, FontWeight.w900),
        ),
      );

  Widget _optionChip(
    String text, {
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? ProductDetailColors.blue : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? ProductDetailColors.blue : ProductDetailColors.gray,
              width: 2,
            ),
          ),
          child: _txt(
            text,
            selected ? Colors.white : ProductDetailColors.gray,
            12,
            FontWeight.w800,
          ),
        ),
      );

  Widget _cta(String text, Color bg, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ProductDetailColors.gray, width: 2),
          ),
          child: _txt(text, Colors.white, 14, FontWeight.w900),
        ),
      );

  Widget _ctaMini(String text, Color bg, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ProductDetailColors.gray, width: 2),
          ),
          child: _txt(text, Colors.white, 12, FontWeight.w800),
        ),
      );

  void _addToCart(BuildContext context, ProductDetailState s) {
    final item = s.buildSingleCartItem();
    if (item == null) {
      return;
    }
    AppServices.instance.cartSession.addCartItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${item.title} x${item.quantity} vào giỏ hàng'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow(BuildContext context, ProductDetailState s) {
    _addToCart(context, s);
    context.goNamed(AppRouteNames.checkout);
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color, width: 2),
        ),
        child: _txt(text, color, 11, FontWeight.w800),
      );

  Widget _ratingChip(double rating, int reviewCount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade700, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber.shade700),
            const SizedBox(width: 4),
            _txt(
              rating <= 0 ? 'Mới' : '${rating.toStringAsFixed(1)} ($reviewCount)',
              Colors.amber.shade900,
              11,
              FontWeight.w800,
            ),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ProductDetailColors.gray, width: 2),
        ),
        child: child,
      );

  Widget _txt(String text, Color color, double size, FontWeight weight) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      );

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

  String _buildDetailedDescription(MenuProduct product) {
    if (product is MenuProductDetail && product.detailBullets.isNotEmpty) {
      return product.detailBullets.map((item) => '• $item').join('\n');
    }
    return '• Danh mục: ${product.category}\n'
        '• ${product.description}\n'
        '• Bộ ảnh sản phẩm gồm ${product.images.length} góc chụp.\n'
        '• Giá niêm yết: ${product.price}.';
  }

  Color _relatedTone(MenuProduct item) {
    if (item.category == 'Cookie') return const Color(0xFFFFF1F1);
    if (item.category == 'Combo') return const Color(0xFFF1FAF1);
    return const Color(0xFFEAF3FF);
  }

  Future<void> _showMooncakeBoxDialog(
    BuildContext context,
    ProductDetailState s,
  ) async {
    await _showMooncakeBoxSelectorDialog(context, s);
  }
}

class _MobileProductDetail extends StatelessWidget {
  final ProductDetailState state;
  final bool showTopHeader;
  const _MobileProductDetail({required this.state, this.showTopHeader = true});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        if (state.isLoading) {
          return _ProductDetailLoading(showTopHeader: showTopHeader, mobile: true);
        }

        if (state.product == null) {
          return _ProductDetailError(
            showTopHeader: showTopHeader,
            message: state.errorMessage ?? 'Không tìm thấy sản phẩm.',
            onRetry: state.load,
            mobile: true,
          );
        }

        final product = state.product!;
        return SizedBox(
          width: 390,
          height: double.infinity,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ProductDetailColors.gray, width: 3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showTopHeader)
                  const PixelHeaderBar(
                    rightLabel: 'chi tiết',
                    showBack: true,
                    showBrand: false,
                    backFallbackRoute: '/menu',
                  ),
                if (showTopHeader) const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 230,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: ProductDetailColors.gray, width: 2),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                                state.images[state.selectedImage],
                                fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children:
                              List.generate(state.images.length * 2 - 1, (i) {
                            if (i.isOdd) return const SizedBox(width: 8);
                            final idx = i ~/ 2;
                            final selected = state.selectedImage == idx;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => state.selectImage(idx),
                                child: Container(
                                  height: 64,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: selected
                                            ? ProductDetailColors.blue
                                            : ProductDetailColors.gray,
                                        width: 2),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(state.images[idx],
                                        fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 10),
                        _mobileCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _mTxt(product.title, ProductDetailColors.red,
                                        22, FontWeight.w900),
                                  ),
                                  IconButton(
                                    onPressed: () => _shareProduct(context, product.id, product.title),
                                    icon: const Icon(Icons.share_rounded, size: 20),
                                    tooltip: 'Chia sẻ',
                                    color: ProductDetailColors.blue,
                                  ),
                                  AnimatedBuilder(
                                    animation: AppServices.instance.wishlistSession,
                                    builder: (context, _) {
                                      final isFavorite = AppServices.instance
                                          .wishlistSession
                                          .contains(product.id);
                                      return IconButton(
                                        onPressed: () => AppServices.instance
                                            .wishlistSession
                                            .toggle(product.id),
                                        icon: Icon(
                                          isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: isFavorite
                                              ? ProductDetailColors.red
                                              : ProductDetailColors.blue,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _mTxt(state.displayPrice, ProductDetailColors.green, 24,
                                  FontWeight.w900),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _mTxt(
                                    '${product.category} • ${product.stockStatus}',
                                    ProductDetailColors.blue,
                                    12,
                                    FontWeight.w700,
                                  ),
                                  _ratingChip(product.averageRating, product.reviewCount),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _mTxt(product.description,
                                  ProductDetailColors.gray, 12, FontWeight.w500),
                              if (state.isMooncake) ...[
                                const SizedBox(height: 10),
                                _mobileMooncakeConfigurator(context, state),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _mobileCard(
                          child: Row(
                            children: [
                              _qtyBtn('-', state.decreaseQty),
                              Container(
                                width: 48,
                                alignment: Alignment.center,
                                child: _mTxt(
                                    '${state.qty}',
                                    ProductDetailColors.blue,
                                    18,
                                    FontWeight.w900),
                              ),
                              _qtyBtn('+', state.increaseQty),
                              const Spacer(),
                              _mTxt(
                                _formatCurrency(state.total),
                                ProductDetailColors.red,
                                16,
                                FontWeight.w900,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                                child: _cta(
                              'Thêm giỏ',
                              ProductDetailColors.red,
                              onTap: () => _addToCart(context, state),
                            )),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _cta(
                              'Mua ngay',
                              ProductDetailColors.blue,
                              onTap: () => _buyNow(context, state),
                            )),
                          ],
                        ),
                        if (state.isMooncake) ...[
                          const SizedBox(height: 8),
                          _cta(
                            'Mua theo hộp',
                            const Color(0xFF8E44AD),
                            onTap: () => _showMooncakeBoxDialog(context, state),
                          ),
                        ],
                        const SizedBox(height: 8),
                        _mobileCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _mTxt('Mô tả', ProductDetailColors.blue, 14,
                                  FontWeight.w800),
                              const SizedBox(height: 4),
                              _mTxt(
                                _buildDetailedDescription(product),
                                ProductDetailColors.gray,
                                12,
                                FontWeight.w500,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _mobileCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _mTxt('Đánh giá', ProductDetailColors.blue, 14,
                                  FontWeight.w800),
                              const SizedBox(height: 4),
                              if (product.reviews.isEmpty)
                                _mTxt(
                                  'Chưa có đánh giá.',
                                  ProductDetailColors.gray,
                                  12,
                                  FontWeight.w500,
                                )
                              else
                                ...product.reviews.take(2).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _review(item, ProductDetailColors.blue),
                                  ),
                                ),
                              _ctaMini(
                                'Viết đánh giá',
                                ProductDetailColors.blue,
                                onTap: () => _openReviewDialog(context, state),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ProductDetailColors.gray, width: 2),
        ),
        child: child,
      );

  Widget _mobileMooncakeConfigurator(
    BuildContext context,
    ProductDetailState s,
  ) {
    final weightOptions = s.mooncakeConfig?.weightOptions ?? const [];
    final eggOptions = s.availableEggOptions;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5C07B), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _mTxt('Tùy chọn bánh trung thu', ProductDetailColors.blue, 13,
              FontWeight.w900),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weightOptions.map((option) {
              final selected = s.selectedWeightCode == option.code;
              return _mobileOptionChip(
                option.label,
                selected: selected,
                onTap: () => s.selectWeight(option.code),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: eggOptions.map((option) {
              final selected = s.selectedEggCount == option.count;
              return _mobileOptionChip(
                '${option.label} • ${option.price}',
                selected: selected,
                onTap: () => s.selectEggCount(option.count),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _qtyBtn(String text, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ProductDetailColors.gray, width: 2),
          ),
          child: _mTxt(text, ProductDetailColors.blue, 18, FontWeight.w900),
        ),
      );

  Widget _cta(String text, Color bg, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ProductDetailColors.gray, width: 2),
          ),
          child: _mTxt(text, Colors.white, 13, FontWeight.w900),
        ),
      );

  Widget _ctaMini(String text, Color bg, {VoidCallback? onTap}) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ProductDetailColors.gray, width: 2),
          ),
          child: _mTxt(text, Colors.white, 12, FontWeight.w800),
        ),
      );

  Widget _mobileOptionChip(
    String text, {
    required bool selected,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? ProductDetailColors.blue : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? ProductDetailColors.blue : ProductDetailColors.gray,
              width: 2,
            ),
          ),
          child: _mTxt(
            text,
            selected ? Colors.white : ProductDetailColors.gray,
            11,
            FontWeight.w800,
          ),
        ),
      );

  void _addToCart(BuildContext context, ProductDetailState s) {
    final item = s.buildSingleCartItem();
    if (item == null) {
      return;
    }
    AppServices.instance.cartSession.addCartItem(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${item.title} x${item.quantity} vào giỏ hàng'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _buyNow(BuildContext context, ProductDetailState s) {
    _addToCart(context, s);
    context.goNamed(AppRouteNames.checkout);
  }

  Widget _mTxt(String text, Color color, double size, FontWeight fw) => Text(
        text,
        style: TextStyle(color: color, fontSize: size, fontWeight: fw),
      );

  Widget _review(MenuReviewItem review, Color accent) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ProductDetailColors.gray, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _mTxt(review.author, accent, 13, FontWeight.w800),
                const SizedBox(width: 8),
                ...List.generate(
                  5,
                  (index) => Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _mTxt('“${review.content}”', ProductDetailColors.gray, 12, FontWeight.w500),
          ],
        ),
      );

  Widget _ratingChip(double rating, int reviewCount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.shade700, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, size: 14, color: Colors.amber.shade700),
            const SizedBox(width: 4),
            _mTxt(
              rating <= 0 ? 'Mới' : '${rating.toStringAsFixed(1)} ($reviewCount)',
              Colors.amber.shade900,
              11,
              FontWeight.w800,
            ),
          ],
        ),
      );

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

  String _buildDetailedDescription(MenuProduct product) {
    if (product is MenuProductDetail && product.detailBullets.isNotEmpty) {
      return product.detailBullets.map((item) => '• $item').join('\n');
    }
    return '• Danh mục: ${product.category}\n'
        '• ${product.description}\n'
        '• Bộ ảnh sản phẩm gồm ${product.images.length} góc chụp.\n'
        '• Giá niêm yết: ${product.price}.';
  }

  Future<void> _showMooncakeBoxDialog(
    BuildContext context,
    ProductDetailState s,
  ) async {
    await _showMooncakeBoxSelectorDialog(context, s);
  }
}

Future<void> _showMooncakeBoxSelectorDialog(
  BuildContext context,
  ProductDetailState state,
) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          final boxOptions = state.mooncakeConfig?.boxOptions ?? const [];
          final weightOptions = state.mooncakeConfig?.weightOptions ?? const [];
          final selectedBox = state.selectedBoxOption;
          return AlertDialog(
            title: const Text('Mua bánh trung thu theo hộp'),
            content: SizedBox(
              width: 720,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (selectedBox == null) ...[
                      const Text('Chọn loại hộp trước khi cấu hình bánh.'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: boxOptions.map((box) {
                          return GestureDetector(
                            onTap: () {
                              state.prepareBoxSelection(box.code);
                              setDialogState(() {});
                            },
                            child: Container(
                              width: 210,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: ProductDetailColors.blue,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      box.imageUrl,
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    box.label,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Sức chứa ${box.cakeCount} bánh • Phụ phí ${box.packagePrice}',
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(growable: false),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${selectedBox.label} • ${selectedBox.cakeCount} bánh',
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              state.clearBoxSelection();
                              setDialogState(() {});
                            },
                            child: const Text('Đổi hộp'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(selectedBox.cakeCount, (index) {
                        final selection = state.boxSelections[index];
                        final currentWeight = weightOptions
                            .where((item) => item.code == selection.weightCode)
                            .first;
                        final eggOptions = currentWeight.eggOptions;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFD),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFD0D8E4),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bánh ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: selection.weightCode,
                                      decoration: const InputDecoration(
                                        labelText: 'Khối lượng',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: weightOptions
                                          .map(
                                            (item) => DropdownMenuItem(
                                              value: item.code,
                                              child: Text(item.label),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        state.updateBoxSelection(
                                          index,
                                          weightCode: value,
                                        );
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: DropdownButtonFormField<int>(
                                      value: state.boxSelections[index].eggCount,
                                      decoration: const InputDecoration(
                                        labelText: 'Số trứng',
                                        border: OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                      items: eggOptions
                                          .map(
                                            (item) => DropdownMenuItem(
                                              value: item.count,
                                              child: Text(item.label),
                                            ),
                                          )
                                          .toList(growable: false),
                                      onChanged: (value) {
                                        if (value == null) return;
                                        state.updateBoxSelection(
                                          index,
                                          eggCount: value,
                                        );
                                        setDialogState(() {});
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Tạm tính hộp: ${state.formatCurrency(state.selectedBoxTotal)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: ProductDetailColors.red,
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Đóng'),
              ),
              ElevatedButton(
                onPressed: selectedBox == null
                    ? null
                    : () {
                        final item = state.buildBoxCartItem();
                        if (item == null) {
                          return;
                        }
                        AppServices.instance.cartSession.addCartItem(item);
                        Navigator.of(dialogContext).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm ${item.title} vào giỏ hàng'),
                          ),
                        );
                      },
                child: const Text('Thêm hộp vào giỏ'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ProductDetailLoading extends StatelessWidget {
  const _ProductDetailLoading({
    required this.showTopHeader,
    this.mobile = false,
  });

  final bool showTopHeader;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: mobile ? 390 : 1200,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ProductDetailColors.gray, width: 3),
        ),
        child: Column(
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                rightLabel: 'chi tiết sản phẩm',
                showBack: true,
                showBrand: false,
                backFallbackRoute: '/menu',
              ),
            if (showTopHeader) const SizedBox(height: 12),
            Expanded(
              child: Column(
                children: List.generate(
                  mobile ? 4 : 3,
                  (index) => Expanded(
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEFF3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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

Future<void> _openReviewDialog(
  BuildContext context,
  ProductDetailState state,
) async {
  final auth = AppServices.instance.authSession;
  if (!auth.isAuthenticated) {
    context.goNamed(AppRouteNames.login);
    return;
  }
  final contentController = TextEditingController();
  final mediaController = TextEditingController();
  var rating = 5;
  final submitted = await showDialog<MenuReviewDraft>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => AlertDialog(
        title: const Text('Viết đánh giá'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => IconButton(
                    onPressed: () => setModalState(() => rating = index + 1),
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber.shade700,
                    ),
                  ),
                ),
              ),
              TextField(
                controller: contentController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Cảm nhận của bạn',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: mediaController,
                decoration: const InputDecoration(
                  labelText: 'URL ảnh review, cách nhau bởi dấu phẩy',
                ),
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
            onPressed: () => Navigator.of(context).pop(
              MenuReviewDraft(
                rating: rating,
                content: contentController.text.trim(),
                mediaUrls: mediaController.text
                    .split(',')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList(growable: false),
              ),
            ),
            child: const Text('Gửi đánh giá'),
          ),
        ],
      ),
    ),
  );
  if (submitted == null || submitted.content.isEmpty) {
    return;
  }
  final success = await state.submitReview(submitted);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? 'Đã gửi đánh giá của bạn.'
            : (state.errorMessage ?? 'Không thể gửi đánh giá.'),
      ),
    ),
  );
}

class _ProductDetailError extends StatelessWidget {
  const _ProductDetailError({
    required this.showTopHeader,
    required this.message,
    required this.onRetry,
    this.mobile = false,
  });

  final bool showTopHeader;
  final String message;
  final Future<void> Function() onRetry;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: mobile ? 390 : 1200,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: ProductDetailColors.gray, width: 3),
        ),
        child: Column(
          children: [
            if (showTopHeader)
              const PixelHeaderBar(
                rightLabel: 'chi tiết sản phẩm',
                showBack: true,
                showBrand: false,
                backFallbackRoute: '/menu',
              ),
            if (showTopHeader) const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: ProductDetailColors.gray,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => onRetry(),
                      child: Container(
                        width: 120,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: ProductDetailColors.blue,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ProductDetailColors.gray,
                            width: 2,
                          ),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelatedCard extends StatelessWidget {
  final MenuProduct product;
  final Color tone;
  final VoidCallback? onTap;

  const _RelatedCard({
    required this.product,
    required this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ProductDetailColors.gray, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.title,
              style: const TextStyle(
                color: ProductDetailColors.blue,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.price,
              style: const TextStyle(
                color: ProductDetailColors.green,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Share helper ─────────────────────────────────────────────────────────────

void _shareProduct(BuildContext context, int productId, String title) {
  final url = '${Uri.base.origin}${Uri.base.path}#${AppRoutePaths.productDetail}?id=$productId';

  if (kIsWeb) {
    try {
      // Try Web Share API first (mobile browsers)
      final nav = html.window.navigator;
      // ignore: avoid_dynamic_calls
      (nav as dynamic).share({'title': title, 'url': url});
      return;
    } catch (_) {
      // Web Share API not supported — fall through to clipboard
    }
  }

  Clipboard.setData(ClipboardData(text: url));
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Text('Đã sao chép link sản phẩm'),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
