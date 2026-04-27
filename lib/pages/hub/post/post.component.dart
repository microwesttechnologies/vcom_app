import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/hub/services/hub.post.services.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/pages/hub/hub_helpers.dart';

/// Componente de lógica de negocio para la gestión de Posts.
class PostComponent extends ChangeNotifier {
  final HubPostsService _postsService = HubPostsService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];
  final Map<int, dynamic> _apiKeyByLocalId = {};
  int _page = HubConstants.defaultPage;
  int _perPage = HubConstants.defaultPerPage;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get posts => _posts;
  Map<int, dynamic> get apiKeyByLocalId => _apiKeyByLocalId;
  int get page => _page;
  int get perPage => _perPage;

  void configure({int page = 1, int perPage = 15}) {
    _page = page;
    _perPage = perPage;
  }

  Future<void> fetchPosts({String? tag}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _postsService.fetchPosts(
        page: _page,
        perPage: _perPage,
        tag: tag,
      );

      _posts = res.posts;
      _apiKeyByLocalId.clear();

      for (final post in _posts) {
        final localId = extractLocalPostId(post);
        if (localId == null) continue;
        _apiKeyByLocalId[localId] = resolvePostApiKey(localId, post);
      }

      _error = null;
    } catch (e) {
      _posts = const [];
      _error = normalizeError(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Crea un post enviando archivos multimedia como multipart.
  Future<bool> createPost({
    required String title,
    required String content,
    int? tagId,
    List<File> mediaFiles = const [],
  }) async {
    try {
      await _postsService.createPost(
        titlePost: title,
        content: content,
        tagId: tagId,
        mediaFiles: mediaFiles,
      );
      _error = null;
      return true;
    } catch (e) {
      _error = normalizeError(e);
      notifyListeners();
      return false;
    }
  }

  /// Extrae el ID local numérico del post.
  static int? extractLocalPostId(Map<String, dynamic> post) {
    final rawId = post['id'] ?? post['id_post'];
    if (rawId is int) return rawId;
    return int.tryParse((rawId ?? '').toString());
  }

  /// Busca una clave API alternativa del post.
  static dynamic resolvePostApiKey(int localId, Map<String, dynamic> post) {
    const idKeys = [
      'id_post',
      'post_uuid',
      'uuid',
      'uid',
      'slug',
      'public_id',
      'publicId',
      'hash',
      'post_key',
      'postId',
    ];
    for (final key in idKeys) {
      final value = post[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return localId;
  }
}
