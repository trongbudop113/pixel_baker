import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/models/menu_models.dart';
import '../../app/routing/app_router.dart';
import '../../app/services/app_services.dart';
import '../menu/menu_page.dart';
import '../shared/app_header.dart';
import '../shared/pixel_footer.dart';

class ResponsiveCompareScreen extends StatefulWidget {
  const ResponsiveCompareScreen({
    super.key,
    required this.productIds,
    this.showTopHeader = true,
  });

  final List<int> productIds;
  final bool showTopHeader;

  @override
  State<ResponsiveCompareScreen> createState() =>
      _ResponsiveCompareScreenState();
}

class _ResponsiveCompareScreenState extends State<ResponsiveCompareScreen> {
  List<MenuProduct?> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    if (widget.productIds.isEmpty) {
      setState(() {
        _isLoading = false;
        _products = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait(
        widget.productIds.map(
          (id) => AppServices.instance.menuRepository.fetchProductById(id),
        ),
      );
      if (mounted) {
        setState(() {
          _products = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Không tải được dữ liệu sản phẩm.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final validProducts =
        _products.whereType<MenuProduct>().toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isNarrow = width < 900;
        return Container(
          width: double.infinity,
          height: double.infinity,
          padding: EdgeInsets.all(isNarrow ? 12 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: MenuColors.gray, width: 3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showTopHeader) ...[
                const PixelHeaderBar(
                  rightLabel: 'so sánh',
                  showBack: true,
                  showBrand: false,
                  backFallbackRoute: '/menu',
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(isNarrow),
                      const SizedBox(height: 16),
                      if (_isLoading)
                        _buildLoading()
                      else if (_errorMessage != null)
                        _buildError()
                      else if (validProducts.isEmpty)
                        _buildEmpty(context)
                      else if (isNarrow)
                        _buildMobileLayout(context, validProducts)
                      else
                        _buildDesktopLayout(context, validProducts),
                      const SizedBox(height: 16),
                      PixelFooter(
                        label: 'PIXEL BAKERY | SO SÁNH',
                        mobile: isNarrow,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 14,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MenuColors.gray, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'So sánh sản phẩm',
            style: TextStyle(
              color: MenuColors.blue,
              fontSize: isMobile ? 20 : 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Xem xét chi tiết từng sản phẩm để chọn loại bánh phù hợp nhất.',
            style: TextStyle(
              color: MenuColors.gray,
              fontSize: isMobile ? 11 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(48),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MenuColors.gray, width: 2),
      ),
      child: Column(
        children: [
          Text(
            _errorMessage ?? 'Có lỗi xảy ra.',
            style: const TextStyle(color: MenuColors.gray, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _loadProducts,
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

  Widget _buildEmpty(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MenuColors.gray, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.compare_arrows, size: 48, color: MenuColors.gray),
          const SizedBox(height: 16),
          const Text(
            'Chưa có sản phẩm nào để so sánh.',
            style: TextStyle(
              color: MenuColors.gray,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Hãy vào thực đơn, chọn 2-3 sản phẩm rồi bấm "So sánh".',
            style: TextStyle(
              color: MenuColors.gray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.goNamed(AppRouteNames.menu),
            child: Container(
              width: 140,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MenuColors.blue,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: MenuColors.gray, width: 2),
              ),
              child: const Text(
                'Xem thực đơn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Desktop: side-by-side table ─────────────────────────────────────────

  Widget _buildDesktopLayout(
      BuildContext context, List<MenuProduct> products) {
    const rowLabels = [
      'Ảnh',
      'Tên',
      'Giá',
      'Danh mục',
      'Đánh giá',
      'Mô tả',
      '',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MenuColors.gray, width: 2),
      ),
      child: Table(
        columnWidths: {
          0: const FixedColumnWidth(110),
          for (var i = 1; i <= products.length; i++)
            i: const FlexColumnWidth(1),
        },
        border: TableBorder.all(color: const Color(0xFFDDE4EE), width: 1),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: List.generate(rowLabels.length, (rowIdx) {
          return TableRow(
            decoration: BoxDecoration(
              color: rowIdx.isEven ? const Color(0xFFF8FBFF) : Colors.white,
            ),
            children: [
              // Label column
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                child: Text(
                  rowLabels[rowIdx],
                  style: const TextStyle(
                    color: MenuColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              // Product columns
              ...products.map(
                (p) => _desktopCell(context, p, rowIdx),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _desktopCell(BuildContext context, MenuProduct p, int rowIdx) {
    switch (rowIdx) {
      case 0: // Image
        return Padding(
          padding: const EdgeInsets.all(10),
          child: _ProductImage(
            imageUrl: p.images.isEmpty ? null : p.images.first,
            tone: _toneFor(p),
            height: 140,
          ),
        );
      case 1: // Name
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: GestureDetector(
            onTap: () =>
                context.go('${AppRoutePaths.productDetail}?id=${p.id}'),
            child: Text(
              p.title,
              style: TextStyle(
                color: _accentFor(p),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      case 2: // Price
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            p.price,
            style: const TextStyle(
              color: MenuColors.green,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case 3: // Category
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _toneFor(p),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _accentFor(p).withOpacity(0.4)),
            ),
            child: Text(
              p.category,
              style: TextStyle(
                color: _accentFor(p),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      case 4: // Rating
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: _RatingRow(
            rating: p.averageRating,
            count: p.reviewCount,
          ),
        );
      case 5: // Description
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Text(
            _truncate(p.description, 100),
            style: const TextStyle(
              color: Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      case 6: // Add to cart button
        return Padding(
          padding: const EdgeInsets.all(10),
          child: _AddToCartButton(
            onTap: () => _addToCart(context, p),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Mobile: scrollable cards ─────────────────────────────────────────────

  Widget _buildMobileLayout(BuildContext context, List<MenuProduct> products) {
    return Column(
      children: products
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MobileProductCard(
                  product: p,
                  onAddToCart: () => _addToCart(context, p),
                  onTap: () =>
                      context.go('${AppRoutePaths.productDetail}?id=${p.id}'),
                ),
              ))
          .toList(growable: false),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _addToCart(BuildContext context, MenuProduct product) {
    AppServices.instance.cartSession.addProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${product.title} vào giỏ hàng'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  Color _toneFor(MenuProduct p) {
    if (p.category == 'Cookie') return const Color(0xFFFFF1F1);
    if (p.category == 'Combo') return const Color(0xFFF1FAF1);
    return const Color(0xFFEAF3FF);
  }

  Color _accentFor(MenuProduct p) {
    if (p.category == 'Cookie') return MenuColors.red;
    if (p.category == 'Combo') return MenuColors.green;
    return MenuColors.blue;
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _ProductImage extends StatelessWidget {
  const _ProductImage({
    required this.imageUrl,
    required this.tone,
    this.height = 120,
  });

  final String? imageUrl;
  final Color tone;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MenuColors.gray, width: 1.5),
        image: imageUrl == null
            ? null
            : DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.count});

  final double rating;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 14, color: Colors.amber.shade700),
        const SizedBox(width: 4),
        Text(
          rating <= 0 ? 'Mới' : rating.toStringAsFixed(1),
          style: const TextStyle(
            color: MenuColors.blue,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '($count)',
          style: const TextStyle(
            color: MenuColors.gray,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AddToCartButton extends StatelessWidget {
  const _AddToCartButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: MenuColors.red,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: MenuColors.gray, width: 2),
        ),
        child: const Text(
          'Thêm vào giỏ',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MobileProductCard extends StatelessWidget {
  const _MobileProductCard({
    required this.product,
    required this.onAddToCart,
    required this.onTap,
  });

  final MenuProduct product;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  Color get _tone {
    if (product.category == 'Cookie') return const Color(0xFFFFF1F1);
    if (product.category == 'Combo') return const Color(0xFFF1FAF1);
    return const Color(0xFFEAF3FF);
  }

  Color get _accent {
    if (product.category == 'Cookie') return MenuColors.red;
    if (product.category == 'Combo') return MenuColors.green;
    return MenuColors.blue;
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: MenuColors.gray, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProductImage(
              imageUrl: product.images.isEmpty ? null : product.images.first,
              tone: _tone,
              height: 140,
            ),
            const SizedBox(height: 10),
            Text(
              product.title,
              style: TextStyle(
                color: _accent,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            _buildInfoRow('Giá', product.price,
                valueStyle: const TextStyle(
                  color: MenuColors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                )),
            const SizedBox(height: 4),
            _buildInfoRow('Danh mục', product.category),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Đánh giá',
                    style: TextStyle(
                      color: MenuColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _RatingRow(
                    rating: product.averageRating, count: product.reviewCount),
              ],
            ),
            const SizedBox(height: 4),
            _buildInfoRow('Mô tả', _truncate(product.description, 100)),
            const SizedBox(height: 10),
            _AddToCartButton(onTap: onAddToCart),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              color: MenuColors.blue,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: valueStyle ??
                const TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

