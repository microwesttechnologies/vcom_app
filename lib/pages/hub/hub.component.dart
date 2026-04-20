import 'package:flutter/material.dart';
import 'package:vcom_app/core/hub/services/hub.post.services.dart';
import 'package:vcom_app/core/hub/services/hub.comments.services.dart';
import 'package:vcom_app/core/hub/services/hub.reactions.services.dart';
import 'package:vcom_app/core/hub/hub_models.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'dart:convert';

class HubComponent extends ChangeNotifier {
  final HubPostsService _postsService = HubPostsService();
  final HubCommentsService _commentsService = HubCommentsService();
  final HubReactionsService _reactionsService = HubReactionsService();
  final HubTagsService _tagsService = HubTagsService();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _posts = const [];
  final Map<int, List<HubCommentModel>> _commentsByPost = {};
  final Map<int, Map<String, int>> _reactionsByPost = {};
  final Map<int, dynamic> _apiKeyByLocalId = {};
  int _page = 1;
  int _perPage = 15;
  List<HubTag> _tags = const [];
  HubTag? _selectedTag;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Map<String, dynamic>> get posts => _posts;
  Map<int, List<HubCommentModel>> get commentsByPost => _commentsByPost;
  Map<int, Map<String, int>> get reactionsByPost => _reactionsByPost;
  Map<int, dynamic> get apiKeyByLocalId => _apiKeyByLocalId;
  int get page => _page;
  int get perPage => _perPage;
  List<HubTag> get tags => _tags;
  HubTag? get selectedTag => _selectedTag;

  Future<void> initialize({int page = 1, int perPage = 15, String? tag}) async {
    _page = page;
    _perPage = perPage;
    await fetchPosts(tag: tag);
    await _loadTags();
  }

