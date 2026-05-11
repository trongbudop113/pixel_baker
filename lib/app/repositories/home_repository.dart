import '../models/home_models.dart';
import '../models/ui_accent.dart';
import '../network/base_api_repository.dart';

abstract class HomeRepository {
  Future<HomePageResponse> fetchHomePage();
  Future<List<HomeTestimonial>> fetchTestimonials();
  Future<HomeTestimonial> submitTestimonial(String content);
}

class ApiHomeRepository extends BaseApiRepository implements HomeRepository {
  ApiHomeRepository(super.apiClient);

  HomePageResponse? _cachedPageResponse;
  List<HomeTestimonial>? _cachedTestimonials;

  @override
  Future<HomePageResponse> fetchHomePage() async {
    if (_cachedPageResponse != null) {
      return _cachedPageResponse!;
    }

    if (!apiClient.config.hasBaseUrl) {
      return _cacheResponse(defaultHomePageResponse);
    }

    try {
      final response = await apiClient.get<HomePageResponse>(
        '/home',
        decoder: (json) => readItem(
          _unwrapItemPayload(json),
          HomePageResponse.fromJson,
        ),
      );
      return _cacheResponse(response.data);
    } catch (_) {
      return _cacheResponse(defaultHomePageResponse);
    }
  }

  @override
  Future<List<HomeTestimonial>> fetchTestimonials() async {
    if (_cachedTestimonials != null) {
      return _cachedTestimonials!;
    }

    if (!apiClient.config.hasBaseUrl) {
      return _cacheTestimonials(defaultHomePageResponse.testimonials);
    }

    try {
      final response = await apiClient.get<List<HomeTestimonial>>(
        '/home/testimonials',
        decoder: (json) => readList(
          _unwrapListPayload(json),
          HomeTestimonial.fromJson,
        ),
      );
      return _cacheTestimonials(response.data);
    } catch (_) {
      return _cacheTestimonials(defaultHomePageResponse.testimonials);
    }
  }

  @override
  Future<HomeTestimonial> submitTestimonial(String content) async {
    final response = await apiClient.post<HomeTestimonial>(
      '/home/testimonials',
      requiresAuth: true,
      body: {'content': content},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        HomeTestimonial.fromJson,
      ),
    );
    final created = response.data;
    _cachedTestimonials = [
      created,
      ...?_cachedTestimonials,
    ];
    return created;
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    return json;
  }

  Object? _unwrapListPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['items'];
      return data ?? json;
    }
    return json;
  }

  HomePageResponse _cacheResponse(HomePageResponse response) {
    _cachedPageResponse = response;
    return response;
  }

  List<HomeTestimonial> _cacheTestimonials(List<HomeTestimonial> testimonials) {
    _cachedTestimonials = List<HomeTestimonial>.unmodifiable(testimonials);
    return _cachedTestimonials!;
  }
}

