import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/video.model.dart';

/// Componente de Training
/// Maneja toda la lógica de videos y categorías de entrenamiento
/// Requiere autenticación mediante token JWT
class TrainingComponent extends ChangeNotifier {
  final TokenService _tokenService = TokenService();
  final SessionCacheService _cache = SessionCacheService();

  // Estado
  List<VideoModel> _videos = [];
  List<VideoModel> _filteredVideos = [];
  List<CategoryVideoModel> _categories = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'Todos los Artículos';
  String _searchQuery = '';

  // Getters
  List<VideoModel> get videos => _filteredVideos;
  List<VideoModel> get allVideos => _videos;
  List<CategoryVideoModel> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;
  String get searchQuery => _searchQuery;

  String _cacheKey(String namespace, [String suffix = '']) {
    return _cache.scopedKey(
      namespace,
      role: _tokenService.getRole() ?? 'guest',
      userId: _tokenService.getUserId() ?? 'guest',
      suffix: suffix,
    );
  }

  /// Obtiene los headers con autenticación si el token está disponible
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Agregar token de autenticación si está disponible
    final token = _tokenService.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  /// Inicializa el componente cargando videos
  Future<void> initialize({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await fetchVideos(forceRefresh: forceRefresh);
      _applyFilters();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtiene todos los videos
  Future<void> fetchVideos({bool forceRefresh = false}) async {
    try {
      final cacheKey = _cacheKey('training::videos');
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
            } else {
              throw Exception('Formato de respuesta no válido');
            }
          } else {
            throw Exception('Formato de respuesta no válido');
          }

          _videos = jsonList
              .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
              .where((video) => video.stateVideo)
              .toList();

          final categoryMap = <int, CategoryVideoModel>{};
          for (final video in _videos) {
            if (video.categoryVideo != null) {
              categoryMap[video.categoryVideo!.idCategoryVideo] =
                  video.categoryVideo!;
            }
          }
          _categories = categoryMap.values.toList();
          return;
        }
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.videosList}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado');
            },
          );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        List<dynamic> jsonList;

        if (jsonResponse is List) {
          jsonList = jsonResponse;
        } else if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data')) {
            jsonList = jsonResponse['data'] as List<dynamic>;
          } else {
            throw Exception('Formato de respuesta no válido');
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }

        _videos = jsonList
            .map((json) => VideoModel.fromJson(json as Map<String, dynamic>))
            .where((video) => video.stateVideo)
            .toList();

        // Extraer categorías únicas de los videos
        final categoryMap = <int, CategoryVideoModel>{};
        for (var video in _videos) {
          if (video.categoryVideo != null) {
            categoryMap[video.categoryVideo!.idCategoryVideo] =
                video.categoryVideo!;
          }
        }
        _categories = categoryMap.values.toList();
        await _cache.write(cacheKey, response.body);
      } else {
        throw Exception('Error al obtener videos: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  /// Filtra videos por categoría
  void filterByCategory(String filterName) {
    _selectedFilter = filterName;
    _applyFilters();
    notifyListeners();
  }

  /// Actualiza la búsqueda y reaplica filtros
  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    notifyListeners();
  }

  /// Aplica los filtros actuales (categoría + búsqueda)
  void _applyFilters() {
    var result = _videos;

    if (_selectedFilter != 'Todos los Artículos') {
      result = result
          .where((v) => v.categoryVideo?.nameCategoryVideo == _selectedFilter)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((v) {
        final title = v.titleVideo.toLowerCase();
        final desc = (v.description ?? v.subtitleVideo ?? '').toLowerCase();
        final cat = v.categoryVideo?.nameCategoryVideo.toLowerCase() ?? '';
        return title.contains(q) || desc.contains(q) || cat.contains(q);
      }).toList();
    }

    _filteredVideos = result;
  }

  /// Obtiene un video por ID
  Future<VideoModel?> getVideoById(int id) async {
    try {
      final cacheKey = _cacheKey('training::video', '$id');
      final cachedBody = await _cache.read(cacheKey);
      if (cachedBody != null) {
        final dynamic jsonResponse = jsonDecode(cachedBody);
        Map<String, dynamic> videoJson;

        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data')) {
            videoJson = jsonResponse['data'] as Map<String, dynamic>;
          } else {
            videoJson = jsonResponse;
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }

        return VideoModel.fromJson(videoJson);
      }

      final url = Uri.parse(
        '${EnvironmentDev.baseUrl}${EnvironmentDev.videosGet(id)}',
      );
      final response = await http
          .get(url, headers: _getHeaders())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Tiempo de espera agotado');
            },
          );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        final dynamic jsonResponse = jsonDecode(response.body);
        Map<String, dynamic> videoJson;

        if (jsonResponse is Map<String, dynamic>) {
          if (jsonResponse.containsKey('data')) {
            videoJson = jsonResponse['data'] as Map<String, dynamic>;
          } else {
            videoJson = jsonResponse;
          }
        } else {
          throw Exception('Formato de respuesta no válido');
        }

        await _cache.write(cacheKey, response.body);
        return VideoModel.fromJson(videoJson);
      } else {
        throw Exception('Error al obtener video: ${response.statusCode}');
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return null;
    }
  }

  /// Recarga los videos
  Future<void> refresh() async {
    await initialize(forceRefresh: true);
  }
}
