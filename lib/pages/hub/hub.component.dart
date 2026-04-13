import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/common/session_state_registry.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/hub/hub_comments.service.dart';
import 'package:vcom_app/core/hub/hub_posts.service.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';
import 'package:vcom_app/core/models/hub_author.model.dart';
import 'package:vcom_app/core/models/hub_comment.model.dart';
import 'package:vcom_app/core/models/hub_media.model.dart';
import 'package:vcom_app/core/models/hub_post.model.dart';
import 'package:vcom_app/core/models/hub_tag.model.dart';

class HubComponent extends ChangeNotifier {
  static final HubComponent _instance = HubComponent._internal();
  factory HubComponent() => _instance;

  HubComponent._internal({
    HubTagsService? tagsService,
    HubPostsService? postsService,
    HubCommentsService? commentsService,
  }) : _tagsService = tagsService ?? HubTagsService(),
       _postsService = postsService ?? HubPostsService(),
       _commentsService = commentsService ?? HubCommentsService() {
    SessionStateRegistryService().register('hub_component', resetSessionState);
  }

  final HubTagsService _tagsService;
  final HubPostsService _postsService;
  final HubCommentsService _commentsService;
  final TokenService _tokenService = TokenService();

  static const int _perPage = 10;
  Timer? _searchDebounce;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _initialized = false;
  String? _error;
  int _currentPage = 1;
  int? _selectedTagId;
  String _searchQuery = '';
  List<HubTagModel> _tags = const [];
  List<HubPostModel> _posts = const [];

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  int? get selectedTagId => _selectedTagId;
  String get searchQuery => _searchQuery;
  List<HubTagModel> get tags => List.unmodifiable(_tags);
  List<HubPostModel> get posts => List.unmodifiable(_posts);

  bool get canCreatePosts {
    final role = (_tokenService.getRole() ?? '').trim().toUpperCase();
    return role == 'ADMIN' || role == 'MONITOR';
  }

  Future<void> initialize({bool forceRefresh = false}) async {
    if (_initialized && !forceRefresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tags = await _tagsService.fetchTags();
      await _loadPosts(resetData: true);
      _initialized = true;
    } catch (e) {
      _error = 'No fue posible cargar Hub: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _error = null;
    _isLoading = true;
    notifyListeners();

    try {
      await _loadPosts(resetData: true);
    } catch (e) {
      _error = 'No fue posible refrescar Hub: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      await _loadPosts(resetData: false);
    } catch (e) {
      _error = 'No fue posible cargar mas publicaciones: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setSelectedTag(int? tagId) {
    if (_selectedTagId == tagId) return;
    _selectedTagId = tagId;
    unawaited(refresh());
  }

  void onSearchChanged(String value) {
    final normalized = value.trim();
    if (_searchQuery == normalized) return;

    _searchQuery = normalized;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(refresh());
    });
  }

  Future<void> toggleReaction(int postId) async {
    try {
      final updated = await _postsService.toggleReaction(postId: postId);
      final index = _posts.indexWhere((post) => post.id == postId);
      if (index < 0) return;
      final nextPosts = [..._posts];
      nextPosts[index] = updated;
      _posts = nextPosts;
      notifyListeners();
    } catch (e) {
      _error = 'No fue posible registrar tu reaccion: $e';
      notifyListeners();
    }
  }

  Future<HubCommentPageResult> loadComments({
    required int postId,
    required int page,
    int perPage = 10,
  }) {
    return _commentsService.fetchComments(
      postId: postId,
      page: page,
      perPage: perPage,
    );
  }

  Future<HubCommentModel?> addComment({
    required int postId,
    required String content,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return null;

    final comment = await _commentsService.addComment(
      postId: postId,
      author: _currentAuthor(),
      content: trimmed,
    );

    _postsService.incrementCommentsCount(postId);
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index >= 0) {
      final nextPosts = [..._posts];
      final post = nextPosts[index];
      nextPosts[index] = post.copyWith(commentsCount: post.commentsCount + 1);
      _posts = nextPosts;
      notifyListeners();
    }
    return comment;
  }

  Future<HubPostModel?> createPost({
    required HubTagModel tag,
    required String content,
    required List<HubMediaModel> media,
  }) async {
    if (!canCreatePosts) {
      throw StateError('Solo admin y monitor pueden crear publicaciones.');
    }

    final trimmed = content.trim();
    if (trimmed.isEmpty && media.isEmpty) {
      throw StateError('El post debe tener contenido o al menos un archivo.');
    }

    final post = await _postsService.createPost(
      author: _currentAuthor(),
      tag: tag,
      content: trimmed,
      media: media,
    );

    final nextPosts = [post, ..._posts];
    _posts = nextPosts;
    notifyListeners();
    return post;
  }

  void resetSessionState() {
    _isLoading = false;
    _isLoadingMore = false;
    _hasMore = true;
    _initialized = false;
    _error = null;
    _currentPage = 1;
    _selectedTagId = null;
    _searchQuery = '';
    _tags = const [];
    _posts = const [];
    _searchDebounce?.cancel();
    notifyListeners();
  }

  Future<void> _loadPosts({required bool resetData}) async {
    if (resetData) {
      _currentPage = 1;
      _hasMore = true;
      _posts = const [];
    }

    final result = await _postsService.fetchPosts(
      page: _currentPage,
      perPage: _perPage,
      searchQuery: _searchQuery,
      tagId: _selectedTagId,
    );

    _hasMore = result.hasMore;
    if (resetData) {
      _posts = result.data;
    } else {
      _posts = [..._posts, ...result.data];
    }

    if (result.data.isNotEmpty) {
      _currentPage += 1;
    }
  }

  HubAuthorModel _currentAuthor() {
    final name = _tokenService.getUserName()?.trim();
    final role = (_tokenService.getRole() ?? 'usuario').trim();
    final userId = _tokenService.getUserId()?.trim();

    return HubAuthorModel(
      id: userId != null && userId.isNotEmpty ? userId : 'anonymous',
      type: 'current',
      name: name != null && name.isNotEmpty ? name : 'Usuario',
      role: role.isNotEmpty ? role.toLowerCase() : 'usuario',
    );
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
