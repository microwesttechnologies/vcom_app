import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/brand.model.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:vcom_app/core/models/product.model.dart';

class ShopComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final SessionCacheService _cache = SessionCacheService();

  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  List<BrandModel> _brands = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;
  String _searchQuery = '';

  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  List<CategoryModel> get categories => _categories;
  List<BrandModel> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  bool get canManageProducts =>
      (_tokenService.getRole() ?? '').trim().toUpperCase() == 'MONITOR';

  String _cacheKey(String namespace) {
    return _cache.scopedKey(
      namespace,
      role: _tokenService.getRole() ?? 'guest',
      userId: _tokenService.getUserId() ?? 'guest',
    );
  }

  Map<String, String> _getHeaders() {
    final token = _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  List<dynamic> _extractList(dynamic jsonResponse, String errorLabel) {
    if (jsonResponse is List) return jsonResponse;
    if (jsonResponse is Map<String, dynamic>) {
      if (jsonResponse['data'] is List) return jsonResponse['data'] as List;
      if (jsonResponse['products'] is List) {
        return jsonResponse['products'] as List;
      }
      if (jsonResponse['brands'] is List) return jsonResponse['brands'] as List;
      if (jsonResponse['categories'] is List) {
        return jsonResponse['categories'] as List;
      }
      final listValues = jsonResponse.values.whereType<List>().toList();
      if (listValues.isNotEmpty) return listValues.first;
    }
    throw Exception('No se encontro la lista de $errorLabel');
  }

  Map<String, dynamic> _extractMap(dynamic jsonResponse, String errorLabel) {
    if (jsonResponse is Map<String, dynamic>) {
      final data = jsonResponse['data'];
      if (data is Map<String, dynamic>) return data;
      return jsonResponse;
    }
    throw Exception('Formato de respuesta invalido en $errorLabel');
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchCategories(forceRefresh: forceRefresh),
        fetchBrands(forceRefresh: forceRefresh),
        fetchProducts(forceRefresh: forceRefresh),
      ]);
      _applyFilters();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('shop::categories');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final dynamic jsonResponse = jsonDecode(cachedBody);
          final jsonList = _extractList(jsonResponse, 'categorias');
          _categories = jsonList
              .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
              .where((category) => category.stateCategory)
              .toList();
          return;
        }
      }

      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesList}');
      final response = await http.get(url, headers: _getHeaders());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        final jsonList = _extractList(jsonResponse, 'categorias');
        _categories = jsonList
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .where((category) => category.stateCategory)
            .toList();
        await _cache.write(cacheKey, response.body);
      } else {
        throw Exception('Error al obtener categorias: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  Future<void> fetchBrands({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('shop::brands');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final dynamic jsonResponse = jsonDecode(cachedBody);
          final jsonList = _extractList(jsonResponse, 'marcas');
          _brands = jsonList
              .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
              .where((brand) => brand.stateBrand)
              .toList();
          return;
        }
      }

      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.brandsList}');
      final response = await http.get(url, headers: _getHeaders());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        final jsonList = _extractList(jsonResponse, 'marcas');
        _brands = jsonList
            .map((json) => BrandModel.fromJson(json as Map<String, dynamic>))
            .where((brand) => brand.stateBrand)
            .toList();
        await _cache.write(cacheKey, response.body);
      } else {
        throw Exception('Error al obtener marcas: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  Future<void> fetchProducts({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('shop::products');
      if (!forceRefresh) {
        final cachedBody = await _cache.read(cacheKey);
        if (cachedBody != null) {
          final dynamic jsonResponse = jsonDecode(cachedBody);
          final jsonList = _extractList(jsonResponse, 'productos');
          _products = jsonList
              .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
              .where((product) => product.stateProduct && product.stock > 0)
              .toList();
          _products.sort(
            (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
              a.createdAt ?? DateTime.now(),
            ),
          );
          return;
        }
      }

      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.productsList}');
      final response = await http.get(url, headers: _getHeaders());
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        final jsonList = _extractList(jsonResponse, 'productos');
        _products = jsonList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .where((product) => product.stateProduct && product.stock > 0)
            .toList();
        _products.sort(
          (a, b) => (b.createdAt ?? DateTime.now()).compareTo(
            a.createdAt ?? DateTime.now(),
          ),
        );
        await _cache.write(cacheKey, response.body);
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      final matchesCategory =
          _selectedCategoryId == null ||
          product.category?.idCategory == _selectedCategoryId ||
          product.brand?.idCategory == _selectedCategoryId;

      final query = _searchQuery.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          product.nameProduct.toLowerCase().contains(query) ||
          (product.descriptionProduct?.toLowerCase().contains(query) ?? false) ||
          (product.brand?.nameBrand.toLowerCase().contains(query) ?? false) ||
          (product.category?.nameCategory.toLowerCase().contains(query) ?? false);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<File> compressProductImage(File originalFile) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}${Platform.pathSeparator}product_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final compressed = await FlutterImageCompress.compressAndGetFile(
      originalFile.absolute.path,
      outputPath,
      quality: 55,
      format: CompressFormat.jpeg,
      minWidth: 1080,
      minHeight: 1080,
      keepExif: false,
    );

    if (compressed == null) return originalFile;

    final compressedFile = File(compressed.path);
    final originalSize = await originalFile.length();
    final compressedSize = await compressedFile.length();
    if (compressedSize <= 0) return originalFile;
    return compressedSize <= originalSize ? compressedFile : originalFile;
  }

  Future<void> _uploadProductImages(
    int idProduct,
    List<File> images, {
    bool markFirstAsPrimary = true,
  }) async {
    if (images.isEmpty) return;

    for (var i = 0; i < images.length; i++) {
      final compressedFile = await compressProductImage(images[i]);
      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productsUploadImage(idProduct)}',
      );
      final request = http.MultipartRequest('POST', uri);
      final token = _tokenService.getToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('image', compressedFile.path),
      );
      final shouldBePrimary = markFirstAsPrimary && i == 0;
      if (shouldBePrimary) {
        request.fields['is_primary'] = '1';
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      _tokenService.handleUnauthorizedStatus(response.statusCode);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String backendMessage = '';
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            final msg = body['message']?.toString();
            final err = body['error']?.toString();
            final errors = body['errors'];
            if (msg != null && msg.isNotEmpty) {
              backendMessage = msg;
            } else if (err != null && err.isNotEmpty) {
              backendMessage = err;
            } else if (errors != null) {
              backendMessage = errors.toString();
            }
          }
        } catch (_) {}
        if (backendMessage.isNotEmpty) {
          throw Exception(
            'No fue posible subir imagen (${response.statusCode}): $backendMessage',
          );
        }
        throw Exception('No fue posible subir imagen (${response.statusCode})');
      }
    }
  }

  Future<void> createProduct({
    required int idBrand,
    required String nameProduct,
    required String descriptionProduct,
    required String sku,
    required double priceCop,
    required int stock,
    bool stateProduct = true,
    List<File> images = const [],
  }) async {
    if (!canManageProducts) {
      throw Exception('No tienes permisos para crear productos');
    }
    if (images.length > 5) {
      throw Exception('Solo se permiten hasta 5 imagenes');
    }

    final payload = {
      'id_brand': idBrand,
      'name_product': nameProduct.trim(),
      'description_product': descriptionProduct.trim(),
      'sku': sku.trim(),
      'price_cop': priceCop,
      'stock': stock,
      'state_product': stateProduct,
    };

    final uri = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.productsCreate}');
    final response = await http.post(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(payload),
    );
    _tokenService.handleUnauthorizedStatus(response.statusCode);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No fue posible crear producto (${response.statusCode})');
    }

    final body = jsonDecode(response.body);
    final data = _extractMap(body, 'crear producto');
    final idProduct = (data['id_product'] as num?)?.toInt();
    if (idProduct == null || idProduct <= 0) {
      throw Exception('Producto creado sin id_product valido');
    }

    await _uploadProductImages(idProduct, images, markFirstAsPrimary: true);
    await refresh();
  }

  Future<void> updateProduct({
    required int idProduct,
    required int idBrand,
    required String nameProduct,
    required String descriptionProduct,
    required String sku,
    required double priceCop,
    required int stock,
    bool stateProduct = true,
    List<File> newImages = const [],
  }) async {
    if (!canManageProducts) {
      throw Exception('No tienes permisos para actualizar productos');
    }
    if (newImages.length > 5) {
      throw Exception('Solo se permiten hasta 5 imagenes');
    }

    final payload = {
      'id_brand': idBrand,
      'name_product': nameProduct.trim(),
      'description_product': descriptionProduct.trim(),
      'sku': sku.trim(),
      'price_cop': priceCop,
      'stock': stock,
      'state_product': stateProduct,
    };

    final uri = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.productsUpdate(idProduct)}',
    );
    final response = await http.put(
      uri,
      headers: _getHeaders(),
      body: jsonEncode(payload),
    );
    _tokenService.handleUnauthorizedStatus(response.statusCode);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('No fue posible actualizar producto (${response.statusCode})');
    }

    await _uploadProductImages(idProduct, newImages, markFirstAsPrimary: false);
    await refresh();
  }

  Future<void> deleteProduct(int idProduct) async {
    if (!canManageProducts) {
      throw Exception('No tienes permisos para eliminar productos');
    }

    final uri = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.productsDelete(idProduct)}',
    );
    final response = await http.delete(uri, headers: _getHeaders());
    _tokenService.handleUnauthorizedStatus(response.statusCode);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String backendMessage = '';
      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic>) {
          final msg = body['message']?.toString();
          final err = body['error']?.toString();
          final errors = body['errors'];
          if (msg != null && msg.isNotEmpty) {
            backendMessage = msg;
          } else if (err != null && err.isNotEmpty) {
            backendMessage = err;
          } else if (errors != null) {
            backendMessage = errors.toString();
          }
        }
      } catch (_) {}
      if (backendMessage.isNotEmpty) {
        throw Exception(
          'No fue posible eliminar producto (${response.statusCode}): $backendMessage',
        );
      }
      throw Exception('No fue posible eliminar producto (${response.statusCode})');
    }

    await refresh();
  }

  Future<bool> deleteOrDeactivateProduct(ProductModel product) async {
    final id = product.idProduct;
    if (id == null) {
      throw Exception('Producto sin id');
    }

    try {
      await deleteProduct(id);
      return true;
    } catch (_) {
      final categoryId = product.category?.idCategory ?? product.brand?.idCategory;
      if (categoryId == null) {
        rethrow;
      }
      final brandId = product.idBrand > 0 ? product.idBrand : _resolveBrandIdForCategory(categoryId);
      final payload = {
        'id_brand': brandId,
        'name_product': product.nameProduct.trim(),
        'description_product': (product.descriptionProduct ?? '').trim(),
        'sku': (product.sku?.trim().isNotEmpty ?? false)
            ? product.sku!.trim()
            : 'SKU-$id',
        'price_cop': product.priceCop,
        'stock': product.stock,
        'state_product': false,
      };

      final uri = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.productsUpdate(id)}',
      );
      final response = await http.put(
        uri,
        headers: _getHeaders(),
        body: jsonEncode(payload),
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('No fue posible desactivar producto (${response.statusCode})');
      }
      await refresh();
      return false;
    }
  }

  List<ProductModel> getMostViewedProducts() {
    return _products.take(6).toList();
  }

  List<ProductModel> getProductsByCategory(int categoryId) {
    return _products.where((product) => product.brand?.idCategory == categoryId).toList();
  }

  List<BrandModel> getBrandsByCategory(int? categoryId) {
    if (categoryId == null) return _brands;
    return _brands.where((brand) => brand.idCategory == categoryId).toList();
  }

  int _resolveBrandIdForCategory(int categoryId) {
    final brands = getBrandsByCategory(categoryId);
    if (brands.isEmpty) {
      throw Exception('No hay marcas configuradas para la categoria seleccionada');
    }
    return brands.first.idBrand;
  }

  Future<void> createProductFromCategory({
    required int idCategory,
    required String nameProduct,
    required String descriptionProduct,
    required double priceCop,
    List<File> images = const [],
  }) async {
    final brandId = _resolveBrandIdForCategory(idCategory);
    await createProduct(
      idBrand: brandId,
      nameProduct: nameProduct,
      descriptionProduct: descriptionProduct,
      sku: 'SKU-${DateTime.now().millisecondsSinceEpoch}',
      priceCop: priceCop,
      stock: 1,
      stateProduct: true,
      images: images,
    );
  }

  Future<void> updateProductFromCategory({
    required int idProduct,
    required int idCategory,
    required String nameProduct,
    required String descriptionProduct,
    required double priceCop,
    List<File> newImages = const [],
  }) async {
    final brandId = _resolveBrandIdForCategory(idCategory);
    await updateProduct(
      idProduct: idProduct,
      idBrand: brandId,
      nameProduct: nameProduct,
      descriptionProduct: descriptionProduct,
      sku: 'SKU-$idProduct',
      priceCop: priceCop,
      stock: 1,
      stateProduct: true,
      newImages: newImages,
    );
  }

  Future<void> contactWhatsApp(ProductModel product) async {
    const phoneNumber = '+573025620704';
    final productUrl =
        'https://vcamb.microwesttechnologies.com/product/${product.idProduct}';
    final message =
        'Hola! Quiero mas informacion de este producto: ${product.nameProduct}\n\nLink: $productUrl';

    final whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('No se puede abrir WhatsApp');
      }
    } catch (e) {
      _error = 'Error al abrir WhatsApp: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> refresh() async {
    await initialize(forceRefresh: true);
  }
}
