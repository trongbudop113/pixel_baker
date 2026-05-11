import '../../app/models/auth_page_models.dart';
import '../../app/network/api_exception.dart';
import '../../app/repositories/auth_repository.dart';
import '../../app/repositories/auth_page_repository.dart';
import '../../app/services/app_services.dart';
import '../../app/state/screen_controller.dart';

enum AuthNavTarget { login, register, home }

class AuthViewState {
  const AuthViewState({
    required this.pageResponse,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.submitMessage,
    this.isSubmitSuccess = false,
  });

  final AuthPageResponse pageResponse;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final String? submitMessage;
  final bool isSubmitSuccess;

  AuthViewState copyWith({
    AuthPageResponse? pageResponse,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    String? submitMessage,
    bool? isSubmitSuccess,
    bool clearErrorMessage = false,
    bool clearSubmitMessage = false,
  }) {
    return AuthViewState(
      pageResponse: pageResponse ?? this.pageResponse,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      submitMessage:
          clearSubmitMessage ? null : (submitMessage ?? this.submitMessage),
      isSubmitSuccess: isSubmitSuccess ?? this.isSubmitSuccess,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AuthViewState &&
        other.pageResponse == pageResponse &&
        other.isLoading == isLoading &&
        other.isSubmitting == isSubmitting &&
        other.errorMessage == errorMessage &&
        other.submitMessage == submitMessage &&
        other.isSubmitSuccess == isSubmitSuccess;
  }

  @override
  int get hashCode => Object.hash(
        pageResponse,
        isLoading,
        isSubmitting,
        errorMessage,
        submitMessage,
        isSubmitSuccess,
      );
}

class AuthState extends ScreenController<AuthViewState, AuthNavTarget> {
  AuthState({
    required AuthPageType pageType,
    AuthPageRepository? repository,
    AuthRepository? authRepository,
  })  : _pageType = pageType,
        _repository = repository ?? AppServices.instance.authPageRepository,
        _authRepository = authRepository ?? AppServices.instance.authRepository,
        super(
          AuthViewState(
            pageResponse: pageType == AuthPageType.login
                ? defaultLoginPageResponse
                : defaultRegisterPageResponse,
          ),
        );

  final AuthPageType _pageType;
  final AuthPageRepository _repository;
  final AuthRepository _authRepository;
  bool _hasLoaded = false;

  AuthPageResponse get pageResponse => state.pageResponse;
  bool get isLoading => state.isLoading;
  bool get isSubmitting => state.isSubmitting;
  bool get isSubmitSuccess => state.isSubmitSuccess;
  String? get errorMessage => state.errorMessage;
  String? get submitMessage => state.submitMessage;

  Future<void> load() async {
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;

    update((current) => current.copyWith(
          isLoading: true,
          clearErrorMessage: true,
          clearSubmitMessage: true,
        ));

    try {
      final page = await _repository.fetchPage(_pageType);
      update(
        (current) => current.copyWith(
          pageResponse: page,
          isLoading: false,
          clearErrorMessage: true,
          clearSubmitMessage: true,
        ),
      );
    } catch (_) {
      _hasLoaded = false;
      update(
        (current) => current.copyWith(
          isLoading: false,
          errorMessage: 'Không thể tải dữ liệu trang xác thực.',
          clearSubmitMessage: true,
        ),
      );
    }
  }

  void openLogin() {
    emit(AuthNavTarget.login);
  }

  void openRegister() {
    emit(AuthNavTarget.register);
  }

  Future<void> submitLogin({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      update((current) => current.copyWith(
            submitMessage: 'Vui lòng nhập email và mật khẩu.',
            clearErrorMessage: true,
            isSubmitSuccess: false,
          ));
      return;
    }

    await _submit(
      action: () => _authRepository.login(
        email: trimmedEmail,
        password: password,
      ),
      successMessage: 'Đăng nhập thành công.',
    );
  }

  Future<void> submitRegister({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    final trimmedFullName = fullName.trim();
    final trimmedEmail = email.trim();
    final trimmedPhone = phone.trim();

    if (trimmedFullName.isEmpty ||
        trimmedEmail.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      update((current) => current.copyWith(
            submitMessage: 'Vui lòng nhập đầy đủ các trường bắt buộc.',
            clearErrorMessage: true,
            isSubmitSuccess: false,
          ));
      return;
    }

    if (password != confirmPassword) {
      update((current) => current.copyWith(
            submitMessage: 'Mật khẩu xác nhận không khớp.',
            clearErrorMessage: true,
            isSubmitSuccess: false,
          ));
      return;
    }

    await _submit(
      action: () => _authRepository.register(
        fullName: trimmedFullName,
        email: trimmedEmail,
        password: password,
        phone: trimmedPhone.isEmpty ? null : trimmedPhone,
      ),
      successMessage: 'Tạo tài khoản thành công.',
    );
  }

  Future<void> _submit({
    required Future<void> Function() action,
    required String successMessage,
  }) async {
    if (state.isSubmitting) {
      return;
    }

    update((current) => current.copyWith(
          isSubmitting: true,
          clearErrorMessage: true,
          clearSubmitMessage: true,
          isSubmitSuccess: false,
        ));

    try {
      await action();
      update((current) => current.copyWith(
            isSubmitting: false,
            submitMessage: successMessage,
            clearErrorMessage: true,
            isSubmitSuccess: true,
          ));
      emit(AuthNavTarget.home);
    } on ApiException catch (error) {
      update((current) => current.copyWith(
            isSubmitting: false,
            submitMessage: _readableErrorMessage(error),
            isSubmitSuccess: false,
          ));
    } catch (_) {
      update((current) => current.copyWith(
            isSubmitting: false,
            submitMessage: 'Đã có lỗi xảy ra. Vui lòng thử lại.',
            isSubmitSuccess: false,
          ));
    }
  }

  String _readableErrorMessage(ApiException error) {
    final details = error.details;
    if (details is Map<String, dynamic>) {
      final detail = details['detail'];
      if (detail is List) {
        final messages = detail
            .map((item) => _validationMessage(item))
            .whereType<String>()
            .where((item) => item.trim().isNotEmpty)
            .toSet()
            .toList(growable: false);
        if (messages.isNotEmpty) {
          return messages.join('\n');
        }
      }

      if (detail is String && detail.trim().isNotEmpty) {
        return detail;
      }
    }

    return error.message;
  }

  String? _validationMessage(Object? item) {
    if (item is! Map) {
      return null;
    }

    final map = Map<String, dynamic>.from(item);
    final loc = ((map['loc'] as List?) ?? const [])
        .map((part) => part.toString())
        .toList(growable: false);
    final message = (map['msg'] ?? '').toString();
    if (message.isEmpty) {
      return null;
    }

    final field = loc.isEmpty ? '' : _fieldLabel(loc.last);
    if (field.isEmpty) {
      return message;
    }
    return '$field: $message';
  }

  String _fieldLabel(String raw) {
    switch (raw) {
      case 'fullName':
        return 'Họ và tên';
      case 'email':
        return 'Email';
      case 'phone':
        return 'Số điện thoại';
      case 'password':
        return 'Mật khẩu';
      case 'confirmPassword':
        return 'Nhập lại mật khẩu';
      default:
        return raw;
    }
  }
}
