import '../models/auth_models.dart';
import '../network/api_exception.dart';
import '../network/base_api_repository.dart';
import '../services/auth_session.dart';
import '../services/cart_session.dart';

abstract class AuthRepository {
  Future<AuthUser> fetchMe();
  Future<bool> refreshSession();
  Future<void> logout();
  Future<PasswordResetRequestResult> requestPasswordReset(String email);
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  });
  Future<AuthUser> updateAddress(String address);
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AuthResult> login({
    required String email,
    required String password,
  });

  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  });
}

class ApiAuthRepository extends BaseApiRepository implements AuthRepository {
  ApiAuthRepository(super.apiClient, this._session, this._cartSession);

  final AuthSession _session;
  final CartSession _cartSession;

  @override
  Future<AuthUser> fetchMe() async {
    final response = await apiClient.get<AuthUser>(
      '/auth/me',
      requiresAuth: true,
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AuthUser.fromJson,
      ),
    );
    _session.updateUser(response.data);
    return response.data;
  }

  @override
  Future<AuthUser> updateAddress(String address) async {
    final response = await apiClient.patch<AuthUser>(
      '/auth/me',
      requiresAuth: true,
      body: {
        'address': address,
      },
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AuthUser.fromJson,
      ),
    );
    _session.updateUser(response.data);
    return response.data;
  }

  @override
  Future<String> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await apiClient.post<String>(
      '/auth/change-password',
      requiresAuth: true,
      body: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
      decoder: (json) {
        final payload = _unwrapItemPayload(json);
        if (payload is Map<String, dynamic>) {
          return (payload['message'] ?? 'Cập nhật mật khẩu thành công.')
              .toString();
        }
        return 'Cập nhật mật khẩu thành công.';
      },
    );
    return response.data;
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post<AuthResult>(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AuthResult.fromJson,
      ),
    );
    _session.save(
      accessToken: response.data.accessToken,
      refreshToken: response.data.refreshToken,
      accessTokenExpiresAt: response.data.accessTokenExpiresAt.toUtc(),
      refreshTokenExpiresAt: response.data.refreshTokenExpiresAt.toUtc(),
      user: response.data.user,
    );
    try {
      await _cartSession.syncAfterLogin();
    } catch (_) {}
    return response.data;
  }

  @override
  Future<AuthResult> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final response = await apiClient.post<AuthResult>(
      '/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
      },
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        AuthResult.fromJson,
      ),
    );
    _session.save(
      accessToken: response.data.accessToken,
      refreshToken: response.data.refreshToken,
      accessTokenExpiresAt: response.data.accessTokenExpiresAt.toUtc(),
      refreshTokenExpiresAt: response.data.refreshTokenExpiresAt.toUtc(),
      user: response.data.user,
    );
    try {
      await _cartSession.syncAfterLogin();
    } catch (_) {}
    return response.data;
  }

  Object? _unwrapItemPayload(Object? json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'] ?? json['item'];
      return data ?? json;
    }
    throw const ApiException(
      message: 'Invalid auth response payload',
      code: 'invalid_auth_payload',
    );
  }

  @override
  Future<bool> refreshSession() async {
    final refreshToken = _session.refreshToken;
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      return false;
    }
    try {
      final response = await apiClient.post<AuthResult>(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
        decoder: (json) => readItem(
          _unwrapItemPayload(json),
          AuthResult.fromJson,
        ),
      );
      _session.save(
        accessToken: response.data.accessToken,
        refreshToken: response.data.refreshToken,
        accessTokenExpiresAt: response.data.accessTokenExpiresAt.toUtc(),
        refreshTokenExpiresAt: response.data.refreshTokenExpiresAt.toUtc(),
        user: response.data.user,
      );
      return true;
    } catch (_) {
      _session.clear();
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      await apiClient.post<String>(
        '/auth/logout',
        requiresAuth: true,
        decoder: (_) => 'ok',
      );
    } catch (_) {}
    _session.clear();
  }

  @override
  Future<PasswordResetRequestResult> requestPasswordReset(String email) async {
    final response = await apiClient.post<PasswordResetRequestResult>(
      '/auth/forgot-password',
      body: {'email': email},
      decoder: (json) => readItem(
        _unwrapItemPayload(json),
        PasswordResetRequestResult.fromJson,
      ),
    );
    return response.data;
  }

  @override
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final response = await apiClient.post<String>(
      '/auth/reset-password',
      body: {
        'token': token,
        'newPassword': newPassword,
      },
      decoder: (json) {
        final payload = _unwrapItemPayload(json);
        if (payload is Map<String, dynamic>) {
          return (payload['message'] ?? 'Đặt lại mật khẩu thành công.')
              .toString();
        }
        return 'Đặt lại mật khẩu thành công.';
      },
    );
    return response.data;
  }
}