  String? _detectUuidFromMap(Map<String, dynamic> m) {
    final reg = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      multiLine: false,
    );
    for (final entry in m.entries) {
      final v = entry.value;
      if (v is String && reg.hasMatch(v)) return v;
      if (v is Map<String, dynamic>) {
        final nested = _detectUuidFromMap(v);
        if (nested != null) return nested;
      }
    }
    return null;
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
      // Pre-cargar comentarios y reacciones por post en segundo plano (listado)
      for (final post in _posts) {
        final dynamic rawId = post['id'] ?? post['id_post'];
        final int? localId = rawId is int
            ? rawId
            : int.tryParse(rawId?.toString() ?? '');
        if (localId == null) continue;
        // Derivar clave para API SOLO desde campos que representen el post,
        // evitando capturar author_id u otros UUID no relacionados.
        dynamic apiKeyCandidate;
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
        for (final k in idKeys) {
          final v = post[k];
          if (v != null && v.toString().trim().isNotEmpty) {
            apiKeyCandidate = v;
            break;
          }
        }
        final dynamic apiKey =
            (apiKeyCandidate != null && apiKeyCandidate.toString().isNotEmpty)
            ? apiKeyCandidate
            : localId; // Fallback seguro al ID numérico
        _apiKeyByLocalId[localId] = apiKey;
        // Debug map
        // ignore: avoid_print
        print(
          '[HubComponent] map localId=$localId -> apiKey="$apiKey" (rawId=$rawId)',
        );
        // Fire-and-forget: cargar comentarios y reacciones
        _loadPostMeta(localId, apiKey);
      }
      _error = null;
    } catch (e) {
      _posts = const [];
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // DEBUG STEP-BY-STEP MODALS
  Future<void> _showStepDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1729),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: SelectableText(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> debugReactToPost(
    BuildContext context,
    int localId,
    String type,
  ) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostReactionsCreate}',
    );
    final body = {'post_id': localId, 'type': type};
    await _showStepDialog(context, 'Paso 1: Endpoint', url.toString());
    await _showStepDialog(context, 'Paso 2: Body', jsonEncode(body));
    final res = await _postsService.postRaw(url, body);
    await _showStepDialog(
      context,
      'Paso 3: Respuesta',
      'HTTP ${res['statusCode']}\n${res['body']}',
    );
    final status = (res['statusCode'] as int?) ?? 500;
    if (status >= 400) {
      _error = (res['body'] as String?) ?? 'HTTP $status';
      notifyListeners();
      return false;
    }
    try {
      final apiKey = _apiKeyByLocalId[localId] ?? localId;
      final summary = await _reactionsService.fetchPostReactionsSummary(apiKey);
      _reactionsByPost[localId] = summary;
      _error = null;
      notifyListeners();
    } catch (_) {}
    return true;
  }

  Future<bool> debugCreatePost(
    BuildContext context, {
    required String title,
    required String content,
    HubTag? tag,
    String? mediaUrl,
  }) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostsList}',
    );
    final body = <String, dynamic>{
      'title_post': title,
      'content': content,
      if (tag != null) 'tag_id': tag.id,
      if (mediaUrl != null && mediaUrl.trim().isNotEmpty)
        'media': [
          {
            'type': 'image',
            'url': mediaUrl.trim(),
            'mime_type': 'image/*',
            'file_size': 0,
            'sort_order': 0,
          },
        ],
    };
    await _showStepDialog(context, 'Paso 1: Endpoint', url.toString());
    await _showStepDialog(context, 'Paso 2: Body', jsonEncode(body));
    try {
      await _postsService.createPost(body);
    } catch (e) {
      await _showStepDialog(context, 'Paso 3: Respuesta', e.toString());
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
    await _showStepDialog(context, 'Paso 3: Respuesta', 'HTTP 201');
    try {
      await refresh();
      _error = null;
    } catch (_) {}
    return true;
  }

  Future<bool> debugReactToComment(
    BuildContext context,
    int localId,
    dynamic commentId,
    String type,
  ) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubCommentReactionsCreate}',
    );
    final body = {
      'comment_id': commentId is int
          ? commentId
          : int.tryParse(commentId.toString()) ?? commentId,
      'type': type,
    };
    await _showStepDialog(context, 'Paso 1: Endpoint', url.toString());
    await _showStepDialog(context, 'Paso 2: Body', jsonEncode(body));
    final res = await _postsService.postRaw(url, body);
    await _showStepDialog(
      context,
      'Paso 3: Respuesta',
      'HTTP ${res['statusCode']}\n${res['body']}',
    );
    final status = (res['statusCode'] as int?) ?? 500;
    if (status >= 400) {
      _error = (res['body'] as String?) ?? 'HTTP $status';
      notifyListeners();
      return false;
    }
    try {
      final apiKey = _apiKeyByLocalId[localId] ?? localId;
      final comments = await _commentsService.fetchPostComments(apiKey);
      _commentsByPost[localId] = comments;
      _error = null;
      notifyListeners();
    } catch (_) {}
    return true;
  }

  Future<bool> debugAddComment(
    BuildContext context,
    int localId,
    String content,
  ) async {
    final apiKey = _apiKeyByLocalId[localId] ?? localId;
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostCommentsCreate}',
    );
    final body = {'post_id': localId, 'content': content, 'text': content};
    await _showStepDialog(context, 'Paso 1: Endpoint', url.toString());
    await _showStepDialog(context, 'Paso 2: Body', jsonEncode(body));
    final res = await _postsService.postRaw(url, body);
    await _showStepDialog(
      context,
      'Paso 3: Respuesta',
      'HTTP ${res['statusCode']}\n${res['body']}',
    );
    final status = (res['statusCode'] as int?) ?? 500;
    if (status >= 400) {
      _error = (res['body'] as String?) ?? 'HTTP $status';
      notifyListeners();
      return false;
    }
    try {
      final comments = await _commentsService.fetchPostComments(apiKey);
      _commentsByPost[localId] = comments;
      _error = null;
      notifyListeners();
    } catch (_) {}
    return true;
  }

  Future<void> refresh() async {
    await fetchPosts(tag: _selectedTag?.slug);
    await _loadTags();
  }

  Future<void> _loadPostMeta(int localId, dynamic apiKey) async {
    try {
      final comments = await _commentsService.fetchPostComments(apiKey);
      _commentsByPost[localId] = comments;
    } catch (_) {}

    try {
      final summary = await _reactionsService.fetchPostReactionsSummary(apiKey);
      _reactionsByPost[localId] = summary;
    } catch (_) {}

    notifyListeners();
  }

  Future<bool> reactToPost(int localId, String type) async {
    try {
      final apiKey = _apiKeyByLocalId[localId] ?? localId;
      // ignore: avoid_print
      print(
        '[HubComponent] reactToPost localId=$localId apiKey=$apiKey type=$type',
      );
      // Use localId for creation endpoint which expects an integer post_id
      await _reactionsService.reactToPost(localId, type);
      final summary = await _reactionsService.fetchPostReactionsSummary(apiKey);
      _reactionsByPost[localId] = summary;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> reactToComment(
    int localId,
    dynamic commentId,
    String type,
  ) async {
    try {
      final apiKey = _apiKeyByLocalId[localId] ?? localId;
      // ignore: avoid_print
      print(
        '[HubComponent] reactToComment localId=$localId apiKey=$apiKey commentId=$commentId type=$type',
      );
      await _reactionsService.reactToComment(apiKey, commentId, type);
      // Refrescar comentarios para reflejar conteos
      final comments = await _commentsService.fetchPostComments(apiKey);
      _commentsByPost[localId] = comments;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadTags() async {
    try {
      _tags = await _tagsService.fetchTags();
    } catch (_) {
      _tags = const [];
    } finally {
      notifyListeners();
    }
  }

  void selectTag(HubTag? tag) {
    _selectedTag = tag;
    fetchPosts(tag: tag?.slug);
  }

  Future<bool> addComment(int localId, String content) async {
    _isLoading = true;
    notifyListeners();
    try {
      final apiKey = _apiKeyByLocalId[localId] ?? localId;
      // ignore: avoid_print
      print(
        '[HubComponent] addComment localId=$localId apiKey=$apiKey contentLen=${content.length}',
      );
      await _commentsService.createPostComment(localId, content);
      final comments = await _commentsService.fetchPostComments(apiKey);
      _commentsByPost[localId] = comments;
      _error = null;
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
