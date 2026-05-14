class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.address,
    this.addresses = const [],
    this.role = 'customer',
    this.permissions = const [],
    this.isAdmin = false,
    this.points = 0,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? address;
  final List<String> addresses;
  final String role;
  final List<String> permissions;
  final bool isAdmin;
  final int points;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone']?.toString(),
      address: json['address']?.toString(),
      addresses: (json['addresses'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      role: (json['role'] ?? 'customer').toString(),
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
      isAdmin: json['isAdmin'] == true,
      points: (json['points'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'addresses': addresses,
      'role': role,
      'permissions': permissions,
      'isAdmin': isAdmin,
      'points': points,
    };
  }

  AuthUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? address,
    List<String>? addresses,
    String? role,
    List<String>? permissions,
    bool? isAdmin,
    int? points,
    bool clearPhone = false,
    bool clearAddress = false,
  }) {
    return AuthUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: clearPhone ? null : (phone ?? this.phone),
      address: clearAddress ? null : (address ?? this.address),
      addresses: addresses ?? this.addresses,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isAdmin: isAdmin ?? this.isAdmin,
      points: points ?? this.points,
    );
  }

  bool hasPermission(String permission) {
    if (isAdmin || permissions.contains('*')) {
      return true;
    }
    return permissions.contains(permission);
  }

  bool hasAnyPermission(Iterable<String> requiredPermissions) {
    if (isAdmin || permissions.contains('*')) {
      return true;
    }
    for (final permission in requiredPermissions) {
      if (permissions.contains(permission)) {
        return true;
      }
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    return other is AuthUser &&
        other.id == id &&
        other.fullName == fullName &&
        other.email == email &&
        other.phone == phone &&
        other.address == address &&
        _samePermissions(other.addresses, addresses) &&
        other.role == role &&
        _samePermissions(other.permissions, permissions) &&
        other.isAdmin == isAdmin &&
        other.points == points;
  }

  @override
  int get hashCode => Object.hash(
        id,
        fullName,
        email,
        phone,
        address,
        Object.hashAll(addresses),
        role,
        Object.hashAll(permissions),
        isAdmin,
        points,
      );
}

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.accessTokenExpiresAt,
    required this.refreshTokenExpiresAt,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final DateTime accessTokenExpiresAt;
  final DateTime refreshTokenExpiresAt;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: (json['accessToken'] ?? '').toString(),
      refreshToken: (json['refreshToken'] ?? '').toString(),
      tokenType: (json['tokenType'] ?? 'bearer').toString(),
      accessTokenExpiresAt: DateTime.tryParse(
            (json['accessTokenExpiresAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      refreshTokenExpiresAt: DateTime.tryParse(
            (json['refreshTokenExpiresAt'] ?? '').toString(),
          ) ??
          DateTime.now(),
      user: AuthUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'accessTokenExpiresAt': accessTokenExpiresAt.toIso8601String(),
      'refreshTokenExpiresAt': refreshTokenExpiresAt.toIso8601String(),
      'user': user.toJson(),
    };
  }
}

class PasswordResetRequestResult {
  const PasswordResetRequestResult({
    required this.message,
    this.debugToken,
  });

  final String message;
  final String? debugToken;

  factory PasswordResetRequestResult.fromJson(Map<String, dynamic> json) {
    return PasswordResetRequestResult(
      message: (json['message'] ?? '').toString(),
      debugToken: json['debugToken']?.toString(),
    );
  }
}

bool _samePermissions(List<String> left, List<String> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
