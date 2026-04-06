import 'package:vcom_app/core/models/module.model.dart';

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
      name:
          json['name_user'] as String? ??
          json['name'] as String? ??
          json['nombre'] as String? ??
          '',
      email: json['email_user'] as String? ?? json['email'] as String? ?? '',
      role:
          json['role_user'] as String? ??
          json['role'] as String? ??
          json['rol'] as String?,
    );
  }
}

/// Modelo de respuesta de permisos
class PermissionsResponse {
  final UserModel user;
  final Map<String, dynamic>? role;
  final List<ModuleModel> modules;

  PermissionsResponse({required this.user, this.role, required this.modules});

  factory PermissionsResponse.fromJson(Map<String, dynamic> json) {
    final rawUser = json['user'];
    final rawRole = json['role'];

    return PermissionsResponse(
      user: UserModel.fromJson(
        rawUser is Map<String, dynamic> ? rawUser : const {},
      ),
      role: rawRole is Map<String, dynamic> ? rawRole : null,
      modules: _parseModules(json),
    );
  }

  static List<ModuleModel> _parseModules(Map<String, dynamic> json) {
    final collected = <ModuleModel>[];
    final visited = <Object>{};

    void visit(dynamic node) {
      if (node == null) return;
      if (visited.contains(node)) return;
      visited.add(node as Object);

      if (node is List) {
        for (final item in node) {
          visit(item);
        }
        return;
      }

      if (node is! Map<String, dynamic>) return;

      if (_looksLikeModulePayload(node)) {
        collected.add(ModuleModel.fromJson(node));
      }

      const nestedKeys = [
        'modules',
        'data',
        'module',
        'children',
        'items',
        'menu',
        'submodules',
        'subModules',
        'permissions',
        'permissions_by_module',
        'modules_by_module',
      ];

      for (final key in nestedKeys) {
        if (node.containsKey(key)) {
          visit(node[key]);
        }
      }
    }

    visit(json);

    final uniqueByIdOrRoute = <String, ModuleModel>{};
    for (final module in collected) {
      final dedupeKey =
          '${module.idModule}|${module.route.trim().toLowerCase()}|${module.nameModule.trim().toLowerCase()}';
      uniqueByIdOrRoute[dedupeKey] = module;
    }

    return uniqueByIdOrRoute.values.toList(growable: false);
  }

  static bool _looksLikeModulePayload(Map<String, dynamic> json) {
    return json.containsKey('id_module') ||
        json.containsKey('name_module') ||
        json.containsKey('permissions');
  }
}

/// Modelo de request de login
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}
