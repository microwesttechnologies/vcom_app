import 'dart:convert';

import 'package:http/http.dart' as http;

class LoginErrorParser {
  const LoginErrorParser._();

  static String extractErrorMessage(String body) {
    if (body.trim().isEmpty) return '';

    try {
      final decoded = jsonDecode(body);
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
      return body.trim();
    }

    return body.trim();
  }

  static String buildServerResponseMessage(
    http.Response response, {
    required String defaultMessage,
  }) {
    final serverMessage = extractErrorMessage(response.body);
    if (serverMessage.isNotEmpty) {
      return '$defaultMessage [HTTP ${response.statusCode}]\n$serverMessage';
    }

    return '$defaultMessage [HTTP ${response.statusCode}]';
  }

  static String? buildInactiveAccountMessage({
    required String responseBody,
    required String fallbackIdentifier,
  }) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) return null;

      final message = (decoded['message'] ?? '').toString().toLowerCase();
      final account = decoded['account'];
      if (!message.contains('no esta activa') &&
          !message.contains('no está activa')) {
        return null;
      }
      if (account is! Map<String, dynamic>) return null;

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
          'Nos agrada tu interes en pertenecer a nuestra comunidad; '
          'nuestros expertos estan evaluando tu cuenta.\n\n'
          'Nombre: $displayName\n'
          'Correo: $displayEmail\n'
          'Username: $displayUsername\n\n'
          'En breve uno de nuestros expertos activara tu cuenta. '
          'Si hay inconsistencias, comunicate por medio del correo Admin@vcom.com.';
    } catch (_) {
      return null;
    }
  }

  static String _readString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _resolveUsername(
    dynamic value, {
    required String fallbackIdentifier,
    required String fallbackEmail,
  }) {
    final directValue = _readString(value);
    if (directValue.isNotEmpty) return directValue;

    if (fallbackIdentifier.isNotEmpty && !fallbackIdentifier.contains('@')) {
      return fallbackIdentifier;
    }

    if (fallbackEmail.contains('@')) {
      return fallbackEmail.split('@').first;
    }

    return '';
  }
}
