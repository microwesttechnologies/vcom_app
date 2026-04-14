import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/login.model.dart';

import 'login_error_parser.dart';
import 'login.gateway.dart';

class LoginHttpGateway implements LoginGateway {
  static const Duration _timeout = Duration(seconds: 120);
  final String baseUrl;

  LoginHttpGateway({String? baseUrl})
    : baseUrl = baseUrl ?? EnvironmentDev.baseUrl;

  @override
  Future<LoginResponse> login(LoginRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${EnvironmentDev.authLogin}'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(jsonDecode(response.body));
      }

      final inactiveMessage = LoginErrorParser.buildInactiveAccountMessage(
        responseBody: response.body,
        fallbackIdentifier: request.email,
      );
      if (inactiveMessage != null) throw Exception(inactiveMessage);

      throw Exception(
        LoginErrorParser.buildServerResponseMessage(
          response,
          defaultMessage: 'Error al realizar el login',
        ),
      );
    } on SocketException catch (e) {
      throw Exception('Error de red en login: ${e.message}');
    } on HandshakeException catch (e) {
      throw Exception('Error SSL/TLS en login: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión en login: ${e.message}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado en login: $e');
    }
  }

  @override
  Future<PermissionsResponse> getPermissions(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl${EnvironmentDev.authPermissions}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);
      TokenService().handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        return PermissionsResponse.fromJson(jsonDecode(response.body));
      }

      throw Exception(
        LoginErrorParser.buildServerResponseMessage(
          response,
          defaultMessage: 'Error al obtener permisos',
        ),
      );
    } on SocketException catch (e) {
      throw Exception('Error de red al consultar permisos: ${e.message}');
    } on HandshakeException catch (e) {
      throw Exception('Error SSL/TLS al consultar permisos: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception('Error de conexión al consultar permisos: ${e.message}');
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error inesperado al consultar permisos: $e');
    }
  }
}
