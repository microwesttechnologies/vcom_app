import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Interceptor que inyecta el token JWT en cada request
///
/// Responsabilidades:
/// - Obtener token del secure storage
/// - Agregar header Authorization: Bearer {token}
/// - Manejar tokens expirados (en pareja con ErrorInterceptor)
class TokenInterceptor extends Interceptor {
  static const String _tokenKey = 'auth_token';
  static const _secureStorage = FlutterSecureStorage();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Obtener token del secure storage
      final token = await _secureStorage.read(key: _tokenKey);

      if (token != null && token.isNotEmpty) {
        // Agregar token al header Authorization
        options.headers['Authorization'] = 'Bearer $token';
      }

      // Continuar con el request
      return handler.next(options);
    } catch (e) {
      // Si hay error al obtener token, permitir continuar sin él
      return handler.next(options);
    }
  }

  /// Guardar token (llamar desde LoginController)
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  /// Eliminar token (llamar desde LogoutController)
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }

  /// Obtener token actual
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }
}
