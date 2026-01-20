import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/models/product.model.dart';
import 'package:vcom_app/core/models/category.model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Componente de la tienda
/// Maneja toda la lógica de productos, categorías y funcionalidades de la tienda
class ShopComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  
  // Estado
  List<ProductModel> _products = [];
  List<ProductModel> _filteredProducts = [];
  List<CategoryModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;
  String _searchQuery = '';

  // Getters
  List<ProductModel> get products => _filteredProducts;
  List<ProductModel> get allProducts => _products;
  List<CategoryModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;

  /// Obtiene los headers con autenticación
  Map<String, String> _getHeaders() {
    final token = _tokenService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  /// Inicializa el componente cargando productos y categorías
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        fetchCategories(),
        fetchProducts(),
      ]);
      _applyFilters();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene todas las categorías
  Future<void> fetchCategories() async {
    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.categoriesList}');
      final response = await http.get(url, headers: _getHeaders());

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
          } else {
            final listValues = jsonResponse.values.where((value) => value is List).toList();
            if (listValues.isNotEmpty) {
              jsonList = listValues.first as List<dynamic>;
            } else {
              throw Exception('No se encontró la lista de categorías');
            }
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }
        
        _categories = jsonList
            .map((json) => CategoryModel.fromJson(json as Map<String, dynamic>))
            .where((category) => category.stateCategory)
            .toList();
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  /// Obtiene todos los productos
  Future<void> fetchProducts() async {
    try {
      final url = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.productsList}');
      final response = await http.get(url, headers: _getHeaders());

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> jsonList;
        
        if (jsonResponse is List) {
          jsonList = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data')) {
            jsonList = jsonResponse['data'] as List<dynamic>;
          } else if (jsonResponse.containsKey('products')) {
            jsonList = jsonResponse['products'] as List<dynamic>;
          } else {
            final listValues = jsonResponse.values.where((value) => value is List).toList();
            if (listValues.isNotEmpty) {
              jsonList = listValues.first as List<dynamic>;
            } else {
              throw Exception('No se encontró la lista de productos');
            }
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }
        
        _products = jsonList
            .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
            .where((product) => product.stateProduct && product.stock > 0)
            .toList();
            
        // Ordenar por productos más vistos (simulado por fecha de creación más reciente)
        _products.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        
      } else {
        throw Exception('Error al obtener productos: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  /// Filtra productos por categoría
  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _applyFilters();
    notifyListeners();
  }

  /// Busca productos por texto
  void searchProducts(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  /// Aplica todos los filtros activos
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Filtro por categoría
      bool matchesCategory = _selectedCategoryId == null || 
          product.brand?.idCategory == _selectedCategoryId;
      
      // Filtro por búsqueda de texto
      bool matchesSearch = _searchQuery.isEmpty ||
          product.nameProduct.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (product.descriptionProduct?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (product.brand?.nameBrand.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Obtiene productos más vistos (primeros 6)
  List<ProductModel> getMostViewedProducts() {
    return _products.take(6).toList();
  }

  /// Obtiene productos por categoría
  List<ProductModel> getProductsByCategory(int categoryId) {
    return _products.where((product) => product.brand?.idCategory == categoryId).toList();
  }

  /// Abre WhatsApp con mensaje predefinido
  Future<void> contactWhatsApp(ProductModel product) async {
    const phoneNumber = '+573025620704';
    final productUrl = 'https://vcamb.microwesttechnologies.com/product/${product.idProduct}';
    final message = 'Hola! Quiero más información de este producto: ${product.nameProduct}\n\nLink: $productUrl';
    
    final whatsappUrl = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}'
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

  /// Limpia filtros
  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _applyFilters();
    notifyListeners();
  }

  /// Limpia errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Recarga datos
  Future<void> refresh() async {
    await initialize();
  }
}
