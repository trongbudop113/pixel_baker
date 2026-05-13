import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/models/home_models.dart';
import '../../app/models/ui_accent.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';
import '../../app/routing/app_router.dart';
import '../shared/app_header.dart';
import '../shared/back_to_top_button.dart';
import '../shared/shimmer_box.dart';
import 'home_state.dart';

class AppColors {
  static const red = Color(0xFFE53935);
  static const blue = Color(0xFF1E88E5);
  static const green = Color(0xFF2E7D32);
  static const gray = Color(0xFF8A8A8A);
}

Color colorForAccent(UiAccent accent) {
  switch (accent) {
    case UiAccent.red:
      return AppColors.red;
    case UiAccent.blue:
      return AppColors.blue;
    case UiAccent.green:
      return AppColors.green;
    case UiAccent.gray:
      return AppColors.gray;
    case UiAccent.orange:
      return const Color(0xFFD97706);
  }
}

class ResponsiveHomeScreen extends StatefulWidget {
  const ResponsiveHomeScreen({super.key, this.showTopHeader = true});

  final bool showTopHeader;

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  final HomeState _homeState = HomeState();
  final TextEditingController _testimonialController = TextEditingController();
  late final ScrollController _webScrollController;
  late final ScrollController _mobileScrollController;

  @override
  void initState() {
    super.initState();
    _homeState.load();
    _webScrollController =
        ScrollController(initialScrollOffset: HomeState.webScrollOffset)
          ..addListener(() {
            HomeState.saveWebScrollOffset(_webScrollController.offset);
          });
    _mobileScrollController =
        ScrollController(initialScrollOffset: HomeState.mobileScrollOffset)
          ..addListener(() {
            HomeState.saveMobileScrollOffset(_mobileScrollController.offset);
          });
  }

  @override
  void dispose() {
    _homeState.dispose();
    _testimonialController.dispose();
    _webScrollController.dispose();
    _mobileScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ControllerEffectListener<HomeState, HomeNavigationTarget>(
      controller: _homeState,
      listener: _handleHomeNavigation,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          if (width >= 900) {
            return HomeWebLayout(
              state: _homeState,
              showTopHeader: widget.showTopHeader,
              scrollController: _webScrollController,
              testimonialController: _testimonialController,
            );
          }
          return HomeMobileLayout(
            state: _homeState,
            showTopHeader: widget.showTopHeader,
            scrollController: _mobileScrollController,
            testimonialController: _testimonialController,
            isTablet: width >= 600,
          );
        },
      ),
    );
  }

  void _handleHomeNavigation(
    BuildContext context,
    HomeNavigationTarget target,
  ) {
    switch (target) {
      case HomeNavigationTarget.profile:
        context.goNamed(AppRouteNames.profile);
        break;
      case HomeNavigationTarget.checkout:
        context.goNamed(AppRouteNames.checkout);
        break;
      case HomeNavigationTarget.menu:
        context.goNamed(AppRouteNames.menu);
        break;
      case HomeNavigationTarget.voucher:
        context.goNamed(AppRouteNames.voucher);
        break;
      case HomeNavigationTarget.contact:
        context.goNamed(AppRouteNames.contact);
        break;
      case HomeNavigationTarget.login:
        context.goNamed(AppRouteNames.login);
        break;
      case HomeNavigationTarget.admin:
        context.goNamed(AppRouteNames.admin);
        break;
    }
  }
}

