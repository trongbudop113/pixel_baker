import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_config.dart';
import '../models/auth_models.dart';

class AuthSession extends ChangeNotifier {
  static const _accessTokenKey = 'auth.access_token';
  static const _refreshTokenKey = 'auth.refresh_token';
  static const _accessTokenExpiresAtKey = 'auth.access_token_expires_at';
  static const _refreshTokenExpiresAtKey = 'auth.refresh_token_expires_at';
  static const _userKey = 'auth.user';

  String? _accessToken;
  String? _refreshToken;
  DateTime? _accessTokenExpiresAt;
  DateTime? _refreshTokenExpiresAt;
  AuthUser? _currentUser;
  SharedPreferences? _preferences;
  Future<bool> Function()? _refreshHandler;
  Future<bool>? _refreshingFuture;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  DateTime? get accessTokenExpiresAt => _accessTokenExpiresAt;
  DateTime? get refreshTokenExpiresAt => _refreshTokenExpiresAt;
  AuthUser? get currentUser => _currentUser;
  bool get isAuthenticated =>
      _accessToken != null && _accessToken!.trim().isNotEmpty;
  AuthConfig get authConfig => AuthConfig(
        accessToken: _accessToken,
        user: _currentUser,
      );

  Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
    await _restore();
  }

  void attachRefreshHandler(Future<bool> Function() handler) {
    _refreshHandler = handler;
  }

  void save({
    required String accessToken,
    required String refreshToken,
    required DateTime accessTokenExpiresAt,
    required DateTime refreshTokenExpiresAt,
    required AuthUser user,
  }) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _accessTokenExpiresAt = accessTokenExpiresAt;
    _refreshTokenExpiresAt = refreshTokenExpiresAt;
    _currentUser = user;
    notifyListeners();
    unawaited(_persist());
  }

  void updateUser(AuthUser user) {
    _currentUser = user;
    notifyListeners();
    unawaited(_persist());
  }

  void clear() {
    _accessToken = null;
    _refreshToken = null;
    _accessTokenExpiresAt = null;
    _refreshTokenExpiresAt = null;
    _currentUser = null;
    notifyListeners();
    unawaited(_clearPersisted());
  }

  Future<bool> ensureFreshAccessToken({bool force = false}) async {
    final refreshHandler = _refreshHandler;
    if (refreshHandler == null) {
      return false;
    }
    if (!force && !_shouldRefreshAccessToken()) {
      return true;
    }
    final inFlight = _refreshingFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = refreshHandler();
    _refreshingFuture = future;
    try {
      return await future;
    } finally {
      _refreshingFuture = null;
    }
  }

  bool get hasValidRefreshToken {
    final token = _refreshToken;
    final expiresAt = _refreshTokenExpiresAt;
    if (token == null || token.trim().isEmpty || expiresAt == null) {
      return false;
    }
    return expiresAt.isAfter(DateTime.now().toUtc());
  }

  Future<void> _restore() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    final storedToken = preferences.getString(_accessTokenKey);
    final storedRefreshToken = preferences.getString(_refreshTokenKey);
    final storedUser = preferences.getString(_userKey);
    final storedAccessTokenExpiresAt =
        preferences.getString(_accessTokenExpiresAtKey);
    final storedRefreshTokenExpiresAt =
        preferences.getString(_refreshTokenExpiresAtKey);

    _accessToken = storedToken;
    _refreshToken = storedRefreshToken;
    _accessTokenExpiresAt = _parseDate(storedAccessTokenExpiresAt);
    _refreshTokenExpiresAt = _parseDate(storedRefreshTokenExpiresAt);
    if (storedUser == null || storedUser.trim().isEmpty) {
      _currentUser = null;
      return;
    }

    try {
      final decoded = jsonDecode(storedUser);
      if (decoded is Map<String, dynamic>) {
        _currentUser = AuthUser.fromJson(decoded);
      } else if (decoded is Map) {
        _currentUser = AuthUser.fromJson(Map<String, dynamic>.from(decoded));
      } else {
        _currentUser = null;
      }
    } catch (_) {
      _currentUser = null;
      await _clearPersisted();
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }

    final token = _accessToken;
    final refreshToken = _refreshToken;
    final user = _currentUser;

    if (token == null ||
        token.trim().isEmpty ||
        refreshToken == null ||
        refreshToken.trim().isEmpty ||
        user == null) {
      await _clearPersisted();
      return;
    }

    await preferences.setString(_accessTokenKey, token);
    await preferences.setString(_refreshTokenKey, refreshToken);
    if (_accessTokenExpiresAt != null) {
      await preferences.setString(
        _accessTokenExpiresAtKey,
        _accessTokenExpiresAt!.toIso8601String(),
      );
    }
    if (_refreshTokenExpiresAt != null) {
      await preferences.setString(
        _refreshTokenExpiresAtKey,
        _refreshTokenExpiresAt!.toIso8601String(),
      );
    }
    await preferences.setString(_userKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearPersisted() async {
    final preferences = _preferences;
    if (preferences == null) {
      return;
    }
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_accessTokenExpiresAtKey);
    await preferences.remove(_refreshTokenExpiresAtKey);
    await preferences.remove(_userKey);
  }

  bool _shouldRefreshAccessToken() {
    final token = _accessToken;
    final expiresAt = _accessTokenExpiresAt;
    if (token == null || token.trim().isEmpty) {
      return false;
    }
    if (expiresAt == null) {
      return false;
    }
    final now = DateTime.now().toUtc();
    return expiresAt.isBefore(now.add(const Duration(minutes: 2)));
  }

  DateTime? _parseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }
}
