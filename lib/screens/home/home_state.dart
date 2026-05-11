import '../../app/models/home_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/home_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

enum HomeNavigationTarget {
  profile,
  checkout,
  menu,
  voucher,
  contact,
  login,
  admin,
}

class HomeScrollCache {
  static double webOffset = 0;
  static double mobileOffset = 0;
}

class HomeViewState {
  const HomeViewState({
    this.pageResponse = defaultHomePageResponse,
    this.testimonials = const [],
    this.selectedCategoryIndex = 0,
    this.selectedTestimonialIndex = 0,
    this.expandedFaqIndex = 0,
    this.isLoading = false,
    this.isSubmittingTestimonial = false,
    this.errorMessage,
    this.testimonialMessage,
    this.isTestimonialSuccess = false,
  });

  final HomePageResponse pageResponse;
  final List<HomeTestimonial> testimonials;
  final int selectedCategoryIndex;
  final int selectedTestimonialIndex;
  final int expandedFaqIndex;
  final bool isLoading;
  final bool isSubmittingTestimonial;
  final String? errorMessage;
  final String? testimonialMessage;
  final bool isTestimonialSuccess;

  HomeViewState copyWith({
    HomePageResponse? pageResponse,
    List<HomeTestimonial>? testimonials,
    int? selectedCategoryIndex,
    int? selectedTestimonialIndex,
    int? expandedFaqIndex,
    bool? isLoading,
    bool? isSubmittingTestimonial,
    String? errorMessage,
    String? testimonialMessage,
    bool? isTestimonialSuccess,
    bool clearErrorMessage = false,
    bool clearTestimonialMessage = false,
  }) {
    return HomeViewState(
      pageResponse: pageResponse ?? this.pageResponse,
      testimonials: testimonials ?? this.testimonials,
      selectedCategoryIndex:
          selectedCategoryIndex ?? this.selectedCategoryIndex,
      selectedTestimonialIndex:
          selectedTestimonialIndex ?? this.selectedTestimonialIndex,
      expandedFaqIndex: expandedFaqIndex ?? this.expandedFaqIndex,
      isLoading: isLoading ?? this.isLoading,
      isSubmittingTestimonial:
          isSubmittingTestimonial ?? this.isSubmittingTestimonial,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      testimonialMessage: clearTestimonialMessage
          ? null
          : (testimonialMessage ?? this.testimonialMessage),
      isTestimonialSuccess:
          isTestimonialSuccess ?? this.isTestimonialSuccess,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is HomeViewState &&
        identical(other.pageResponse, pageResponse) &&
        _sameTestimonials(other.testimonials, testimonials) &&
        other.selectedCategoryIndex == selectedCategoryIndex &&
        other.selectedTestimonialIndex == selectedTestimonialIndex &&
        other.expandedFaqIndex == expandedFaqIndex &&
        other.isLoading == isLoading &&
        other.isSubmittingTestimonial == isSubmittingTestimonial &&
        other.errorMessage == errorMessage &&
        other.testimonialMessage == testimonialMessage &&
        other.isTestimonialSuccess == isTestimonialSuccess;
  }

  @override
  int get hashCode => Object.hash(
        pageResponse,
        Object.hashAll(testimonials),
        selectedCategoryIndex,
        selectedTestimonialIndex,
        expandedFaqIndex,
        isLoading,
        isSubmittingTestimonial,
        errorMessage,
        testimonialMessage,
        isTestimonialSuccess,
      );
}

class HomeState extends ScreenController<HomeViewState, HomeNavigationTarget> {
  HomeState({HomeRepository? repository})
      : _repository = repository ?? AppServices.instance.homeRepository,
        super(const HomeViewState());

  final HomeRepository _repository;
  bool _hasLoaded = false;

  List<HomeCategory> get categories => state.pageResponse.categories;
  List<HomeTestimonial> get testimonials => state.testimonials;
  List<HomeFaq> get faqs => state.pageResponse.faqs;

  List<HomeCategory> get mobileCategories {
    return categories.length <= 2
        ? categories
        : categories.take(2).toList(growable: false);
  }

  List<HomeTestimonial> get mobileTestimonials {
    return testimonials.length <= 2
        ? testimonials
        : testimonials.take(2).toList(growable: false);
  }

  List<HomeFaq> get mobileFaqs {
    return faqs.length <= 2 ? faqs : faqs.take(2).toList(growable: false);
  }

  HomePageResponse get pageResponse => state.pageResponse;
  int get selectedCategoryIndex => state.selectedCategoryIndex;
  int get selectedTestimonialIndex => state.selectedTestimonialIndex;
  int get expandedFaqIndex => state.expandedFaqIndex;
  bool get isLoading => state.isLoading;
  bool get isSubmittingTestimonial => state.isSubmittingTestimonial;
  String? get errorMessage => state.errorMessage;
  String? get testimonialMessage => state.testimonialMessage;
  bool get isTestimonialSuccess => state.isTestimonialSuccess;

