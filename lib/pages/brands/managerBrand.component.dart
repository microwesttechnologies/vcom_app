import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/core/models/category.model.dart';

/// Componente de gestión de marcas
/// Maneja toda la lógica, cálculos y estado relacionado con la gestión de marcas
class ManagerBrandComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final PermissionService _permissionService = PermissionService();
  final SessionCacheService _cache = SessionCacheService();

  // Estado
  List<BrandModel> _brands = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  BrandModel? _selectedBrand;

  // Getters
  List<BrandModel> get brands => _brands;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  BrandModel? get selectedBrand => _selectedBrand;
  bool get canReadBrands =>
      _permissionService.canReadModule(routeHints: const ['brand', 'marca']);
  bool get canCreateBrands =>
      _permissionService.canCreateModule(routeHints: const ['brand', 'marca']);
  bool get canUpdateBrands =>
      _permissionService.canUpdateModule(routeHints: const ['brand', 'marca']);
  bool get canDeleteBrands =>
      _permissionService.canDeleteModule(routeHints: const ['brand', 'marca']);

  String _cacheKey(String namespace, [String suffix = '']) {
    return _cache.scopedKey(
      namespace,
      role: _tokenService.getRole() ?? 'guest',
      userId: _tokenService.getUserId() ?? 'guest',
      suffix: suffix,
    );
  }

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

  /// Inicializa el componente cargando marcas y categorías
  Future<void> initialize({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadBrands) {
        throw Exception('No tienes permiso para ver marcas');
      }
      await Future.wait([
        fetchCategories(forceRefresh: forceRefresh),
        fetchBrands(forceRefresh: forceRefresh),
      ]);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene todas las categorías
  Future<void> fetchCategories({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('brands::categories');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final dynamic jsonResponse = jsonDecode(cachedBody);
          List<dynamic> jsonList;

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
              final listValues = jsonResponse.values
                  .where((value) => value is List)
                  .toList();
              if (listValues.isNotEmpty) {
                jsonList = listValues.first as List<dynamic>;
              } else {
                throw Exception(
                  'No se encontró la lista de categorías en la respuesta',
                );
              }
            }
          } else {
            throw Exception('Formato de respuesta no válido');
          }

          _categories = jsonList
              .map(
                (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
              )
              .where((category) => category.stateCategory)
              .toList();
          _error = null;
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesList}',
      );
      final response = await http.get(url, headers: _getHeaders());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> jsonList;

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
            final listValues = jsonResponse.values
                .where((value) => value is List)
                .toList();
            if (listValues.isNotEmpty) {
              jsonList = listValues.first as List<dynamic>;
            } else {
              throw Exception(
                'No se encontró la lista de categorías en la respuesta',
              );
            }
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }

        _categories = jsonList
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .where((category) => category.stateCategory)
            .toList();
        await _cache.write(cacheKey, response.body);
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Obtiene todas las marcas
  Future<void> fetchBrands({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canReadBrands) {
        throw Exception('No tienes permiso para ver marcas');
      }

      final cacheKey = _cacheKey('brands::list');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final dynamic jsonResponse = jsonDecode(cachedBody);
          List<dynamic> jsonList;

          if (jsonResponse is List) {
            jsonList = jsonResponse;
          } else if (jsonResponse is Map<String, dynamic>) {
            if (jsonResponse.containsKey('data')) {
              jsonList = jsonResponse['data'] as List<dynamic>;
            } else if (jsonResponse.containsKey('brands')) {
              jsonList = jsonResponse['brands'] as List<dynamic>;
            } else if (jsonResponse.containsKey('results')) {
              jsonList = jsonResponse['results'] as List<dynamic>;
            } else {
              final listValues = jsonResponse.values
                  .where((value) => value is List)
                  .toList();
              if (listValues.isNotEmpty) {
                jsonList = listValues.first as List<dynamic>;
              } else {
                throw Exception(
                  'No se encontró la lista de marcas en la respuesta',
                );
              }
            }
          } else {
            throw Exception('Formato de respuesta no válido');
          }

          _brands = jsonList
              .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _error = null;
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.brandsList}',
      );
      final response = await http.get(url, headers: _getHeaders());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> jsonList;

        if (jsonResponse is List) {
          jsonList = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data')) {
            jsonList = jsonResponse['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('brands')) {
            jsonList = jsonResponse['brands'] as List<dynamic>;
          } else if (jsonResponse.containsKey('results')) {
            jsonList = jsonResponse['results'] as List<dynamic>;
          } else {
            final listValues = jsonResponse.values
                .where((value) => value is List)
                .toList();
            if (listValues.isNotEmpty) {
              jsonList = listValues.first as List<dynamic>;
            } else {
              throw Exception(
                'No se encontró la lista de marcas en la respuesta',
              );
            }
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }

        _brands = jsonList
            .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
            .toList();
        await _cache.write(cacheKey, response.body);
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else {
        throw Exception('Error al obtener marcas: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _brands = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene una marca por ID
  Future<BrandModel> fetchBrandById(int id) async {
    try {
      final cacheKey = _cacheKey('brands::detail', '$id');
      final cachedBody = await _cache.read(cacheKey);
      if (cachedBody != null) {
        final json = jsonDecode(cachedBody) as Map<String, dynamic>;
        return BrandModel.fromJson(json);
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.brandsGet(id)}',
      );
      final response = await http.get(url, headers: _getHeaders());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        await _cache.write(cacheKey, response.body);
        return BrandModel.fromJson(json);
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Marca no encontrada');
      } else {
        throw Exception('Error al obtener marca: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  /// Crea una nueva marca
  Future<void> createBrand(BrandModel brand) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canCreateBrands) {
        throw Exception('No tienes permiso para crear marcas');
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.brandsCreate}',
      );
      final response = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(brand.toJson()),
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 201) {
        await _cache.removeByPrefix(_cacheKey('brands::detail'));
        await _cache.removeByPrefix(_cacheKey('brands::list'));
        await _cache.removeByPrefix(_cacheKey('products::form::brands'));
        await fetchBrands(forceRefresh: true);
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 422) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Error de validación: ${errorBody.toString()}');
      } else {
        throw Exception(
          'Error al crear marca: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Actualiza una marca
  Future<void> updateBrand(BrandModel brand) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canUpdateBrands) {
        throw Exception('No tienes permiso para actualizar marcas');
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.brandsUpdate(brand.idBrand)}',
      );
      final response = await http.put(
        url,
        headers: _getHeaders(),
        body: jsonEncode(brand.toJson()),
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        await _cache.removeByPrefix(_cacheKey('brands::detail'));
        await _cache.removeByPrefix(_cacheKey('brands::list'));
        await _cache.removeByPrefix(_cacheKey('products::form::brands'));
        await fetchBrands(forceRefresh: true);
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Marca no encontrada');
      } else if (response.statusCode == 422) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Error de validación: ${errorBody.toString()}');
      } else {
        throw Exception('Error al actualizar marca: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Elimina una marca
  Future<void> deleteBrand(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canDeleteBrands) {
        throw Exception('No tienes permiso para eliminar marcas');
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.brandsDelete(id)}',
      );
      final response = await http.delete(url, headers: _getHeaders());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        await _cache.removeByPrefix(_cacheKey('brands::detail'));
        await _cache.removeByPrefix(_cacheKey('brands::list'));
        await _cache.removeByPrefix(_cacheKey('products::form::brands'));
        await fetchBrands(forceRefresh: true);
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Marca no encontrada');
      } else {
        throw Exception('Error al eliminar marca: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Establece la marca seleccionada para edición
  void setSelectedBrand(BrandModel? brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  /// Limpia la marca seleccionada
  void clearSelectedBrand() {
    _selectedBrand = null;
    notifyListeners();
  }

  /// Limpia el estado de error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
