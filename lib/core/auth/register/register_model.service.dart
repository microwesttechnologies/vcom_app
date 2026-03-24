import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/models/model_register.model.dart';

class RegisterModelService {
  static const Duration _timeout = Duration(seconds: 30);
  final String _baseUrl;

  RegisterModelService() : _baseUrl = EnvironmentDev.baseUrl;

  Future<List<PlatformRecord>> getPlatforms() async {
    final url = Uri.parse('$_baseUrl${EnvironmentDev.platformsPublic}');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(
            _timeout,
            onTimeout: () => throw Exception(
              'Tiempo de espera agotado al cargar plataformas.',
            ),
          );

      if (response.statusCode != 200) {
        throw Exception(
          _extractErrorMessage(
            response,
            fallback: response.statusCode == 404
                ? 'El listado publico de plataformas no esta disponible en el servidor.'
                : 'No se pudieron cargar las plataformas disponibles.',
          ),
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final data = body['data'] as List? ?? [];
      return data
          .map(
            (entry) => PlatformRecord.fromJson(entry as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on SocketException {
      throw Exception(
        'Sin conexion a internet. Verifica tu red e intenta de nuevo.',
      );
    } on HandshakeException {
      throw Exception('Error de conexion segura. Contacta soporte.');
    } on FormatException {
      throw Exception(
        'La respuesta del servidor para plataformas no es valida.',
      );
    } on Exception {
      rethrow;
    }
  }

  Future<void> registerModel(ModelRegisterPayload payload) async {
    final url = Uri.parse('$_baseUrl${EnvironmentDev.modelsRegister}');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload.toJson()),
          )
          .timeout(
            _timeout,
            onTimeout: () => throw Exception(
              'Tiempo de espera agotado. Verifica tu conexion a internet.',
            ),
          );

      if (response.statusCode == 201) {
        return;
      }

      if (response.statusCode == 422) {
        throw Exception(
          _extractErrorMessage(
            response,
            fallback: 'Error de validacion. Revisa los datos ingresados.',
          ),
        );
      }

      throw Exception(
        _extractErrorMessage(
          response,
          fallback: response.statusCode == 404
              ? 'El endpoint publico de registro no esta disponible en el servidor.'
              : 'Error al enviar la solicitud.',
        ),
      );
    } on SocketException {
      throw Exception(
        'Sin conexion a internet. Verifica tu red e intenta de nuevo.',
      );
    } on HandshakeException {
      throw Exception('Error de conexion segura. Contacta soporte.');
    } on FormatException {
      throw Exception(
        'El servidor respondio con un formato no valido para el registro.',
      );
    } on Exception {
      rethrow;
    }
  }

  String _extractErrorMessage(
    http.Response response, {
    required String fallback,
  }) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return '$fallback (HTTP ${response.statusCode}).';
    }

    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final directMessage = decoded['message'] ?? decoded['error'];
        if (directMessage is String && directMessage.trim().isNotEmpty) {
          return 'HTTP ${response.statusCode}: ${directMessage.trim()}';
        }

        final errors = decoded['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final firstValue = errors.values.first;
          if (firstValue is List && firstValue.isNotEmpty) {
            return 'HTTP ${response.statusCode}: ${firstValue.first}';
          }
          return 'HTTP ${response.statusCode}: $firstValue';
        }
      }
    } catch (_) {
      return 'HTTP ${response.statusCode}: $body';
    }

    return 'HTTP ${response.statusCode}: $body';
  }
}