  Future<void> load() async {
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;

    update((current) => current.copyWith(isLoading: true, clearErrorMessage: true));

    try {
      final pageResponse = await _repository.fetchHomePage();
      final testimonials = await _repository.fetchTestimonials();
      update(
        (current) => current.copyWith(
          pageResponse: pageResponse,
          testimonials: testimonials,
          selectedCategoryIndex: _safeIndex(
            current.selectedCategoryIndex,
            pageResponse.categories.length,
          ),
          selectedTestimonialIndex: _safeIndex(
            current.selectedTestimonialIndex,
            testimonials.length,
          ),
          expandedFaqIndex: _safeExpandedIndex(
            current.expandedFaqIndex,
            pageResponse.faqs.length,
          ),
          isLoading: false,
          clearErrorMessage: true,
        ),
      );
    } catch (_) {
      _hasLoaded = false;
      update(
        (current) => current.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải dữ liệu trang chủ từ backend.',
        ),
      );
    }
  }

  int _safeIndex(int currentIndex, int itemCount) {
    if (itemCount <= 0) {
      return 0;
    }
    if (currentIndex < 0) {
      return 0;
    }
    if (currentIndex >= itemCount) {
      return itemCount - 1;
    }
    return currentIndex;
  }

  int _safeExpandedIndex(int currentIndex, int itemCount) {
    if (itemCount <= 0 || currentIndex < 0 || currentIndex >= itemCount) {
      return -1;
    }
    return currentIndex;
  }

  void selectCategory(int index) {
    update((current) => current.copyWith(selectedCategoryIndex: index));
  }

  void selectTestimonial(int index) {
    update((current) => current.copyWith(selectedTestimonialIndex: index));
  }

  Future<void> submitTestimonial(String rawContent) async {
    final content = rawContent.trim();
    if (!AppServices.instance.authSession.isAuthenticated) {
      update((current) => current.copyWith(
            testimonialMessage: 'Vui lòng đăng nhập để gửi đánh giá.',
            isTestimonialSuccess: false,
          ));
      emit(HomeNavigationTarget.login);
      return;
    }
    if (content.length < 10) {
      update((current) => current.copyWith(
            testimonialMessage: 'Nội dung đánh giá phải có ít nhất 10 ký tự.',
            isTestimonialSuccess: false,
          ));
      return;
    }
    if (state.isSubmittingTestimonial) {
      return;
    }

    update((current) => current.copyWith(
          isSubmittingTestimonial: true,
          clearTestimonialMessage: true,
          isTestimonialSuccess: false,
        ));

    try {
      final created = await _repository.submitTestimonial(content);
      final updatedTestimonials = [created, ...state.testimonials];
      update((current) => current.copyWith(
            testimonials: updatedTestimonials,
            selectedTestimonialIndex: 0,
            isSubmittingTestimonial: false,
            testimonialMessage: 'Gửi đánh giá thành công.',
            isTestimonialSuccess: true,
          ));
    } on ApiException catch (error) {
      final message = error.isUnauthorized
          ? 'Vui lòng đăng nhập lại để gửi đánh giá.'
          : error.message;
      update((current) => current.copyWith(
            isSubmittingTestimonial: false,
            testimonialMessage: message,
            isTestimonialSuccess: false,
          ));
      if (error.isUnauthorized) {
        emit(HomeNavigationTarget.login);
      }
    } catch (_) {
      update((current) => current.copyWith(
            isSubmittingTestimonial: false,
            testimonialMessage: 'Không thể gửi đánh giá lúc này.',
            isTestimonialSuccess: false,
          ));
    }
  }

  void toggleFaq(int index) {
    update((current) {
      final nextIndex = current.expandedFaqIndex == index ? -1 : index;
      return current.copyWith(expandedFaqIndex: nextIndex);
    });
  }

  void openProfile() => _requestNavigation(HomeNavigationTarget.profile);
  void openCheckout() => _requestNavigation(HomeNavigationTarget.checkout);
  void openMenu() => _requestNavigation(HomeNavigationTarget.menu);
  void openVoucher() => _requestNavigation(HomeNavigationTarget.voucher);
  void openContact() => _requestNavigation(HomeNavigationTarget.contact);
  void openLogin() => _requestNavigation(HomeNavigationTarget.login);
  void openAdmin() => _requestNavigation(HomeNavigationTarget.admin);

  void _requestNavigation(HomeNavigationTarget target) {
    emit(target);
  }

  static double webScrollOffset = 0;
  static double mobileScrollOffset = 0;

  static void saveWebScrollOffset(double offset) {
    webScrollOffset = offset;
    HomeScrollCache.webOffset = offset;
  }

  static void saveMobileScrollOffset(double offset) {
    mobileScrollOffset = offset;
    HomeScrollCache.mobileOffset = offset;
  }
}

bool _sameTestimonials(
  List<HomeTestimonial> left,
  List<HomeTestimonial> right,
) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    final a = left[index];
    final b = right[index];
    if (a.id != b.id ||
        a.content != b.content ||
        a.author != b.author ||
        a.accent != b.accent ||
        a.createdAt != b.createdAt) {
      return false;
    }
  }
  return true;
}
