import '../models/auth_page_models.dart';
import '../network/base_api_repository.dart';

enum AuthPageType { login, register }

abstract class AuthPageRepository {
  Future<AuthPageResponse> fetchPage(AuthPageType pageType);
}

class ApiAuthPageRepository extends BaseApiRepository
    implements AuthPageRepository {
  ApiAuthPageRepository(super.apiClient);

  AuthPageResponse? _loginCache;
  AuthPageResponse? _registerCache;

  @override
  Future<AuthPageResponse> fetchPage(AuthPageType pageType) async {
    final cached = _cacheFor(pageType);
    if (cached != null) {
      return cached;
    }

    if (!apiClient.config.hasBaseUrl) {
      return _cache(pageType, _fallback(pageType));
    }

    try {
      final response = await apiClient.get<AuthPageResponse>(
        '/auth/pages/${pageType.name}',
        decoder: (json) => readItem(
          _unwrapItemPayload(json),
          AuthPageResponse.fromJson,
        ),
      );
      return _cache(pageType, response.data);
    } catch (_) {
      return _cache(pageType, _fallback(pageType));
    }
  }

  AuthPageResponse? _cacheFor(AuthPageType pageType) {
    switch (pageType) {
      case AuthPageType.login:
        return _loginCache;
      case AuthPageType.register:
        return _registerCache;
    }
  }

  AuthPageResponse _cache(AuthPageType pageType, AuthPageResponse response) {
    switch (pageType) {
      case AuthPageType.login:
        _loginCache = response;
        break;
      case AuthPageType.register:
        _registerCache = response;
        break;
    }
    return response;
  }

  AuthPageResponse _fallback(AuthPageType pageType) {
    switch (pageType) {
      case AuthPageType.login:
        return defaultLoginPageResponse;
      case AuthPageType.register:
        return defaultRegisterPageResponse;
    }
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    return json;
  }
}

const AuthPageResponse defaultLoginPageResponse = AuthPageResponse(
  headerBrand: 'PIXEL BAKERY',
  headerTitle: 'ĐĂNG NHẬP',
  introTitle: 'Chào mừng quay lại',
  introDescription:
      'Đăng nhập để xem ưu đãi cá nhân và lịch sử đơn hàng của bạn.',
  fields: [
    AuthFieldConfig(label: 'Email hoặc số điện thoại'),
    AuthFieldConfig(label: 'Mật khẩu'),
  ],
  helpText: 'Quên mật khẩu?',
  primaryActionLabel: 'Đăng nhập',
  socialActionLabel: 'Đăng nhập với Google',
  switchPrompt: 'Chưa có tài khoản?',
  switchActionLabel: 'Đăng ký',
  footerTagline: 'PIXEL BAKERY | SIGN IN',
);

const AuthPageResponse defaultRegisterPageResponse = AuthPageResponse(
  headerBrand: 'PIXEL BAKERY',
  headerTitle: 'ĐĂNG KÝ',
  introTitle: 'Tạo tài khoản mới',
  introDescription:
      'Đăng ký để nhận ưu đãi độc quyền và theo dõi đơn hàng nhanh hơn.',
  fields: [
    AuthFieldConfig(label: 'Họ và tên'),
    AuthFieldConfig(label: 'Email'),
    AuthFieldConfig(label: 'Số điện thoại'),
    AuthFieldConfig(label: 'Mật khẩu'),
    AuthFieldConfig(label: 'Nhập lại mật khẩu'),
  ],
  primaryActionLabel: 'Tạo tài khoản',
  socialActionLabel: 'Đăng ký với Google',
  switchPrompt: 'Đã có tài khoản?',
  switchActionLabel: 'Đăng nhập',
  footerTagline: 'PIXEL BAKERY | SIGN UP',
);
