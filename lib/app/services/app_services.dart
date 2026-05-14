import 'package:http/http.dart' as http;

import '../repositories/admin_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/auth_page_repository.dart';
import '../repositories/checkout_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/home_repository.dart';
import '../repositories/menu_repository.dart';
import '../repositories/story_repository.dart';
import '../repositories/voucher_repository.dart';
import '../network/api_config.dart';
import '../network/network_client.dart';
import 'auth_session.dart';
import 'cart_session.dart';
import 'wishlist_session.dart';
import 'recently_viewed_session.dart';

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  final AuthSession authSession = AuthSession();
  final CartSession cartSession = CartSession();
  final WishlistSession wishlistSession = WishlistSession();
  final RecentlyViewedSession recentlyViewedSession = RecentlyViewedSession();
  late final ApiClient apiClient;
  late final AuthRepository authRepository;
  late final AdminRepository adminRepository;
  late final AuthPageRepository authPageRepository;
  late final CheckoutRepository checkoutRepository;
  late final ContactRepository contactRepository;
  late final HomeRepository homeRepository;
  late final MenuRepository menuRepository;
  late final StoryRepository storyRepository;
  late final VoucherRepository voucherRepository;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await authSession.initialize();
    await cartSession.initialize();
    await wishlistSession.initialize();
    await recentlyViewedSession.initialize();

    final config = ApiConfig.fromEnvironment();
    apiClient = ApiClient(
      config: config,
      httpClient: http.Client(),
      tokenProvider: () => authSession.accessToken,
    );
    checkoutRepository = ApiCheckoutRepository(apiClient);
    cartSession.configureSync(
      loadRemoteItems: () async => (await checkoutRepository.getCart()).items,
      mergeRemoteItems: (guestItems) async =>
          (await checkoutRepository.mergeCart(guestItems)).items,
      replaceRemoteItems: (items) async =>
          (await checkoutRepository.replaceCart(items)).items,
      canSyncRemotely: () => authSession.isAuthenticated,
    );
    authRepository = ApiAuthRepository(apiClient, authSession, cartSession);
    authSession.attachRefreshHandler(() => authRepository.refreshSession());
    apiClient.attachAuthRefreshHandler(() => authRepository.refreshSession());
    adminRepository = ApiAdminRepository(apiClient);
    authPageRepository = ApiAuthPageRepository(apiClient);
    contactRepository = ApiContactRepository(apiClient);
    homeRepository = ApiHomeRepository(apiClient);
    menuRepository = ApiMenuRepository(apiClient);
    storyRepository = ApiStoryRepository(apiClient);
    voucherRepository = ApiVoucherRepository(apiClient, authSession);
    if (authSession.isAuthenticated) {
      try {
        await cartSession.loadRemoteSnapshot();
      } catch (_) {}
    }
    _isInitialized = true;
  }

  void dispose() {
    if (!_isInitialized) {
      return;
    }

    apiClient.close();
    authSession.clear();
    cartSession.clear();
    _isInitialized = false;
  }
}