const HomePageResponse defaultHomePageResponse = HomePageResponse(
  hero: HomeHeroSection(
    title: 'Hương vị cổ điển\nGiao diện hiện đại',
    description:
        'Pixel Bakery kết hợp cảm hứng máy game cổ điển với trải nghiệm mua bánh hiện đại, dễ dùng.',
    primaryAction: HomeActionLink(
      label: 'XEM THỰC ĐƠN',
      routeName: 'menu',
    ),
    secondaryAction: HomeActionLink(
      label: 'ĐẶT NGAY',
      routeName: 'ordersInfo',
    ),
  ),
  highlights: [
    HomeInfoHighlight(
      title: 'Giao nhanh trong ngày',
      description: 'Nội thành nhận bánh trong 2 giờ.',
      accent: UiAccent.blue,
    ),
    HomeInfoHighlight(
      title: 'Nguyên liệu tươi mới',
      description: 'Làm bánh mỗi ngày, không chất bảo quản.',
      accent: UiAccent.red,
    ),
    HomeInfoHighlight(
      title: 'Mở cửa mỗi ngày',
      description: '08:00 - 21:30, hỗ trợ đặt online.',
      accent: UiAccent.green,
    ),
  ],
  featuredProducts: [
    HomeFeaturedProduct(
      productId: 1,
      title: 'BÁNH DÂU PIXEL',
      price: '55.000đ',
      imageUrl:
          'https://images.unsplash.com/photo-1621177921600-13666f61db2d?auto=format&fit=crop&w=1080&q=80',
      titleAccent: UiAccent.blue,
      priceAccent: UiAccent.green,
    ),
    HomeFeaturedProduct(
      productId: 2,
      title: 'BÁNH VIỆT QUẤT 8-BIT',
      price: '60.000đ',
      imageUrl:
          'https://images.unsplash.com/photo-1723760822616-67baeb5559fe?auto=format&fit=crop&w=1080&q=80',
      titleAccent: UiAccent.red,
      priceAccent: UiAccent.green,
    ),
    HomeFeaturedProduct(
      productId: 3,
      title: 'TART LÁ XANH',
      price: '58.000đ',
      imageUrl:
          'https://images.unsplash.com/photo-1567624725806-227866a3f784?auto=format&fit=crop&w=1080&q=80',
      titleAccent: UiAccent.blue,
      priceAccent: UiAccent.red,
    ),
  ],
  story: HomeStorySection(
    title: 'Câu chuyện Pixel Bakery',
    description:
        'Từ cảm hứng máy game thùng, chúng tôi tạo nên những chiếc bánh có màu sắc vui mắt, vị ngon cân bằng và chất lượng ổn định mỗi ngày.',
    badgeText: '100% Làm mới trong ngày',
  ),
  categories: [
    HomeCategory(
      label: 'Cupcake',
      routeCategory: 'cupcake',
      accent: UiAccent.red,
    ),
    HomeCategory(
      label: 'Cookie',
      routeCategory: 'cookie',
      accent: UiAccent.blue,
    ),
    HomeCategory(
      label: 'Tart',
      routeCategory: 'tart',
      accent: UiAccent.green,
    ),
    HomeCategory(
      label: 'Bánh sinh nhật',
      routeCategory: 'cake',
      accent: UiAccent.gray,
    ),
  ],
  testimonials: [
    HomeTestimonial(
      content: '“Bánh đẹp như game pixel, vị lại rất vừa miệng.”',
      author: '- Minh Anh',
      accent: UiAccent.red,
    ),
    HomeTestimonial(
      content: '“Đặt online nhanh, nhận bánh đúng giờ, đóng gói xịn.”',
      author: '- Tuấn Khoa',
      accent: UiAccent.blue,
    ),
  ],
  faqs: [
    HomeFaq(
      question: 'Có nhận đặt bánh theo mẫu không?',
      answer: 'Có, bạn chỉ cần gửi ảnh mẫu trước 24-48 giờ.',
      accent: UiAccent.red,
    ),
    HomeFaq(
      question: 'Có giao bánh theo khung giờ không?',
      answer: 'Có, bạn chọn giờ nhận khi đặt đơn online.',
      accent: UiAccent.blue,
    ),
  ],
  promo: HomePromoBanner(
    message: 'Giảm 15% cho đơn đầu tiên - dùng mã PIXEL15',
    action: HomeActionLink(
      label: 'Dùng ngay',
      routeName: 'voucher',
    ),
  ),
  footer: HomeFooterSection(
    tagline: 'PIXEL BAKERY  |  VỊ CỔ ĐIỂN, CHẤT HIỆN ĐẠI',
    links: [
      HomeActionLink(label: 'Liên hệ', routeName: 'contact'),
      HomeActionLink(
        label: 'Chính sách giao hàng',
        routeName: 'deliveryPolicy',
      ),
      HomeActionLink(
        label: 'Chính sách thanh toán',
        routeName: 'paymentPolicy',
      ),
    ],
  ),
);
