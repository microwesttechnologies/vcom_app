import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcom_app/core/common/app_routes.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/session_state_registry.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/core/models/login.model.dart';
import 'package:vcom_app/core/models/module.model.dart';

/// Servicio para gestionar el token de autenticación, el rol derivado del JWT
/// y los permisos cargados desde el backend.
class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  static const String _prefsTokenKey = 'auth_token';
  static const String _prefsUserNameKey = 'auth_user_name';
  static const String _prefsUserIdKey = 'auth_user_id';

  String? _token;
  String? _userName;
  String? _userId;
  Map<String, dynamic>? _jwtClaims;
  PermissionsResponse? _permissionsResponse;
  List<ModuleModel> _modules = const [];
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  bool _handlingSessionExpiration = false;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_prefsTokenKey);
    final savedUserName = prefs.getString(_prefsUserNameKey);
    final savedUserId = prefs.getString(_prefsUserIdKey);

    if (savedToken != null && savedToken.trim().isNotEmpty) {
      _token = savedToken.trim();
      _jwtClaims = _decodeJwtPayload(_token!);
      SessionCacheService().bindToken(_token!);
    }

    if (savedUserName != null && savedUserName.trim().isNotEmpty) {
      _userName = savedUserName.trim();
    }

    if (savedUserId != null && savedUserId.trim().isNotEmpty) {
      _userId = savedUserId.trim();
    }

    _initialized = true;
  }

  /// Guarda el token de autenticación y decodifica sus claims.
  void setToken(String token) {
    final normalizedToken = token.trim();
    _token = normalizedToken;
    _jwtClaims = _decodeJwtPayload(normalizedToken);
    SessionCacheService().bindToken(normalizedToken);
    unawaited(_persistSession());
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

    unawaited(_persistSession());
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
    unawaited(_persistSession());
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
    unawaited(_persistSession());
  }

  /// Obtiene el ID del modelo/usuario.
  /// Prioriza claims explícitos tipo `id_user` y usa el backend como fuente principal
  /// antes de caer en claims genéricos como `sub`.
  String? getUserId() {
    final raw =
        _stringClaim(const [
          ['id_user'],
          ['user_id'],
          ['user', 'id_user'],
          ['user', 'user_id'],
          ['data', 'id_user'],
          ['data', 'user_id'],
        ]) ??
        _userId ??
        _stringClaim(const [
          ['id'],
          ['user', 'id'],
          ['data', 'id'],
          ['sub'],
        ]) ??
        _userId;

    return _normalizeUserId(raw);
  }

  String? _normalizeUserId(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;

    // JWT "sub" puede llegar como "model:9" o "employee:uuid".
    final parts = trimmed.split(':');
    if (parts.length == 2 && parts[1].trim().isNotEmpty) {
      return parts[1].trim();
    }

    return trimmed;
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
    _initialized = false;
    unawaited(_clearPersistedSession());
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
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);

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

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (_token != null && _token!.trim().isNotEmpty) {
      await prefs.setString(_prefsTokenKey, _token!.trim());
    } else {
      await prefs.remove(_prefsTokenKey);
    }

    if (_userName != null && _userName!.trim().isNotEmpty) {
      await prefs.setString(_prefsUserNameKey, _userName!.trim());
    } else {
      await prefs.remove(_prefsUserNameKey);
    }

    if (_userId != null && _userId!.trim().isNotEmpty) {
      await prefs.setString(_prefsUserIdKey, _userId!.trim());
    } else {
      await prefs.remove(_prefsUserIdKey);
    }
  }

  Future<void> _clearPersistedSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTokenKey);
    await prefs.remove(_prefsUserNameKey);
    await prefs.remove(_prefsUserIdKey);
  }
}
