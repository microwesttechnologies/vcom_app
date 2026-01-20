import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';

/// Componente para eliminar productos
/// Maneja la lógica de eliminación de productos
class DeleteProductComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  
  // Estado
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  /// Elimina un producto
  Future<void> deleteProduct(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.productsDelete(id)}');
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Producto no encontrado');
      } else {
        throw Exception('Error al eliminar producto: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
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

