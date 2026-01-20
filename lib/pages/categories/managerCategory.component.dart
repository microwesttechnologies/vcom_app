import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/models/category.model.dart';

/// Componente de gestión de categorías
/// Maneja toda la lógica, cálculos y estado relacionado con la gestión de categorías
class ManagerCategoryComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  
  // Estado
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  CategoryModel? _selectedCategory;

  // Getters
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  CategoryModel? get selectedCategory => _selectedCategory;

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

  /// Inicializa el componente cargando categorías
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await fetchCategories();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene todas las categorías
  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesList}');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> jsonList;
        
        // Manejar si la respuesta es un array directo o un objeto con una propiedad
        if (jsonResponse is List) {
          jsonList = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data')) {
            jsonList = jsonResponse['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('categories')) {
            jsonList = jsonResponse['categories'] as List<dynamic>;
          } else if (jsonResponse.containsKey('results')) {
            jsonList = jsonResponse['results'] as List<dynamic>;
          } else {
            final listValues = jsonResponse.values.where((value) => value is List).toList();
            if (listValues.isNotEmpty) {
              jsonList = listValues.first as List<dynamic>;
            } else {
              throw Exception('No se encontró la lista de categorías en la respuesta');
            }
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }
        
        _categories = jsonList
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .toList();
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _categories = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene una categoría por ID
  Future<CategoryModel> fetchCategoryById(int id) async {
    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesGet(id)}');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return CategoryModel.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Categoría no encontrada');
      } else {
        throw Exception('Error al obtener categoría: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  /// Crea una nueva categoría
  Future<void> createCategory(CategoryModel category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesCreate}');
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(category.toJson()),
      );

      if (response.statusCode == 201) {
        await fetchCategories(); // Recargar lista
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 422) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Error de validación: ${errorBody.toString()}');
      } else {
        throw Exception('Error al crear categoría: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza una categoría
  Future<void> updateCategory(CategoryModel category) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesUpdate(category.idCategory)}');
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(category.toJson()),
      );

      if (response.statusCode == 200) {
        await fetchCategories(); // Recargar lista
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Categoría no encontrada');
      } else if (response.statusCode == 422) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Error de validación: ${errorBody.toString()}');
      } else {
        throw Exception('Error al actualizar categoría: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina una categoría
  Future<void> deleteCategory(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesDelete(id)}');
      final response = await http.delete(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        await fetchCategories(); // Recargar lista
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Categoría no encontrada');
      } else {
        throw Exception('Error al eliminar categoría: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Establece la categoría seleccionada para edición
  void setSelectedCategory(CategoryModel? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Limpia la categoría seleccionada
  void clearSelectedCategory() {
    _selectedCategory = null;
    notifyListeners();
  }

  /// Limpia el estado de error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

