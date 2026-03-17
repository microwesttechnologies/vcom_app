import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/core/models/brand.model.dart';

/// Componente para crear productos
/// Maneja la lógica de creación de productos
class CreateProductComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final SessionCacheService _cache = SessionCacheService();

  // Estado
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;

  // Getters
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;

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

  /// Inicializa el componente cargando categorías
  Future<void> initialize({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await fetchCategories(forceRefresh: forceRefresh);
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
      final cacheKey = _cacheKey('products::form::categories');
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

  /// Obtiene las marcas por categoría
  Future<void> fetchBrandsByCategory(
    int categoryId, {
    bool forceRefresh = false,
  }) async {
    _selectedCategoryId = categoryId;
    _brands = [];
    notifyListeners();

    try {
      final cacheKey = _cacheKey('products::form::brands', '$categoryId');
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
              .where((brand) => brand.stateBrand)
              .toList();
          _error = null;
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.brandsByCategory(categoryId)}',
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
            .where((brand) => brand.stateBrand)
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
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  /// Limpia la selección de categoría y marcas
  void clearCategorySelection() {
    _selectedCategoryId = null;
    _brands = [];
    notifyListeners();
  }

  /// Sube una imagen usando multipart/form-data
  Future<String> uploadImage(
    File imageFile,
    int productId,
    int imageOrder,
    bool isPrimary,
  ) async {
    try {
      final token = _getToken();
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productsUploadImage(productId)}',
      );

      var request = http.MultipartRequest('POST', url);

      // Headers
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      // Agregar archivo
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      // Agregar campos adicionales
      request.fields['image_order'] = imageOrder.toString();
      request.fields['is_primary'] = isPrimary ? '1' : '0';

      // Sugerir nombre de archivo corto: {productId}{imageOrder}{fecha}
      final now = DateTime.now();
      final dateStr =
          '${now.day.toString().padLeft(2, '0')}${now.month.toString().padLeft(2, '0')}${now.year}';
      final suggestedName = '$productId$imageOrder$dateStr.jpg';
      request.fields['suggested_filename'] = suggestedName;

      print('=== UPLOAD IMAGE REQUEST ===');
      print('URL: $url');
      print('Fields: ${request.fields}');
      print('File: ${imageFile.path}');
      print('Suggested filename: ${request.fields['suggested_filename']}');
      print('===========================\n');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      print('=== UPLOAD IMAGE RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('============================\n');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        // El API retorna la URL de la imagen subida
        if (jsonResponse is Map<String, dynamic>) {
          final imageUrl =
              jsonResponse['image_url'] as String? ??
              jsonResponse['url'] as String? ??
              jsonResponse['data']?['image_url'] as String? ??
              '';

          if (imageUrl.isNotEmpty) {
            print('=== IMAGEN SUBIDA EXITOSAMENTE ===');
            print('URL: $imageUrl');
            print('Orden: $imageOrder, Principal: $isPrimary');
            print('=================================\n');
          }

          return imageUrl;
        }
        return '';
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else {
        throw Exception('Error al subir imagen: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  /// Crea un nuevo producto con imágenes
  Future<void> createProduct(
    ProductModel product, {
    List<XFile>? images,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Validar imágenes primero si existen
      if (images != null && images.isNotEmpty) {
        print(
          'Validando ${images.length} imágenes antes de crear el producto...',
        );

        // Crear un producto temporal para probar la subida de imágenes
        // Esto nos permite validar que las imágenes se pueden subir antes de crear el producto
        for (int i = 0; i < images.length; i++) {
          final imageFile = File(images[i].path);
          if (!await imageFile.exists()) {
            throw Exception(
              'La imagen ${i + 1} no existe o no se puede acceder',
            );
          }

          // Validar tamaño de archivo (máximo 10MB)
          final fileSize = await imageFile.length();
          if (fileSize > 10 * 1024 * 1024) {
            throw Exception(
              'La imagen ${i + 1} es demasiado grande (máximo 10MB)',
            );
          }
        }
      }

      // 2. Crear el producto sin imágenes
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productsCreate}',
      );

      final productData = {
        'id_brand': product.idBrand,
        'name_product': product.nameProduct,
        'description_product': product.descriptionProduct,
        'sku': product.sku,
        'price_cop': product.priceCop,
        'stock': product.stock,
        'state_product': product.stateProduct,
      };

      print('=== CREATE PRODUCT REQUEST ===');
      print('URL: $url');
      print('Body: ${jsonEncode(productData)}');
      print('=============================\n');

      final createResponse = await http.post(
        url,
        headers: _getHeaders(),
        body: jsonEncode(productData),
      );
      _tokenService.handleUnauthorizedStatus(createResponse.statusCode);

      print('=== CREATE PRODUCT RESPONSE ===');
      print('Status Code: ${createResponse.statusCode}');
      print('Body: ${createResponse.body}');
      print('==============================\n');

      if (createResponse.statusCode == 201) {
        final responseData = jsonDecode(createResponse.body);

        // Extraer el ID del producto creado
        int? productId;
        if (responseData is Map<String, dynamic>) {
          productId =
              responseData['id_product'] as int? ??
              responseData['data']?['id_product'] as int? ??
              responseData['id'] as int?;
        }

        if (productId == null) {
          throw Exception('No se pudo obtener el ID del producto creado');
        }

        print('Producto creado con ID: $productId');

        // 3. Subir imágenes si existen
        if (images != null && images.isNotEmpty) {
          print('Subiendo ${images.length} imágenes...');

          List<String> imageErrors = [];

          for (int i = 0; i < images.length; i++) {
            try {
              final imageFile = File(images[i].path);
              await uploadImage(
                imageFile,
                productId,
                i + 1, // image_order empieza en 1
                i == 0, // primera imagen es principal
              );
            } catch (e) {
              final errorMessage =
                  'Error al subir imagen ${i + 1}: ${e.toString().replaceFirst('Exception: ', '')}';
              print(errorMessage);
              imageErrors.add(errorMessage);
            }
          }

          // Si hay errores en las imágenes, lanzar excepción con todos los errores
          if (imageErrors.isNotEmpty) {
            throw Exception(
              'Errores al subir imágenes:\n${imageErrors.join('\n')}',
            );
          }
        }

        await _cache.removeByPrefix(_cacheKey('products::list'));
        await _cache.removeByPrefix(_cacheKey('products::detail'));
        await _cache.removeByPrefix(_cacheKey('shop::products'));
        _error = null;
      } else if (createResponse.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (createResponse.statusCode == 422) {
        final errorBody = jsonDecode(createResponse.body);
        throw Exception('Error de validación: ${errorBody.toString()}');
      } else {
        throw Exception(
          'Error al crear producto: ${createResponse.statusCode}',
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

  /// Limpia el estado de error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
