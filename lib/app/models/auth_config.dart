import 'auth_models.dart';

class AuthConfig {
  const AuthConfig({
    this.accessToken,
    this.user,
  });

  final String? accessToken;
  final AuthUser? user;

  bool get isLogin => accessToken != null && accessToken!.trim().isNotEmpty;
}
