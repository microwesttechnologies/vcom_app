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
      final inactiveAccountMessage = _buildInactiveAccountMessage(
        response.body,
        request.email,
      );
      if (inactiveAccountMessage != null) {
        throw Exception(inactiveAccountMessage);
      }

      throw Exception(
        _buildServerResponseMessage(
          response,
          defaultMessage: 'Error al realizar el login',
        ),
      );
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
      throw Exception(
        _buildServerResponseMessage(
          response,
          defaultMessage: 'Error al obtener permisos',
        ),
      );
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

  String _buildServerResponseMessage(
    http.Response response, {
    required String defaultMessage,
  }) {
    final serverMessage = _extractErrorMessage(response.body);
    if (serverMessage.isNotEmpty) {
      return '$defaultMessage [HTTP ${response.statusCode}]\n$serverMessage';
    }

    return '$defaultMessage [HTTP ${response.statusCode}]';
  }

  String? _buildInactiveAccountMessage(
    String responseBody,
    String fallbackIdentifier,
  ) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final message = (decoded['message'] ?? '').toString().toLowerCase();
      final account = decoded['account'];
      if (!message.contains('no esta activa') &&
          !message.contains('no está activa')) {
        return null;
      }
      if (account is! Map<String, dynamic>) {
        return null;
      }

      final name = _readString(account['name']);
      final email = _readString(account['email']).isNotEmpty
          ? _readString(account['email'])
          : fallbackIdentifier;
      final username = _resolveUsername(
        account['username'],
        fallbackIdentifier: fallbackIdentifier,
        fallbackEmail: email,
      );

      final displayName = name.isNotEmpty ? name : 'Modelo';
      final displayEmail = email.isNotEmpty ? email : 'No disponible';
      final displayUsername = username.isNotEmpty ? username : 'No disponible';

      return 'Hola, $displayName.\n\n'
          'Nos agrada tu interes en pertenecer a nuestra comunidad; nuestros expertos estan evaluando tu cuenta identificada con esta informacion.\n\n'
          'Nombre: $displayName\n'
          'Correo: $displayEmail\n'
          'Username: $displayUsername\n\n'
          'En breve uno de nuestros expertos activara tu cuenta. Si hay inconsistencias, comunicate por medio del correo Admin@vcom.com.';
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(String responseBody) {
    if (responseBody.trim().isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'] ?? decoded['error'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }

        final errors = decoded['errors'];
        if (errors is Map<String, dynamic>) {
          for (final value in errors.values) {
            if (value is List && value.isNotEmpty) {
              final first = value.first;
              if (first is String && first.trim().isNotEmpty) {
                return first.trim();
              }
            }
            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
        }
      }
    } catch (_) {
      return responseBody.trim();
    }

    return responseBody.trim();
  }

  String _readString(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString().trim();
  }

  String _resolveUsername(
    dynamic value, {
    required String fallbackIdentifier,
    required String fallbackEmail,
  }) {
    final directValue = _readString(value);
    if (directValue.isNotEmpty) {
      return directValue;
    }

    if (fallbackIdentifier.isNotEmpty && !fallbackIdentifier.contains('@')) {
      return fallbackIdentifier;
    }

    if (fallbackEmail.contains('@')) {
      return fallbackEmail.split('@').first;
    }

    return '';
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
