import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pixel_bakery_home_web_flutter/screens/auth/forgot_password_page.dart';
import 'package:pixel_bakery_home_web_flutter/screens/auth/login_page.dart';
import 'package:pixel_bakery_home_web_flutter/screens/auth/register_page.dart';

import '../services/app_services.dart';
import '../services/seo_service.dart';
import '../../screens/admin/admin_page.dart';
import '../../screens/admin/admin_customer_form_page.dart';
import '../../screens/admin/admin_ingredient_form_page.dart';
import '../../screens/admin/admin_product_form_page.dart';
import '../../screens/admin/admin_recipe_form_page.dart';
import '../../screens/checkout/checkout_page.dart';
import '../../screens/contact/contact_page.dart';
import '../../screens/home/home_page.dart';
import '../../screens/menu/menu_page.dart';
import '../../screens/orders_detail/orders_detail_page.dart';
import '../../screens/orders_info/orders_info_page.dart';
import '../../screens/policies/policy_pages.dart';
import '../../screens/product_detail/product_detail_page.dart';
import '../../screens/profile/profile_page.dart';
import '../../screens/shared/app_header.dart';
import '../../screens/story/story_page.dart';
import '../../screens/voucher/voucher_page.dart';
import '../../screens/wishlist/wishlist_page.dart';

class AppRouteNames {
  static const home = 'home';
  static const profile = 'profile';
  static const checkout = 'checkout';
  static const menu = 'menu';
  static const voucher = 'voucher';
  static const story = 'story';
  static const contact = 'contact';
  static const deliveryPolicy = 'deliveryPolicy';
  static const paymentPolicy = 'paymentPolicy';
  static const login = 'login';
  static const register = 'register';
  static const forgotPassword = 'forgotPassword';
  static const resetPassword = 'resetPassword';
  static const wishlist = 'wishlist';
  static const admin = 'admin';
  static const ordersDetail = 'ordersDetail';
  static const ordersInfo = 'ordersInfo';
  static const productDetail = 'productDetail';
  static const adminProductForm = 'adminProductForm';
  static const adminCustomerForm = 'adminCustomerForm';
  static const adminRecipeForm = 'adminRecipeForm';
  static const adminIngredientForm = 'adminIngredientForm';
}

class AppRoutePaths {
  static const home = '/';
  static const profile = '/profile';
  static const checkout = '/checkout';
  static const menu = '/menu';
  static const voucher = '/voucher';
  static const story = '/story';
  static const contact = '/contact';
  static const deliveryPolicy = '/delivery-policy';
  static const paymentPolicy = '/payment-policy';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const wishlist = '/wishlist';
  static const admin = '/admin';
  static const ordersDetail = '/orders-detail';
  static const ordersInfo = '/orders-info';
  static const productDetail = '/menu/productDetail';
  static const adminProductForm = '/admin/product-form';
  static const adminCustomerForm = '/admin/customer-form';
  static const adminRecipeForm = '/admin/recipe-form';
  static const adminIngredientForm = '/admin/ingredient-form';
}

