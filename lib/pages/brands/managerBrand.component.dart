import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/permission.service.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/core/models/category.model.dart';

/// Componente de gestión de marcas.
/// Orquesta estado, permisos y llamadas a infraestructura para el módulo brands.
class ManagerBrandComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final PermissionService _permissionService = PermissionService();
  final SessionCacheService _cache = SessionCacheService();

  List<BrandModel> _brands = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;

  List<BrandModel> get brands => _brands;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

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

  String? _getToken() => _tokenService.getToken();

  Map<String, String> _getHeaders() {
    final token = _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Uri _buildUri(String path) => Uri.parse('${EnvironmentDev.baseUrl}$path');

  Future<List<dynamic>?> _readCachedList({
    required String cacheKey,
    required List<String> preferredKeys,
    required String notFoundMessage,
  }) async {
    final cachedBody = await _cache.read(cacheKey);
    if (cachedBody == null) return null;

    final dynamic jsonResponse = jsonDecode(cachedBody);
    return _extractListPayload(
      jsonResponse,
      preferredKeys: preferredKeys,
      notFoundMessage: notFoundMessage,
    );
  }

  List<dynamic> _extractListPayload(
    dynamic jsonResponse, {
    required List<String> preferredKeys,
    required String notFoundMessage,
  }) {
    if (jsonResponse is List) {
      return jsonResponse;
    }

    if (jsonResponse is! Map<String, dynamic>) {
      throw Exception('Formato de respuesta no válido');
    }

    for (final key in preferredKeys) {
      final value = jsonResponse[key];
      if (value is List<dynamic>) {
        return value;
      }
    }

    final listValues = jsonResponse.values.whereType<List<dynamic>>().toList();
    if (listValues.isNotEmpty) {
      return listValues.first;
    }

    throw Exception(notFoundMessage);
  }

  Future<http.Response> _authorizedGet(String path) async {
    final response = await http.get(_buildUri(path), headers: _getHeaders());
    _tokenService.handleUnauthorizedStatus(response.statusCode);
    return response;
  }

  Future<void> _invalidateBrandCaches() async {
    await _cache.removeByPrefix(_cacheKey('brands::detail'));
    await _cache.removeByPrefix(_cacheKey('brands::list'));
    await _cache.removeByPrefix(_cacheKey('products::form::brands'));
  }

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

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('brands::categories');

      if (!forceRefresh) {
        final cachedList = await _readCachedList(
          cacheKey: cacheKey,
          preferredKeys: const ['data', 'categories', 'results'],
          notFoundMessage:
              'No se encontró la lista de categorías en la respuesta',
        );

        if (cachedList != null) {
          _categories = cachedList
              .map(
                (json) => CategoryModel.fromJson(json as Map<String, dynamic>),
              )
              .where((category) => category.stateCategory)
              .toList();
          _error = null;
          return;
        }
      }

      final response = await _authorizedGet(EnvironmentDev.categoriesList);
      if (response.statusCode == 200) {
        final jsonList = _extractListPayload(
          jsonDecode(response.body),
          preferredKeys: const ['data', 'categories', 'results'],
          notFoundMessage:
              'No se encontró la lista de categorías en la respuesta',
        );

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
        final cachedList = await _readCachedList(
          cacheKey: cacheKey,
          preferredKeys: const ['data', 'brands', 'results'],
          notFoundMessage: 'No se encontró la lista de marcas en la respuesta',
        );

        if (cachedList != null) {
          _brands = cachedList
              .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
              .toList();
          _error = null;
          return;
        }
      }

      final response = await _authorizedGet(EnvironmentDev.brandsList);
      if (response.statusCode == 200) {
        final jsonList = _extractListPayload(
          jsonDecode(response.body),
          preferredKeys: const ['data', 'brands', 'results'],
          notFoundMessage: 'No se encontró la lista de marcas en la respuesta',
        );

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

  Future<BrandModel> fetchBrandById(int id) async {
    try {
      final cacheKey = _cacheKey('brands::detail', '$id');
      final cachedBody = await _cache.read(cacheKey);
      if (cachedBody != null) {
        final json = jsonDecode(cachedBody) as Map<String, dynamic>;
        return BrandModel.fromJson(json);
      }

      final response = await _authorizedGet(EnvironmentDev.brandsGet(id));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        await _cache.write(cacheKey, response.body);
        return BrandModel.fromJson(json);
      }

      if (response.statusCode == 401) {
        throw Exception('No autenticado');
      }

      if (response.statusCode == 404) {
        throw Exception('Marca no encontrada');
      }

      throw Exception('Error al obtener marca: ${response.statusCode}');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  Future<void> createBrand(BrandModel brand) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canCreateBrands) {
        throw Exception('No tienes permiso para crear marcas');
      }

      final response = await http.post(
        _buildUri(EnvironmentDev.brandsCreate),
        headers: _getHeaders(),
        body: jsonEncode(brand.toJson()),
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 201) {
        await _invalidateBrandCaches();
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

  Future<void> updateBrand(BrandModel brand) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canUpdateBrands) {
        throw Exception('No tienes permiso para actualizar marcas');
      }

      final response = await http.put(
        _buildUri(EnvironmentDev.brandsUpdate(brand.idBrand)),
        headers: _getHeaders(),
        body: jsonEncode(brand.toJson()),
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        await _invalidateBrandCaches();
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

  Future<void> deleteBrand(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (!canDeleteBrands) {
        throw Exception('No tienes permiso para eliminar marcas');
      }

      final response = await http.delete(
        _buildUri(EnvironmentDev.brandsDelete(id)),
        headers: _getHeaders(),
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        await _invalidateBrandCaches();
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

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
