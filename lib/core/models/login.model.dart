/// Modelos de dominio para el login
/// Contiene las entidades y DTOs relacionados con la autenticación

/// Modelo de respuesta del login
class LoginResponse {
  final String token;
  final String tokenType;
  final int expiresIn;

  LoginResponse({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: _parseInt(json['expires_in']),
    );
  }

  /// Convierte un valor a int de forma segura
  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.parse(value);
    return 0;
  }
}

/// Modelo de usuario
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? role;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id_user']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name_user'] as String? ?? json['name'] as String? ?? json['nombre'] as String? ?? '',
      email: json['email_user'] as String? ?? json['email'] as String? ?? '',
      role: json['role_user'] as String? ?? json['role'] as String? ?? json['rol'] as String?,
    );
  }
}

/// Modelo de respuesta de permisos
class PermissionsResponse {
  final UserModel user;
  final Map<String, dynamic>? role;
  final List<Map<String, dynamic>> modules;

  PermissionsResponse({
    required this.user,
    this.role,
    required this.modules,
  });

  factory PermissionsResponse.fromJson(Map<String, dynamic> json) {
    return PermissionsResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      role: json['role'] as Map<String, dynamic>?,
      modules: (json['modules'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList() ?? [],
    );
  }
}

/// Modelo de request de login
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

