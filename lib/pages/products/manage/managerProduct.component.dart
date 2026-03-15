import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/models/product.model.dart';

/// Componente de gestión de productos
/// Maneja solo la lógica de listado de productos
class ManagerProductComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final PermissionService _permissionService = PermissionService();
  
  // Estado
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get canReadProducts =>
      _permissionService.canReadModule(routeHints: const ['product', 'producto']);
  bool get canCreateProducts =>
      _permissionService.canCreateModule(routeHints: const ['product', 'producto']);
  bool get canUpdateProducts =>
      _permissionService.canUpdateModule(routeHints: const ['product', 'producto']);
  bool get canDeleteProducts =>
      _permissionService.canDeleteModule(routeHints: const ['product', 'producto']);

  /// Obtiene el token de autenticación
  String? _getToken() {
    return _tokenService.getToken();
  }

  /// Obtiene los headers con autenticación
  Map<String, String> _getHeaders() {
    final token = _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Inicializa el componente cargando productos
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadProducts) {
        throw Exception('No tienes permiso para ver productos');
      }
      await fetchProducts();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene todos los productos
  Future<void> fetchProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadProducts) {
        throw Exception('No tienes permiso para ver productos');
      }

      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.productsList}');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> jsonList;
        
        // Manejar si la respuesta es un array directo o un objeto con una propiedad
        if (jsonResponse is List) {
          jsonList = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          // Intentar obtener el array desde diferentes posibles propiedades
          if (jsonResponse.containsKey('data')) {
            jsonList = jsonResponse['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('products')) {
            jsonList = jsonResponse['products'] as List<dynamic>;
          } else if (jsonResponse.containsKey('results')) {
            jsonList = jsonResponse['results'] as List<dynamic>;
          } else {
            // Buscar cualquier propiedad que sea una lista
            final listValues = jsonResponse.values.where((value) => value is List).toList();
            if (listValues.isNotEmpty) {
              jsonList = listValues.first as List<dynamic>;
            } else {
              throw Exception('No se encontró la lista de productos en la respuesta. Estructura: ${jsonResponse.keys.join(", ")}');
            }
          }
        } else {
          throw Exception('Formato de respuesta no válido. Tipo recibido: ${jsonResponse.runtimeType}');
        }
        
        _products = jsonList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _products = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpia el estado de error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

