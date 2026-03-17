import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/session_state_registry.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/core/models/login.model.dart';
import 'package:vcom_app/core/models/module.model.dart';
import 'package:vcom_app/pages/auth/login.page.dart';

/// Servicio para gestionar el token de autenticación, el rol derivado del JWT
/// y los permisos cargados desde el backend.
class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  String? _token;
  String? _userName;
  String? _userId;
  Map<String, dynamic>? _jwtClaims;
  PermissionsResponse? _permissionsResponse;
  List<ModuleModel> _modules = const [];
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _handlingSessionExpiration = false;

  /// Guarda el token de autenticación y decodifica sus claims.
  void setToken(String token) {
    _token = token;
    _jwtClaims = _decodeJwtPayload(token);
    SessionCacheService().bindToken(token);
  }

  /// Obtiene el token de autenticación.
  String? getToken() {
    if (isTokenExpired()) {
      unawaited(
        expireSession(message: 'Tu sesion expiro. Inicia sesion nuevamente.'),
      );
      return null;
    }
    return _token;
  }

  /// Guarda los permisos recibidos desde el backend y actualiza los datos de usuario.
  void setPermissions(PermissionsResponse response) {
    _permissionsResponse = response;
    _modules = List.unmodifiable(response.modules);

    if (response.user.name.trim().isNotEmpty) {
      _userName = response.user.name.trim();
    }
    if (response.user.id.trim().isNotEmpty) {
      _userId = response.user.id.trim();
    }
  }

  PermissionsResponse? getPermissionsResponse() {
    return _permissionsResponse;
  }

  List<ModuleModel> getModules() {
    return _modules;
  }

  bool hasPermissions() {
    return _modules.isNotEmpty;
  }

  /// Obtiene el rol del usuario únicamente desde el JWT.
  String? getRole() {
    return _stringClaim(const [
      ['role'],
      ['role_user'],
      ['rol'],
      ['user', 'role'],
      ['user', 'role_user'],
      ['data', 'role'],
      ['data', 'role_user'],
      ['app_metadata', 'role'],
      ['realm_access', 'role'],
      ['realm_access', 'roles'],
      ['roles'],
      ['authorities'],
    ]);
  }

  /// Guarda el nombre del usuario como fallback para JWTs que no lo incluyan.
  void setUserName(String name) {
    _userName = name;
  }

  /// Obtiene el nombre del usuario; prioriza el JWT y usa el backend como fallback.
  String? getUserName() {
    return _stringClaim(const [
          ['name_user'],
          ['name'],
          ['nombre'],
          ['user', 'name'],
          ['user', 'name_user'],
          ['preferred_username'],
        ]) ??
        _userName;
  }

  /// Guarda el ID del usuario como fallback para JWTs que no lo incluyan.
  void setUserId(String id) {
    _userId = id;
  }

  /// Obtiene el ID del modelo/usuario.
  /// Prioriza claims explícitos tipo `id_user` y usa el backend como fuente principal
  /// antes de caer en claims genéricos como `sub`.
  String? getUserId() {
    return _stringClaim(const [
          ['id_user'],
          ['user', 'id_user'],
          ['data', 'id_user'],
        ]) ??
        _userId ??
        _stringClaim(const [
          ['id'],
          ['user', 'id'],
          ['data', 'id'],
          ['sub'],
        ]) ??
        _userId;
  }

  /// Verifica si hay un token guardado.
  bool hasToken() {
    return getToken() != null;
  }

  bool isTokenExpired() {
    final token = _token;
    if (token == null || token.isEmpty) return false;

    final expValue = _readClaimPath(const ['exp']);
    if (expValue is! num) return false;

    final nowInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowInSeconds >= expValue.toInt();
  }

  Future<void> handleExpiredTokenIfNeeded() async {
    if (isTokenExpired()) {
      await expireSession(
        message: 'Tu sesion expiro. Inicia sesion nuevamente.',
      );
    }
  }

  void handleUnauthorizedStatus(
    int statusCode, {
    String message = 'Tu sesion expiro. Inicia sesion nuevamente.',
  }) {
    if (statusCode != 401) return;
    unawaited(expireSession(message: message));
  }

  /// Limpia todos los datos de autenticación.
  void clear() {
    unawaited(SessionCacheService().clearSession());
    SessionStateRegistryService().clearAll();
    _token = null;
    _userName = null;
    _userId = null;
    _jwtClaims = null;
    _permissionsResponse = null;
    _modules = const [];
  }

  /// Obtiene el header de autorización para las peticiones HTTP.
  Map<String, String> getAuthHeaders() {
    final token = getToken();
    if (token == null) {
      return {};
    }
    return {'Authorization': 'Bearer $token'};
  }

  Future<void> expireSession({
    String message = 'Tu sesion expiro. Inicia sesion nuevamente.',
  }) async {
    if (_handlingSessionExpiration) return;
    _handlingSessionExpiration = true;

    try {
      await UserStatusService().setOffline();
    } catch (_) {}

    clear();

    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = navigatorKey.currentContext;
        final messenger = context != null
            ? ScaffoldMessenger.maybeOf(context)
            : null;
        messenger?.showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      });
    }

    _handlingSessionExpiration = false;
  }

  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length < 2) return null;

      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payload);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return null;
  }

  String? _stringClaim(List<List<String>> claimPaths) {
    if (_jwtClaims == null) return null;

    for (final path in claimPaths) {
      final value = _readClaimPath(path);
      final normalized = _normalizeClaimValue(value);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  dynamic _readClaimPath(List<String> path) {
    dynamic current = _jwtClaims;

    for (final segment in path) {
      if (current is Map<String, dynamic> && current.containsKey(segment)) {
        current = current[segment];
      } else {
        return null;
      }
    }

    return current;
  }

  String? _normalizeClaimValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.trim();
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      const priorityRoles = ['MODELO', 'MONITOR', 'MODAL', 'ADMIN'];
      for (final priorityRole in priorityRoles) {
        final match = value
            .map(_normalizeClaimValue)
            .whereType<String>()
            .firstWhere(
              (entry) => entry.toUpperCase() == priorityRole,
              orElse: () => '',
            );
        if (match.isNotEmpty) {
          return match;
        }
      }

      for (final entry in value) {
        final normalized = _normalizeClaimValue(entry);
        if (normalized != null && normalized.isNotEmpty) {
          return normalized;
        }
      }
    }
    return null;
  }
}
