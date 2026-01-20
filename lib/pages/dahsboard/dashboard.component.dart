import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/models/module.model.dart';

class DashboardComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  List<ModuleModel> _modules = [];
  bool _isLoading = false;
  String? _error;

  List<ModuleModel> get modules => _modules;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Obtiene los módulos del endpoint
  Future<void> fetchModules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _tokenService.getToken();
      if (token == null || token.isEmpty) {
        throw Exception('No hay token de autenticación');
      }

      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.authPermissions}');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> modulesList;
        
        // Manejar si la respuesta es un array directo o un objeto con una propiedad
        if (jsonResponse is List) {
          modulesList = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          // Intentar obtener el array de módulos desde diferentes posibles propiedades
          if (jsonResponse.containsKey('modules')) {
            modulesList = jsonResponse['modules'] as List<dynamic>;
          } else if (jsonResponse.containsKey('data')) {
            modulesList = jsonResponse['data'] as List<dynamic>;
          } else {
            // Buscar cualquier propiedad que sea una lista
            final listValues = jsonResponse.values.where((value) => value is List).toList();
            if (listValues.isNotEmpty) {
              modulesList = listValues.first as List<dynamic>;
            } else {
              throw Exception('No se encontró la lista de módulos en la respuesta. Estructura: ${jsonResponse.keys.join(", ")}');
            }
          }
        } else {
          throw Exception('Formato de respuesta no válido. Tipo recibido: ${jsonResponse.runtimeType}');
        }
        
        _modules = modulesList
            .map((module) => ModuleModel.fromJson(module as Map<String, dynamic>))
            .where((module) => module.state) // Solo módulos activos
            .toList();
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else {
        throw Exception('Error al obtener módulos: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _modules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getToken() {
    return _tokenService.getToken() ?? 'No hay token';
  }
}

