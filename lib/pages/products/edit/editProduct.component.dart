import 'dart:convert';
import 'dart:io'; // Keep this for File
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // Keep this for XFile

import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/core/models/brand.model.dart';

class EditProductComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final SessionCacheService _cache = SessionCacheService();

  // ========================
  // STATE
  // ========================
  ProductModel? _product;
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;

  // ========================
  // GETTERS
  // ========================
  ProductModel? get product => _product;
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

  // ========================
  // HEADERS
  // ========================
  Map<String, String> _headers() {
    final token = _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Inicializa el componente cargando el producto y categorías
  Future<void> initialize(int productId, {bool forceRefresh = false}) async {
    _setLoading(true);
    try {
      await Future.wait([
        _fetchProduct(productId, forceRefresh: forceRefresh),
        _fetchCategories(forceRefresh: forceRefresh),
      ]);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _setLoading(false);
    }
  }

  // ========================
  // FETCH PRODUCT
  // ========================
  Future<void> _fetchProduct(int id, {bool forceRefresh = false}) async {
    final cacheKey = _cacheKey('products::detail', '$id');
    if (!forceRefresh) {
      final cachedBody = await _cache.read(cacheKey);
      if (cachedBody != null) {
        final body = jsonDecode(cachedBody);
        final data = body['data'] ?? body['product'] ?? body;

        _product = ProductModel.fromJson(data);
        if (_product?.category?.idCategory != null) {
          _selectedCategoryId = _product!.category!.idCategory;
          await fetchBrandsByCategory(_selectedCategoryId!);
        }
        notifyListeners();
        return;
      }
    }

    final response = await http.get(
      Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.productsGet(id)}'),
      headers: _headers(),
    );
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener producto');
    }

    final body = jsonDecode(response.body);
    final data = body['data'] ?? body['product'] ?? body;

    _product = ProductModel.fromJson(data);
    await _cache.write(cacheKey, response.body);

    if (_product?.category?.idCategory != null) {
      _selectedCategoryId = _product!.category!.idCategory;
      await fetchBrandsByCategory(_selectedCategoryId!);
    }

    notifyListeners();
  }

  // ========================
  // FETCH CATEGORIES
  // ========================
  Future<void> _fetchCategories({bool forceRefresh = false}) async {
    final cacheKey = _cacheKey('products::form::categories');
    if (!forceRefresh) {
      final cachedBody = await _cache.read(cacheKey);
      if (cachedBody != null) {
        final body = jsonDecode(cachedBody);
        final list = body['data'] ?? body['categories'] ?? body;

        _categories = (list as List)
            .map((e) => CategoryModel.fromJson(e))
            .where((c) => c.stateCategory)
            .toList();
        notifyListeners();
        return;
      }
    }

    final response = await http.get(
      Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesList}'),
      headers: _headers(),
    );
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener categorías');
    }

    final body = jsonDecode(response.body);
    final list = body['data'] ?? body['categories'] ?? body;

    _categories = (list as List)
        .map((e) => CategoryModel.fromJson(e))
        .where((c) => c.stateCategory)
        .toList();
    await _cache.write(cacheKey, response.body);

    notifyListeners();
  }

  // ========================
  // FETCH BRANDS
  // ========================
  Future<void> fetchBrandsByCategory(
    int categoryId, {
    bool forceRefresh = false,
  }) async {
    _selectedCategoryId = categoryId;
    _brands = [];
    notifyListeners();

    final cacheKey = _cacheKey('products::form::brands', '$categoryId');
    if (!forceRefresh) {
      final cachedBody = await _cache.read(cacheKey);
      if (cachedBody != null) {
        final body = jsonDecode(cachedBody);
        final list = body['data'] ?? body['brands'] ?? body;

        _brands = (list as List)
            .map((e) => BrandModel.fromJson(e))
            .where((b) => b.stateBrand)
            .toList();
        notifyListeners();
        return;
      }
    }

    final response = await http.get(
      Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.brandsByCategory(categoryId)}',
      ),
      headers: _headers(),
    );
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode != 200) {
      throw Exception('Error al obtener marcas');
    }

    final body = jsonDecode(response.body);
    final list = body['data'] ?? body['brands'] ?? body;

    _brands = (list as List)
        .map((e) => BrandModel.fromJson(e))
        .where((b) => b.stateBrand)
        .toList();
    await _cache.write(cacheKey, response.body);

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
      final token = _tokenService.getToken();
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

  // ========================
  // UPDATE PRODUCT
  // ========================
  Future<void> updateProduct(
    ProductModel product, {
    List<XFile>? newImages,
  }) async {
    if (product.idProduct == null) {
      throw Exception('Producto sin ID');
    }

    _setLoading(true);

    try {
      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productsUpdate(product.idProduct!)}',
      );

      // 1. Subir nuevas imágenes si existen
      if (newImages != null && newImages.isNotEmpty) {
        print('Subiendo ${newImages.length} nuevas imágenes...');

        // Contar imágenes existentes para determinar el orden de las nuevas
        final existingImageCount = product.images.length;

        for (int i = 0; i < newImages.length; i++) {
          try {
            final imageFile = File(newImages[i].path);
            final imageOrder = existingImageCount + i + 1;
            final isPrimary =
                existingImageCount == 0 &&
                i == 0; // Solo si no hay imágenes existentes

            await uploadImage(
              imageFile,
              product.idProduct!,
              imageOrder,
              isPrimary,
            );
          } catch (e) {
            print('Error al subir imagen ${i + 1}: $e');
            // Continuar con las demás imágenes aunque una falle
          }
        }
      }

      // 2. Actualizar solo los datos básicos del producto (sin imágenes)
      final productData = {
        'id_brand': product.idBrand,
        'name_product': product.nameProduct,
        'description_product': product.descriptionProduct,
        'sku': product.sku,
        'price_cop': product.priceCop,
        'stock': product.stock,
        'state_product': product.stateProduct,
      };

      print('=== UPDATE PRODUCT REQUEST ===');
      print('URL: $url');
      print('Body: ${jsonEncode(productData)}');
      print('=============================\n');

      final response = await http.put(
        url,
        headers: _headers(),
        body: jsonEncode(productData),
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      print('=== UPDATE PRODUCT RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('==============================\n');

      if (response.statusCode == 200) {
        await _cache.removeByPrefix(_cacheKey('products::list'));
        await _cache.removeByPrefix(_cacheKey('products::detail'));
        await _cache.removeByPrefix(_cacheKey('shop::products'));
        _error = null;
      } else if (response.statusCode == 401) {
        throw Exception('No autenticado');
      } else if (response.statusCode == 404) {
        throw Exception('Producto no encontrado');
      } else if (response.statusCode == 422) {
        final errorBody = jsonDecode(response.body);
        throw Exception('Error de validación: ${errorBody.toString()}');
      } else {
        throw Exception('Error al actualizar producto: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ========================
  // HELPERS
  // ========================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCategorySelection() {
    _selectedCategoryId = null;
    _brands = [];
    notifyListeners();
  }
}