class HomeWebLayout extends StatelessWidget {
  final HomeState state;
  final bool showTopHeader;
  final ScrollController scrollController;
  final TextEditingController testimonialController;
  const HomeWebLayout({
    super.key,
    required this.state,
    required this.scrollController,
    required this.testimonialController,
    this.showTopHeader = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1200,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopHeader) _header(context),
            if (showTopHeader) const SizedBox(height: 20),
            Expanded(
              child: Stack(
                children: [
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _statusBanner(),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _hero(context),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _infoRow(),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _txt('BÁNH BÁN CHẠY', AppColors.blue, 16, FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _productCards(context),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _storyBlock(context),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _menuCategory(context),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _testimonial(context),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _promoBanner(context),
                    ),
                    const SizedBox(height: 20),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _faq(),
                    ),
                    const SizedBox(height: 20),
                    _footer(context),
                  ],
                ),
              ),
              BackToTopButton(scrollController: scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
      );
  }

  Widget _statusBanner() => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          if (state.errorMessage case final message?) {
            return _messageBanner(message, AppColors.red);
          }
          if (state.isLoading) {
            return _messageBanner('Đang đồng bộ dữ liệu trang chủ...', AppColors.blue);
          }
          return const SizedBox.shrink();
        },
      );

  Widget _header(BuildContext context) => Container(
        child: PixelHeaderBar(
          rightLabel: 'giỏ hàng',
          centerLabel: 'tiệm bánh arcade | mở cửa 08:00 - 21:30',
          rightWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: state.openProfile,
                child: _profileIcon(),
              ),
              const SizedBox(width: 6),
              _button(
                'giỏ hàng',
                AppColors.red,
                88,
                20,
                9,
                FontWeight.w900,
                radius: 12,
                onTap: state.openCheckout,
              ),
            ],
          ),
        ),
      );

  Widget _hero(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final hero = state.pageResponse.hero;
          return SizedBox(
            height: 360,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        border: Border.all(color: AppColors.gray, width: 2)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _txt(hero.title, AppColors.blue, 34, FontWeight.w800, 1.08),
                        const SizedBox(height: 14),
                        _txt(hero.description, AppColors.gray, 30, FontWeight.w500),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _button(
                              hero.primaryAction.label,
                              AppColors.red,
                              190,
                              48,
                              11,
                              FontWeight.w700,
                              onTap: () => _openActionLink(context, hero.primaryAction),
                            ),
                            const SizedBox(width: 10),
                            _button(
                              hero.secondaryAction.label,
                              AppColors.green,
                              140,
                              48,
                              11,
                              FontWeight.w700,
                              onTap: () => _openActionLink(context, hero.secondaryAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Container(
                  width: 360,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Color(0xFFEAF3FF), Color(0xFFF1FAF1)],
                    ),
                    border: Border.all(color: AppColors.gray, width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 190,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.gray, width: 3),
                        ),
                        child: Stack(
                          children: [
                            _shape(20, 22, 100, 60, AppColors.red),
                            _shape(128, 22, 100, 60, AppColors.blue),
                            Positioned(
                                left: 28,
                                top: 98,
                                child: Container(
                                    width: 86, height: 68, color: AppColors.gray)),
                            _circle(148, 108, AppColors.green),
                            _circle(190, 108, AppColors.red),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.gray, width: 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _button('X', AppColors.red, 54, 28, 14, FontWeight.w900,
                                radius: 14),
                            const SizedBox(width: 10),
                            _button('O', AppColors.blue, 54, 28, 14, FontWeight.w900,
                                radius: 14),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );

  Widget _infoRow() => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final highlights = state.pageResponse.highlights;
          if (highlights.isEmpty) {
            return const SizedBox.shrink();
          }

          return Row(
            children: List.generate(highlights.length * 2 - 1, (index) {
              if (index.isOdd) {
                return const SizedBox(width: 12);
              }
              final item = highlights[index ~/ 2];
              return Expanded(
                child: _infoItem(
                  item.title,
                  item.description,
                  colorForAccent(item.accent),
                ),
              );
            }),
          );
        },
      );

  Widget _productCards(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          if (state.isLoading) {
            return const _HomeProductSkeleton();
          }
          final products = state.pageResponse.featuredProducts.take(3).toList(growable: false);
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }

          return SizedBox(
            height: 270,
            child: Row(
              children: List.generate(products.length * 2 - 1, (index) {
                if (index.isOdd) {
                  return const SizedBox(width: 16);
                }
                final product = products[index ~/ 2];
                return Expanded(
                  child: _productCard(
                    context,
                    product,
                    onTap: () => context.go(
                      '${AppRoutePaths.productDetail}?id=${product.productId}',
                    ),
                    onAddToCart: () => _addFeaturedProductToCart(context, product),
                  ),
                );
              }),
            ),
          );
        },
      );

  Widget _storyBlock(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final story = state.pageResponse.story;
          return SizedBox(
            height: 170,
            child: GestureDetector(
              onTap: () => context.goNamed(AppRouteNames.story),
              child: Row(
                children: [
                  Expanded(
                    child: _box(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _txt(story.title, AppColors.blue, 18, FontWeight.w800),
                          const SizedBox(height: 6),
                          _txt(
                            story.description,
                            AppColors.gray,
                            14,
                            FontWeight.w500,
                            1.3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 320,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFEAF3FF), Color(0xFFF1FAF1)]),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.gray, width: 2),
                    ),
                    child: _txt(story.badgeText, AppColors.red, 18, FontWeight.w800),
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _menuCategory(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt('Danh mục nổi bật', AppColors.blue, 18, FontWeight.w800),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              final categories = state.categories;
              return SizedBox(
                height: 112,
                child: Row(
                  children: List.generate(categories.length * 2 - 1, (i) {
                    if (i.isOdd) return const SizedBox(width: 10);
                    final index = i ~/ 2;
                    final category = categories[index];
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          state.selectCategory(index);
                          context.go(
                            '${AppRoutePaths.menu}?category=${category.routeCategory}',
                          );
                        },
                        child: _category(
                          category.label,
                          colorForAccent(category.accent),
                          selected: state.selectedCategoryIndex == index,
                        ),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      );

  Widget _testimonial(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final testimonials = state.testimonials;
          if (testimonials.isEmpty) {
            return const SizedBox.shrink();
          }
          final active = state.selectedTestimonialIndex % testimonials.length;
          final item = testimonials[active];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _txt('Khách hàng nói gì', AppColors.blue, 18, FontWeight.w800),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: Row(
                  children: [
                    Expanded(
                      child: _review(
                        item.content,
                        item.author,
                        colorForAccent(item.accent),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 120,
                      child: Column(
                        children: [
                          Expanded(
                            child: _button(
                              'Prev',
                              AppColors.gray,
                              double.infinity,
                              44,
                              12,
                              FontWeight.w700,
                              onTap: () => state.selectTestimonial(
                                  (active - 1 + testimonials.length) %
                                      testimonials.length),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _button(
                              'Next',
                              AppColors.blue,
                              double.infinity,
                              44,
                              12,
                              FontWeight.w700,
                              onTap: () => state.selectTestimonial(
                                  (active + 1) % testimonials.length),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _testimonialComposer(context),
            ],
          );
        },
      );

  Widget _testimonialComposer(BuildContext context) => _box(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt('Viết đánh giá', AppColors.blue, 16, FontWeight.w800),
            const SizedBox(height: 8),
            TextField(
              controller: testimonialController,
              minLines: 3,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Chia sẻ cảm nhận của bạn về Pixel Bakery...',
                hintStyle: const TextStyle(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            if (state.testimonialMessage != null) ...[
              const SizedBox(height: 8),
              _txt(
                state.testimonialMessage!,
                state.isTestimonialSuccess ? AppColors.green : AppColors.red,
                12,
                FontWeight.w700,
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: _button(
                state.isSubmittingTestimonial ? 'ĐANG GỬI...' : 'Gửi đánh giá',
                AppColors.red,
                140,
                40,
                13,
                FontWeight.w800,
                onTap: () async {
                  await state.submitTestimonial(testimonialController.text);
                  if (state.isTestimonialSuccess) {
                    testimonialController.clear();
                  }
                },
              ),
            ),
          ],
        ),
      );

  Widget _promoBanner(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final promo = state.pageResponse.promo;
          return Container(
            height: 68,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [Color(0xFFEAF3FF), Colors.white]),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.gray, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _txt(promo.message, AppColors.green, 16, FontWeight.w800),
                _button(
                  promo.action.label,
                  AppColors.red,
                  140,
                  40,
                  14,
                  FontWeight.w800,
                  onTap: () => _openActionLink(context, promo.action),
                ),
              ],
            ),
          );
        },
      );

  Widget _faq() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt('FAQ nhanh', AppColors.blue, 18, FontWeight.w800),
          const SizedBox(height: 10),
          AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              final faqs = state.faqs;
              return Column(
                children: List.generate(faqs.length * 2 - 1, (i) {
                  if (i.isOdd) return const SizedBox(height: 8);
                  final index = i ~/ 2;
                  final expanded = state.expandedFaqIndex == index;
                  final faq = faqs[index];
                  return GestureDetector(
                    onTap: () => state.toggleFaq(index),
                    child: _faqItem(
                      faq.question,
                      faq.answer,
                      colorForAccent(faq.accent),
                      expanded,
                    ),
                  );
                }),
              );
            },
          ),
        ],
      );

  Widget _footer(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final footer = state.pageResponse.footer;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              border: Border.all(color: AppColors.gray, width: 2),
            ),
            child: Column(
              children: [
                _txt(footer.tagline, AppColors.gray, 10, FontWeight.w600),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(footer.links.length * 2 - 1, (index) {
                    if (index.isOdd) {
                      return const SizedBox(width: 18);
                    }
                    final link = footer.links[index ~/ 2];
                    return GestureDetector(
                      onTap: () => _openActionLink(context, link),
                      child: _txt(link.label, AppColors.blue, 12, FontWeight.w700),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      );

  void _openActionLink(BuildContext context, HomeActionLink link) {
    if (link.routeName case final routeName?) {
      context.goNamed(routeName, queryParameters: link.queryParameters);
      return;
    }
    if (link.routePath case final routePath?) {
      final uri = Uri(path: routePath, queryParameters: link.queryParameters.isEmpty ? null : link.queryParameters);
      context.go(uri.toString());
    }
  }

  Widget _messageBanner(String message, Color accentColor) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accentColor, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: _txt(message, AppColors.gray, 13, FontWeight.w600)),
          ],
        ),
      );

  Widget _infoItem(String title, String sub, Color titleColor) => _box(
        height: 96,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(title, titleColor, 16, FontWeight.w800),
            const SizedBox(height: 4),
            _txt(sub, AppColors.gray, 13, FontWeight.w500),
          ],
        ),
      );

  Widget _productCard(
    BuildContext context,
    HomeFeaturedProduct product, {
    VoidCallback? onTap,
    VoidCallback? onAddToCart,
  }) =>
      AnimatedBuilder(
        animation: Listenable.merge([
          AppServices.instance.cartSession,
          AppServices.instance.wishlistSession,
        ]),
        builder: (context, _) {
          final quantity = AppServices.instance.cartSession
              .quantityForProduct(product.productId);
          final isFavorite = AppServices.instance.wishlistSession
              .contains(product.productId);
          return GestureDetector(
            onTap: onTap,
            child: _box(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          height: 130,
                          decoration: BoxDecoration(
                              border: Border.all(color: AppColors.gray, width: 2)),
                          child: Image.network(product.imageUrl,
                              fit: BoxFit.cover, width: double.infinity),
                        ),
                      ),
                      if (quantity > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _cartQuantityBadge(quantity),
                        ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () => AppServices.instance.wishlistSession
                              .toggle(product.productId),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.gray,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.red
                                  : AppColors.blue,
                              size: 17,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _txt(
                              product.title,
                              colorForAccent(product.titleAccent),
                              12,
                              FontWeight.w700,
                            ),
                            _txt(
                              product.price,
                              colorForAccent(product.priceAccent),
                              30,
                              FontWeight.w700,
                            ),
                            const SizedBox(height: 4),
                            _ratingChip(
                              product.averageRating,
                              product.reviewCount,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.gray, width: 2),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

  void _addFeaturedProductToCart(
    BuildContext context,
    HomeFeaturedProduct product,
  ) {
    AppServices.instance.cartSession.addFeaturedProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${product.title} vào giỏ hàng.'),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Widget _cartQuantityBadge(int quantity) => Container(
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _txt(
          'x$quantity',
          Colors.white,
          11,
          FontWeight.w900,
        ),
      );

  Widget _ratingChip(double averageRating, int reviewCount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gray, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 14,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 4),
            _txt(
              averageRating <= 0
                  ? 'Mới'
                  : '${averageRating.toStringAsFixed(1)} · $reviewCount',
              AppColors.gray,
              11,
              FontWeight.w700,
            ),
          ],
        ),
      );

  Widget _category(String text, Color color, {bool selected = false}) =>
      Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: selected ? color : AppColors.gray, width: 2),
        ),
        child: Center(child: _txt(text, color, 16, FontWeight.w700)),
      );

  Widget _review(String content, String author, Color authorColor) => _box(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(content, AppColors.gray, 14, FontWeight.w500),
            const SizedBox(height: 4),
            _txt(author, authorColor, 13, FontWeight.w700),
          ],
        ),
      );

  Widget _faqItem(String q, String a, Color qColor, bool expanded) => _box(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _txt(q, qColor, 14, FontWeight.w700)),
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: expanded ? const Color(0xFFEAF3FF) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.gray, width: 1.5),
                  ),
                  child: _txt(expanded ? '-' : '+', AppColors.blue, 14,
                      FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            _txt(
              expanded ? a : 'Nhấn để xem chi tiết',
              AppColors.gray,
              13,
              FontWeight.w500,
              1.3,
            ),
          ],
        ),
      );

  Widget _button(
    String text,
    Color bg,
    double width,
    double height,
    double fontSize,
    FontWeight fw, {
    double radius = 6,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border:
                Border.all(color: AppColors.gray, width: radius > 10 ? 1 : 2),
          ),
          child: _txt(text, Colors.white, fontSize, fw),
        ),
      );

  Widget _profileIcon() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gray, width: 2),
        ),
        child: const Icon(Icons.person, size: 12, color: AppColors.blue),
      );

  Widget _shape(double l, double t, double w, double h, Color c) => Positioned(
        left: l,
        top: t,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
              color: c, border: Border.all(color: AppColors.gray, width: 2)),
        ),
      );

  Widget _circle(double l, double t, Color c) => Positioned(
        left: l,
        top: t,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c,
              border: Border.all(color: AppColors.gray, width: 2)),
        ),
      );

  Widget _box({Widget? child, EdgeInsetsGeometry? padding, double? height}) =>
      Container(
        height: height,
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.gray, width: 2),
        ),
        child: child,
      );

  Widget _txt(String text, Color color, double size, FontWeight weight,
          [double? lineHeight]) =>
      Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            height: lineHeight),
      );
}