/// Helper: fade transition page (200ms)
CustomTransitionPage<void> _fadePage(
  GoRouterState state,
  Widget child, {
  Duration duration = const Duration(milliseconds: 200),
}) {
  return CustomTransitionPage<void>(
    key: ValueKey(state.uri.toString()),
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

class AppRouter {
  static const BoxConstraints pageWidthConstraints = BoxConstraints(
    maxWidth: 1440,
    minWidth: 600,
  );

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.home,
    refreshListenable: AppServices.instance.authSession,
    redirect: (context, state) {
      final authConfig = AppServices.instance.authSession.authConfig;
      final path = state.uri.path;
      final isLoggedIn = authConfig.isLogin;
      final isAdmin = authConfig.user?.isAdmin == true;

      const authOnlyPaths = {
        AppRoutePaths.profile,
        AppRoutePaths.checkout,
        AppRoutePaths.ordersDetail,
        AppRoutePaths.ordersInfo,
      };
      const adminOnlyPaths = {
        AppRoutePaths.admin,
        AppRoutePaths.adminProductForm,
        AppRoutePaths.adminCustomerForm,
        AppRoutePaths.adminRecipeForm,
        AppRoutePaths.adminIngredientForm,
      };
      const guestOnlyPaths = {
        AppRoutePaths.login,
        AppRoutePaths.register,
        AppRoutePaths.forgotPassword,
        AppRoutePaths.resetPassword,
      };

      if (adminOnlyPaths.contains(path)) {
        if (!isLoggedIn) {
          return AppRoutePaths.login;
        }
        if (!isAdmin) {
          return AppRoutePaths.home;
        }
      }

      if (authOnlyPaths.contains(path) && !isLoggedIn) {
        return AppRoutePaths.login;
      }

      if (guestOnlyPaths.contains(path) && isLoggedIn) {
        return isAdmin ? AppRoutePaths.admin : AppRoutePaths.profile;
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            _MainShellScaffold(state: state, child: child),
        routes: [
          GoRoute(
            path: AppRoutePaths.home,
            name: AppRouteNames.home,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveHomeScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.checkout,
            name: AppRouteNames.checkout,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveCheckoutScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.menu,
            name: AppRouteNames.menu,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveMenuScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.productDetail,
            name: AppRouteNames.productDetail,
            redirect: (context, state) {
              final idParam = state.uri.queryParameters['id'];
              final id = int.tryParse(idParam ?? '');
              if (id == null) return AppRoutePaths.home;
              return null;
            },
            pageBuilder: (context, state) {
              final id = int.tryParse(state.uri.queryParameters['id'] ?? '');
              final autoOpenMooncakeBox = state.uri.queryParameters['box'] == '1';
              return _fadePage(state, ResponsiveProductDetailScreen(
                productId: id!,
                showTopHeader: false,
                autoOpenMooncakeBox: autoOpenMooncakeBox,
              ));
            },
          ),
          GoRoute(
            path: AppRoutePaths.profile,
            name: AppRouteNames.profile,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveProfileScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.voucher,
            name: AppRouteNames.voucher,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveVoucherScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.story,
            name: AppRouteNames.story,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveStoryScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.contact,
            name: AppRouteNames.contact,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveContactScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.deliveryPolicy,
            name: AppRouteNames.deliveryPolicy,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveDeliveryPolicyScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.paymentPolicy,
            name: AppRouteNames.paymentPolicy,
            pageBuilder: (context, state) => _fadePage(state, const ResponsivePaymentPolicyScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.login,
            name: AppRouteNames.login,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveLoginScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.register,
            name: AppRouteNames.register,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveRegisterScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.wishlist,
            name: AppRouteNames.wishlist,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveWishlistScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.forgotPassword,
            name: AppRouteNames.forgotPassword,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveForgotPasswordScreen(showTopHeader: false)),
          ),
          GoRoute(
            path: AppRoutePaths.resetPassword,
            name: AppRouteNames.resetPassword,
            pageBuilder: (context, state) => _fadePage(state, ResponsiveResetPasswordScreen(
              showTopHeader: false,
              initialToken: state.uri.queryParameters['token'],
            )),
          ),
          GoRoute(
            path: AppRoutePaths.admin,
            name: AppRouteNames.admin,
            pageBuilder: (context, state) {
              final sidebarIndex = int.tryParse(state.uri.queryParameters['sidebar'] ?? '') ?? 0;
              return _fadePage(state, ResponsiveAdminScreen(
                showTopHeader: false,
                initialSidebarIndex: sidebarIndex,
              ));
            },
          ),
          GoRoute(
            path: AppRoutePaths.adminProductForm,
            name: AppRouteNames.adminProductForm,
            pageBuilder: (context, state) {
              final productId = int.tryParse(state.uri.queryParameters['id'] ?? '');
              final returnSidebarIndex = int.tryParse(state.uri.queryParameters['sidebar'] ?? '') ?? 2;
              return _fadePage(state, ResponsiveAdminProductFormScreen(
                showTopHeader: false,
                productId: productId,
                returnSidebarIndex: returnSidebarIndex,
              ));
            },
          ),
          GoRoute(
            path: AppRoutePaths.adminCustomerForm,
            name: AppRouteNames.adminCustomerForm,
            pageBuilder: (context, state) {
              final customerId = state.uri.queryParameters['id'] ?? '';
              final returnSidebarIndex = int.tryParse(state.uri.queryParameters['sidebar'] ?? '') ?? 3;
              return _fadePage(state, ResponsiveAdminCustomerFormScreen(
                showTopHeader: false,
                customerId: customerId,
                returnSidebarIndex: returnSidebarIndex,
              ));
            },
          ),
          GoRoute(
            path: AppRoutePaths.adminRecipeForm,
            name: AppRouteNames.adminRecipeForm,
            pageBuilder: (context, state) {
              final recipeId = state.uri.queryParameters['id'];
              final returnSidebarIndex = int.tryParse(state.uri.queryParameters['sidebar'] ?? '') ?? 5;
              return _fadePage(state, ResponsiveAdminRecipeFormScreen(
                showTopHeader: false,
                recipeId: recipeId,
                returnSidebarIndex: returnSidebarIndex,
              ));
            },
          ),
          GoRoute(
            path: AppRoutePaths.adminIngredientForm,
            name: AppRouteNames.adminIngredientForm,
            pageBuilder: (context, state) {
              final ingredientId = state.uri.queryParameters['id'];
              final returnSidebarIndex = int.tryParse(state.uri.queryParameters['sidebar'] ?? '') ?? 4;
              return _fadePage(state, ResponsiveAdminIngredientFormScreen(
                showTopHeader: false,
                ingredientId: ingredientId,
                returnSidebarIndex: returnSidebarIndex,
              ));
            },
          ),
          GoRoute(
            path: AppRoutePaths.ordersDetail,
            name: AppRouteNames.ordersDetail,
            pageBuilder: (context, state) => _fadePage(state, ResponsiveOrdersDetailScreen(
              showTopHeader: false,
              orderId: state.uri.queryParameters['id'],
            )),
          ),
          GoRoute(
            path: AppRoutePaths.ordersInfo,
            name: AppRouteNames.ordersInfo,
            pageBuilder: (context, state) => _fadePage(state, const ResponsiveOrdersInfoScreen(showTopHeader: false)),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: pageWidthConstraints,
          child: Center(
            child: Text(
              'Route not found: ${state.uri}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    ),
  );
}

class _MainShellScaffold extends StatefulWidget {
  const _MainShellScaffold({required this.state, required this.child});

  final GoRouterState state;
  final Widget child;

  @override
  State<_MainShellScaffold> createState() => _MainShellScaffoldState();
}

class _MainShellScaffoldState extends State<_MainShellScaffold> {
  bool _scrolled = false;

  void _onScrollNotification(bool scrolled) {
    if (scrolled != _scrolled) {
      setState(() => _scrolled = scrolled);
    }
  }

  @override
  Widget build(BuildContext context) {
    _applySeo();
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppServices.instance.authSession,
        AppServices.instance.cartSession,
      ]),
      builder: (context, _) {
        final path = widget.state.uri.path;
        final isMobile = MediaQuery.of(context).size.width < 900;
        final isMenu = path == AppRoutePaths.menu;
        final authConfig = AppServices.instance.authSession.authConfig;
        final cartCount = AppServices.instance.cartSession.itemCount;

        final rightLabel = isMenu ? 'thực đơn' : 'giỏ hàng';
        final centerLabel =
            isMobile ? null : 'tiệm bánh arcade | mở cửa 08:00 - 21:30';

        return Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: AppRouter.pageWidthConstraints,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: _scrolled
                          ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]
                          : [],
                    ),
                    padding:
                        EdgeInsets.only(top: isMobile ? 12 : 24, bottom: 10),
                    child: PixelHeaderBar(
                      rightLabel: rightLabel,
                      centerLabel: centerLabel,
                      rightWidget: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => context.goNamed(
                              authConfig.isLogin
                                  ? (authConfig.user?.isAdmin == true
                                      ? AppRouteNames.admin
                                      : AppRouteNames.profile)
                                  : AppRouteNames.login,
                            ),
                            child: _profileIcon(isLogin: authConfig.isLogin),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () =>
                                context.goNamed(AppRouteNames.checkout),
                            child: _cartButton(
                              isMobile: isMobile,
                              cartCount: cartCount,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        _onScrollNotification(
                          notification.metrics.pixels > 10,
                        );
                        return false;
                      },
                      child: widget.child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _applySeo() {
    final path = widget.state.uri.path;
    final config = switch (path) {
      AppRoutePaths.menu => (
          'Pixel Bakery | Thực Đơn',
          'Thực đơn bánh ngọt, combo và món bán chạy của Pixel Bakery.'
        ),
      AppRoutePaths.productDetail => (
          'Pixel Bakery | Chi Tiết Sản Phẩm',
          'Xem chi tiết sản phẩm, đánh giá và đặt bánh nhanh tại Pixel Bakery.'
        ),
      AppRoutePaths.story => (
          'Pixel Bakery | Câu Chuyện',
          'Câu chuyện thương hiệu và hành trình tạo nên những chiếc bánh của Pixel Bakery.'
        ),
      AppRoutePaths.contact => (
          'Pixel Bakery | Liên Hệ',
          'Liên hệ Pixel Bakery để đặt bánh, hợp tác và nhận hỗ trợ nhanh chóng.'
        ),
      AppRoutePaths.deliveryPolicy => (
          'Pixel Bakery | Chính Sách Giao Hàng',
          'Chi tiết phạm vi giao hàng, thời gian xử lý và lưu ý nhận bánh tại Pixel Bakery.'
        ),
      AppRoutePaths.paymentPolicy => (
          'Pixel Bakery | Chính Sách Thanh Toán',
          'Thông tin về phương thức thanh toán, xác nhận giao dịch và hoàn tiền tại Pixel Bakery.'
        ),
      AppRoutePaths.wishlist => (
          'Pixel Bakery | Yêu Thích',
          'Danh sách sản phẩm yêu thích để quay lại chọn bánh nhanh hơn.'
        ),
      AppRoutePaths.checkout => (
          'Pixel Bakery | Thanh Toán',
          'Xác nhận đơn hàng và hoàn tất thanh toán tại Pixel Bakery.'
        ),
      _ => (
          'Pixel Bakery | Trang Chủ',
          'Bánh ngọt thủ công, menu nổi bật và trải nghiệm đặt bánh online tại Pixel Bakery.'
        ),
    };
    SeoService.instance.apply(title: config.$1, description: config.$2);
  }

  Widget _profileIcon({required bool isLogin}) => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isLogin ? AppHeaderColors.blue : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppHeaderColors.gray, width: 2),
        ),
        child: Icon(
          Icons.person,
          size: 14,
          color: isLogin ? Colors.white : AppHeaderColors.blue,
        ),
      );

  Widget _cartButton({
    required bool isMobile,
    required int cartCount,
  }) {
    final badgeCount = cartCount > 99 ? '99+' : '$cartCount';
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isMobile ? 88 : 104,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppHeaderColors.red,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppHeaderColors.gray, width: 1),
          ),
          child: Text(
            'giỏ hàng',
            style: TextStyle(
              color: Colors.white,
              fontSize: isMobile ? 10 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (cartCount > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppHeaderColors.blue, width: 2),
              ),
              child: Text(
                badgeCount,
                style: const TextStyle(
                  color: AppHeaderColors.blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
