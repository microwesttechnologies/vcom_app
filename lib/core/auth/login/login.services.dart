import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/models/login.model.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'login.gateway.dart';

/// Implementación del gateway de login
class LoginGatewayImpl implements LoginGateway {
  final String baseUrl;

  LoginGatewayImpl({String? baseUrl})
      : baseUrl = baseUrl ?? EnvironmentDev.baseUrl;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final url = Uri.parse('$baseUrl${EnvironmentDev.authLogin}');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifica que el servidor esté corriendo en $baseUrl');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('Credenciales inválidas');
      } else if (response.statusCode == 422) {
        throw Exception('Error de validación');
      } else {
        throw Exception('Error al realizar el login: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: ${e.message}. Verifica que el servidor esté corriendo en $baseUrl');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtiene los permisos y datos del usuario autenticado
  Future<PermissionsResponse> getPermissions(String token) async {
    final url = Uri.parse('$baseUrl${EnvironmentDev.authPermissions}');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. Verifica que el servidor esté corriendo en $baseUrl');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return PermissionsResponse.fromJson(jsonResponse);
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      } else {
        throw Exception('Error al obtener permisos: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión: ${e.message}. Verifica que el servidor esté corriendo en $baseUrl');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }
}

/// Servicio de login (Caso de uso)
class LoginService {
  final LoginGateway _gateway;

  LoginService({LoginGateway? gateway})
      : _gateway = gateway ?? LoginGatewayImpl();

  /// Ejecuta el login
  Future<LoginResponse> executeLogin(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    return await _gateway.login(request);
  }

  /// Obtiene los permisos y datos del usuario después del login
  Future<PermissionsResponse> getPermissions(String token) async {
    return await _gateway.getPermissions(token);
  }
}

