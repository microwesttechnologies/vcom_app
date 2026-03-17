import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/login.model.dart';

import 'login.gateway.dart';

/// Implementacion del gateway de login.
class LoginGatewayImpl implements LoginGateway {
  final String baseUrl;
  static const Duration _requestTimeout = Duration(seconds: 120);

  LoginGatewayImpl({String? baseUrl})
    : baseUrl = baseUrl ?? EnvironmentDev.baseUrl;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    final url = Uri.parse('$baseUrl${EnvironmentDev.authLogin}');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw Exception(
                'Tiempo de espera agotado en login. '
                'El backend no respondio dentro de ${_requestTimeout.inSeconds}s.',
              );
            },
          );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return LoginResponse.fromJson(jsonResponse);
      }
      if (response.statusCode == 401) {
        throw Exception('Credenciales invalidas');
      }
      if (response.statusCode == 422) {
        throw Exception('Error de validacion');
      }

      throw Exception('Error al realizar el login: ${response.statusCode}');
    } on SocketException catch (e) {
      throw Exception(
        'Error de red en login: ${e.message}. '
        'Verifica internet y acceso a $baseUrl',
      );
    } on HandshakeException catch (e) {
      throw Exception(
        'Error SSL/TLS en login: ${e.message}. '
        'La app no pudo establecer conexion segura con $baseUrl',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Error de conexion en login: ${e.message}. '
        'Verifica acceso a $baseUrl',
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado en login: $e');
    }
  }

  /// Obtiene los permisos y datos del usuario autenticado.
  @override
  Future<PermissionsResponse> getPermissions(String token) async {
    final url = Uri.parse('$baseUrl${EnvironmentDev.authPermissions}');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            _requestTimeout,
            onTimeout: () {
              throw Exception(
                'Tiempo de espera agotado al consultar permisos. '
                'El backend no respondio dentro de ${_requestTimeout.inSeconds}s.',
              );
            },
          );
      TokenService().handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return PermissionsResponse.fromJson(jsonResponse);
      }
      if (response.statusCode == 401) {
        throw Exception('No autenticado');
      }
      if (response.statusCode == 404) {
        throw Exception('Usuario no encontrado');
      }

      throw Exception('Error al obtener permisos: ${response.statusCode}');
    } on SocketException catch (e) {
      throw Exception(
        'Error de red al consultar permisos: ${e.message}. '
        'Verifica internet y acceso a $baseUrl',
      );
    } on HandshakeException catch (e) {
      throw Exception(
        'Error SSL/TLS al consultar permisos: ${e.message}. '
        'La app no pudo establecer conexion segura con $baseUrl',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Error de conexion al consultar permisos: ${e.message}. '
        'Verifica acceso a $baseUrl',
      );
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al consultar permisos: $e');
    }
  }
}

/// Servicio de login (caso de uso).
class LoginService {
  final LoginGateway _gateway;

  LoginService({LoginGateway? gateway})
    : _gateway = gateway ?? LoginGatewayImpl();

  /// Ejecuta el login.
  Future<LoginResponse> executeLogin(String email, String password) async {
    final request = LoginRequest(email: email, password: password);
    return _gateway.login(request);
  }

  /// Obtiene los permisos y datos del usuario despues del login.
  Future<PermissionsResponse> getPermissions(String token) async {
    return _gateway.getPermissions(token);
  }
}