class HomeMobileLayout extends StatelessWidget {
  final HomeState state;
  final bool showTopHeader;
  final ScrollController scrollController;
  final TextEditingController testimonialController;
  final bool isTablet;
  const HomeMobileLayout({
    super.key,
    required this.state,
    required this.scrollController,
    required this.testimonialController,
    this.showTopHeader = true,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isTablet ? 900 : 390,
      height: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray, width: 3),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showTopHeader) _header(context),
            if (showTopHeader) const SizedBox(height: 12),
            Expanded(
              child: Stack(
                children: [
              SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _statusBanner(),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _hero(context),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _benefit(),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _products(context),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _story(context),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _cat(context),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _reviewSection(context),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _promo(context),
                    ),
                    const SizedBox(height: 12),
                    _ScrollRevealSection(
                      scrollController: scrollController,
                      child: _faq(),
                    ),
                    const SizedBox(height: 12),
                    _footer(context),
                  ],
                ),
              ),
              BackToTopButton(scrollController: scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
      );
  }

  Widget _statusBanner() => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          if (state.errorMessage case final message?) {
            return _messageBanner(message, AppColors.red);
          }
          if (state.isLoading) {
            return _messageBanner('Đang đồng bộ dữ liệu trang chủ...', AppColors.blue);
          }
          return const SizedBox.shrink();
        },
      );

  Widget _header(BuildContext context) => Container(
        child: PixelHeaderBar(
          rightLabel: 'giỏ hàng',
          rightWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: state.openProfile,
                child: _profileIcon(),
              ),
              const SizedBox(width: 6),
              _button(
                'giỏ hàng',
                AppColors.red,
                76,
                20,
                9,
                FontWeight.w900,
                radius: 12,
                border: 1,
                onTap: state.openCheckout,
              ),
            ],
          ),
        ),
      );

  Widget _hero(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final hero = state.pageResponse.hero;
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFEAF3FF), Color(0xFFF1FAF1)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gray, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _txt(hero.title, AppColors.blue, 24, FontWeight.w800, 1.08),
                const SizedBox(height: 8),
                _txt(hero.description, AppColors.gray, 14, FontWeight.w500, 1.2),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _button(
                        hero.primaryAction.label,
                        AppColors.blue,
                        double.infinity,
                        44,
                        13,
                        FontWeight.w800,
                        onTap: () => _openActionLink(context, hero.primaryAction),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _button(
                        hero.secondaryAction.label,
                        AppColors.red,
                        double.infinity,
                        44,
                        14,
                        FontWeight.w800,
                        onTap: () => _openActionLink(context, hero.secondaryAction),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Widget _benefit() => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final highlights = state.pageResponse.highlights.take(2).toList(growable: false);
          if (highlights.isEmpty) {
            return const SizedBox.shrink();
          }
          return Column(
            children: List.generate(highlights.length * 2 - 1, (index) {
              if (index.isOdd) {
                return const SizedBox(height: 8);
              }
              final item = highlights[index ~/ 2];
              return _tile(
                item.title,
                item.description,
                colorForAccent(item.accent),
              );
            }),
          );
        },
      );

  Widget _products(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          if (state.isLoading) {
            return _HomeProductSkeleton(mobile: !isTablet);
          }
          final count = isTablet ? 4 : 2;
          final products = state.pageResponse.featuredProducts.take(count).toList(growable: false);
          if (products.isEmpty) {
            return const SizedBox.shrink();
          }
          if (isTablet) {
            // 2-column grid for tablet
            final rows = <Widget>[];
            for (var i = 0; i < products.length; i += 2) {
              final rowItems = products.skip(i).take(2).toList();
              rows.add(Row(children: List.generate(rowItems.length * 2 - 1, (idx) {
                if (idx.isOdd) return const SizedBox(width: 10);
                final p = rowItems[idx ~/ 2];
                return Expanded(child: _productLite(context, p,
                  idx.isEven ? const Color(0xFFEAF3FF) : const Color(0xFFF1FAF1),
                  onTap: (ctx) => ctx.go('${AppRoutePaths.productDetail}?id=${p.productId}'),
                  onAddToCart: () => _addFeaturedProductToCart(context, p),
                ));
              })));
              if (i + 2 < products.length) rows.add(const SizedBox(height: 8));
            }
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _txt('BÁNH BÁN CHẠY', AppColors.blue, 15, FontWeight.w800),
              const SizedBox(height: 8),
              ...rows,
            ]);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _txt('BÁNH BÁN CHẠY', AppColors.blue, 15, FontWeight.w800),
              const SizedBox(height: 8),
              ...List.generate(products.length, (index) {
                final product = products[index];
                return Padding(
                  padding: EdgeInsets.only(bottom: index == products.length - 1 ? 0 : 8),
                  child: _productLite(
                    context,
                    product,
                    index.isEven ? const Color(0xFFEAF3FF) : const Color(0xFFF1FAF1),
                    onTap: (context) => context.go(
                      '${AppRoutePaths.productDetail}?id=${product.productId}',
                    ),
                    onAddToCart: () => _addFeaturedProductToCart(context, product),
                  ),
                );
              }),
            ],
          );
        },
      );

  Widget _story(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final story = state.pageResponse.story;
          return GestureDetector(
            onTap: () => context.goNamed(AppRouteNames.story),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: _boxDec(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _txt(story.title, AppColors.blue, 16, FontWeight.w800),
                  const SizedBox(height: 6),
                  _txt(
                    story.description,
                    AppColors.gray,
                    13,
                    FontWeight.w500,
                    1.25,
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _cat(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _txt('Danh mục nổi bật', AppColors.blue, 16, FontWeight.w800),
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: state,
            builder: (context, _) {
              final categories = state.mobileCategories;
              if (categories.length < 2) {
                return const SizedBox.shrink();
              }
              return Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        state.selectCategory(0);
                        context.go(
                          '${AppRoutePaths.menu}?category=${categories[0].routeCategory}',
                        );
                      },
                      child: _catItem(categories[0].label,
                          colorForAccent(categories[0].accent),
                          selected: state.selectedCategoryIndex == 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        state.selectCategory(1);
                        context.go(
                          '${AppRoutePaths.menu}?category=${categories[1].routeCategory}',
                        );
                      },
                      child: _catItem(categories[1].label,
                          colorForAccent(categories[1].accent),
                          selected: state.selectedCategoryIndex == 1),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      );

  Widget _reviewSection(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final testimonials = state.mobileTestimonials;
          if (testimonials.isEmpty) {
            return const SizedBox.shrink();
          }
          final active = state.selectedTestimonialIndex % testimonials.length;
          final item = testimonials[active];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _txt('Khách hàng nói gì', AppColors.blue, 16, FontWeight.w800),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: _boxDec(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _txt(item.content, AppColors.gray, 13, FontWeight.w500),
                    const SizedBox(height: 4),
                    _txt(
                      item.author,
                      colorForAccent(item.accent),
                      12,
                      FontWeight.w700,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _button(
                      'Prev',
                      AppColors.gray,
                      double.infinity,
                      36,
                      11,
                      FontWeight.w700,
                      border: 1,
                      onTap: () => state.selectTestimonial(
                          (active - 1 + testimonials.length) %
                              testimonials.length),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _button(
                      'Next',
                      AppColors.blue,
                      double.infinity,
                      36,
                      11,
                      FontWeight.w700,
                      border: 1,
                      onTap: () => state.selectTestimonial(
                          (active + 1) % testimonials.length),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: _boxDec(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _txt('Viết đánh giá', AppColors.blue, 14, FontWeight.w800),
                    const SizedBox(height: 8),
                    TextField(
                      controller: testimonialController,
                      minLines: 3,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Chia sẻ cảm nhận của bạn...',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(10),
                      ),
                    ),
                    if (state.testimonialMessage != null) ...[
                      const SizedBox(height: 8),
                      _txt(
                        state.testimonialMessage!,
                        state.isTestimonialSuccess
                            ? AppColors.green
                            : AppColors.red,
                        11,
                        FontWeight.w700,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _button(
                        state.isSubmittingTestimonial
                            ? 'ĐANG GỬI...'
                            : 'Gửi đánh giá',
                        AppColors.red,
                        112,
                        34,
                        11,
                        FontWeight.w800,
                        border: 1,
                        onTap: () async {
                          await state.submitTestimonial(
                            testimonialController.text,
                          );
                          if (state.isTestimonialSuccess) {
                            testimonialController.clear();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );

  Widget _promo(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final promo = state.pageResponse.promo;
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient:
                  const LinearGradient(colors: [Color(0xFFEAF3FF), Colors.white]),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.gray, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _txt(promo.message, AppColors.green, 13, FontWeight.w800),
                ),
                _button(
                  promo.action.label,
                  AppColors.red,
                  88,
                  32,
                  11,
                  FontWeight.w800,
                  border: 1,
                  onTap: () => _openActionLink(context, promo.action),
                ),
              ],
            ),
          );
        },
      );

  Widget _faq() => Builder(builder: (ctx) => Container(
        padding: const EdgeInsets.all(10),
        decoration: _boxDec(ctx),
        child: AnimatedBuilder(
          animation: state,
          builder: (context, _) {
            final faqs = state.mobileFaqs;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _txt('FAQ nhanh', AppColors.blue, 16, FontWeight.w800),
                const SizedBox(height: 6),
                ...List.generate(faqs.length, (index) {
                  final expanded = state.expandedFaqIndex == index;
                  final faq = faqs[index];
                  return GestureDetector(
                    onTap: () => state.toggleFaq(index),
                    child: Padding(
                      padding: EdgeInsets.only(
                          bottom: index == faqs.length - 1 ? 0 : 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color:
                              expanded ? const Color(0xFFEAF3FF) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.gray, width: 1.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _txt(
                                    faq.question,
                                    colorForAccent(faq.accent),
                                    12,
                                    FontWeight.w700,
                                  ),
                                ),
                                _txt(expanded ? '-' : '+', AppColors.blue, 13,
                                    FontWeight.w900),
                              ],
                            ),
                            const SizedBox(height: 4),
                            _txt(
                              expanded ? faq.answer : 'Nhấn để xem chi tiết',
                              AppColors.gray,
                              11,
                              FontWeight.w500,
                              1.25,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      );

  Widget _footer(BuildContext context) => AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final footer = state.pageResponse.footer;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              border: Border.all(color: AppColors.gray, width: 2),
            ),
            child: Column(
              children: [
                Center(
                  child: _txt(footer.tagline, AppColors.gray, 9, FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ...List.generate(footer.links.length, (index) {
                  final link = footer.links[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == footer.links.length - 1 ? 0 : 5),
                    child: GestureDetector(
                      onTap: () => _openActionLink(context, link),
                      child: _txt(link.label, AppColors.blue, 12, FontWeight.w700),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      );

  void _openActionLink(BuildContext context, HomeActionLink link) {
    if (link.routeName case final routeName?) {
      context.goNamed(routeName, queryParameters: link.queryParameters);
      return;
    }
    if (link.routePath case final routePath?) {
      final uri = Uri(path: routePath, queryParameters: link.queryParameters.isEmpty ? null : link.queryParameters);
      context.go(uri.toString());
    }
  }

  Widget _messageBanner(String message, Color accentColor) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: accentColor, width: 2),
        ),
        child: _txt(message, AppColors.gray, 12, FontWeight.w600),
      );

  Widget _tile(String title, String desc, Color color) => Builder(builder: (ctx) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: _boxDec(ctx),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _txt(title, color, 14, FontWeight.w800),
            const SizedBox(height: 2),
            _txt(desc, AppColors.gray, 12, FontWeight.w500),
          ],
        ),
      );

  Widget _productLite(
    BuildContext context,
    HomeFeaturedProduct product,
    Color imgBg,
    {
    void Function(BuildContext context)? onTap,
    VoidCallback? onAddToCart,
  }) =>
      AnimatedBuilder(
        animation: Listenable.merge([
          AppServices.instance.cartSession,
          AppServices.instance.wishlistSession,
        ]),
        builder: (context, _) {
          final quantity = AppServices.instance.cartSession
              .quantityForProduct(product.productId);
          final isFavorite = AppServices.instance.wishlistSession
              .contains(product.productId);
          return GestureDetector(
            onTap: onTap == null ? null : () => onTap(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.gray, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: imgBg,
                            borderRadius: BorderRadius.circular(6),
                            border:
                                Border.all(color: AppColors.gray, width: 2),
                            image: product.imageUrl.isEmpty
                                ? null
                                : DecorationImage(
                                    image: NetworkImage(product.imageUrl),
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                      if (quantity > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _cartQuantityBadge(quantity),
                        ),
                      Positioned(
                        left: 8,
                        top: 8,
                        child: GestureDetector(
                          onTap: () => AppServices.instance.wishlistSession
                              .toggle(product.productId),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: AppColors.gray,
                                width: 1.5,
                              ),
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite
                                  ? AppColors.red
                                  : AppColors.blue,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _txt(
                              product.title,
                              colorForAccent(product.titleAccent),
                              13,
                              FontWeight.w700,
                            ),
                            _txt(product.price, AppColors.green, 20, FontWeight.w700),
                            const SizedBox(height: 4),
                            _ratingChip(
                              product.averageRating,
                              product.reviewCount,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onAddToCart,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.gray, width: 2),
                          ),
                          child: const Icon(
                            Icons.add_shopping_cart_rounded,
                            color: Colors.white,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

  Widget _cartQuantityBadge(int quantity) => Container(
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: _txt(
          'x$quantity',
          Colors.white,
          11,
          FontWeight.w900,
        ),
      );

  Widget _ratingChip(double averageRating, int reviewCount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F8FF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.gray, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.star_rounded,
              size: 13,
              color: Color(0xFFF59E0B),
            ),
            const SizedBox(width: 4),
            _txt(
              averageRating <= 0
                  ? 'Mới'
                  : '${averageRating.toStringAsFixed(1)} · $reviewCount',
              AppColors.gray,
              10,
              FontWeight.w700,
            ),
          ],
        ),
      );

  void _addFeaturedProductToCart(
    BuildContext context,
    HomeFeaturedProduct product,
  ) {
    AppServices.instance.cartSession.addFeaturedProduct(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${product.title} vào giỏ hàng.'),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  Widget _catItem(String text, Color color, {bool selected = false}) =>
      Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF3FF) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border:
              Border.all(color: selected ? color : AppColors.gray, width: 2),
        ),
        child: _txt(text, color, 13, FontWeight.w700),
      );

  Widget _button(
    String text,
    Color bg,
    double width,
    double height,
    double fontSize,
    FontWeight fw, {
    double radius = 6,
    double border = 2,
    VoidCallback? onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.gray, width: border),
          ),
          child: _txt(text, Colors.white, fontSize, fw),
        ),
      );

  Widget _profileIcon() => Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gray, width: 2),
        ),
        child: const Icon(Icons.person, size: 12, color: AppColors.blue),
      );

  BoxDecoration _boxDec([BuildContext? ctx]) {
    final bg = ctx != null ? Theme.of(ctx).cardColor : Colors.white;
    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AppColors.gray, width: 2),
    );
  }

  Widget _txt(String text, Color color, double size, FontWeight weight,
          [double? lineHeight]) =>
      Text(
        text,
        style: TextStyle(
            color: color,
            fontSize: size,
            fontWeight: weight,
            height: lineHeight),
      );
}

class _HomeProductSkeleton extends StatelessWidget {
  const _HomeProductSkeleton({this.mobile = false});

  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final itemCount = mobile ? 2 : 3;
    if (mobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(itemCount * 2 - 1, (index) {
          if (index.isOdd) {
            return const SizedBox(height: 8);
          }
          return _cardSkeleton(height: 232);
        }),
      );
    }
    return SizedBox(
      height: 270,
      child: Row(
        children: List.generate(itemCount * 2 - 1, (index) {
          if (index.isOdd) {
            return const SizedBox(width: 16);
          }
          return Expanded(child: _cardSkeleton(height: 270));
        }),
      ),
    );
  }

  Widget _cardSkeleton({required double height}) => Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.gray, width: 2),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(width: double.infinity, height: mobile ? 140 : 130, borderRadius: 6),
            const SizedBox(height: 10),
            ShimmerBox(width: mobile ? 150 : 110, height: 14, borderRadius: 999),
            const SizedBox(height: 10),
            ShimmerBox(width: mobile ? 110 : 90, height: mobile ? 24 : 28, borderRadius: 999),
            const SizedBox(height: 8),
            const ShimmerBox(width: 92, height: 22, borderRadius: 999),
          ],
        ),
      );
}

class _ScrollRevealSection extends StatefulWidget {
  const _ScrollRevealSection({
    required this.scrollController,
    required this.child,
  });

  final ScrollController scrollController;
  final Widget child;

  @override
  State<_ScrollRevealSection> createState() => _ScrollRevealSectionState();
}

class _ScrollRevealSectionState extends State<_ScrollRevealSection> {
  final GlobalKey _sectionKey = GlobalKey();
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void didUpdateWidget(covariant _ScrollRevealSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    if (_isVisible || !mounted) {
      return;
    }
    final context = _sectionKey.currentContext;
    if (context == null) {
      return;
    }
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) {
      return;
    }
    final top = renderObject.localToGlobal(Offset.zero).dy;
    final viewportHeight = MediaQuery.of(context).size.height;
    if (top <= viewportHeight * 0.92) {
      setState(() {
        _isVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: _sectionKey,
      opacity: _isVisible ? 1 : 0,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      child: AnimatedSlide(
        offset: _isVisible ? Offset.zero : const Offset(0, 0.08),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
