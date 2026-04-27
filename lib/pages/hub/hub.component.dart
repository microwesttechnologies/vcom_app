import 'package:flutter/material.dart';
import 'package:vcom_app/core/hub/hub_models.dart';
import 'package:vcom_app/core/hub/hub_tags.service.dart';
import 'package:vcom_app/pages/hub/comments_by_post/comments_by_post.component.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/pages/hub/hub_helpers.dart';
import 'package:vcom_app/pages/hub/post/post.component.dart';
import 'package:vcom_app/pages/hub/reaction_by_post/reaction_by_post.component.dart';
import 'package:vcom_app/pages/hub/reactions_by_comment/reactions_by_comment.component.dart';
import 'package:vcom_app/pages/hub/tags/tags.component.dart';

/// Facade que orquesta los sub-componentes del módulo Hub.
class HubComponent extends ChangeNotifier {
  final PostComponent _postComponent = PostComponent();
  final CommentsByPostComponent _commentsComponent = CommentsByPostComponent();
  final ReactionByPostComponent _reactionByPost = ReactionByPostComponent();
  final ReactionsByCommentComponent _reactionsByComment =
      ReactionsByCommentComponent();
  final TagsComponent _tagsComponent = TagsComponent();

  String? _error;

  // ── Getters delegados ──────────────────────────────────────

  bool get isLoading => _postComponent.isLoading;
  String? get error => _error ?? _postComponent.error;
  List<Map<String, dynamic>> get posts => _postComponent.posts;
  Map<int, dynamic> get apiKeyByLocalId => _postComponent.apiKeyByLocalId;

  Map<int, List<HubCommentModel>> get commentsByPost =>
      _commentsComponent.commentsByPost;
  Map<int, Map<String, int>> get reactionsByPost =>
      _reactionByPost.reactionsByPost;

  List<HubTag> get tags => _tagsComponent.tags;
  HubTag? get selectedTag => _tagsComponent.selectedTag;

  String? myPostReaction(int postId) => _reactionByPost.myReaction(postId);
  String? myCommentReaction(int postId, dynamic commentId) =>
      _reactionsByComment.myReaction(postId, commentId);

  bool isPostReactionInFlight(int postId) => _reactionByPost.isInFlight(postId);
  bool isCommentReactionInFlight(int postId, dynamic commentId) =>
      _reactionsByComment.isInFlight(postId, commentId);
  bool isCommentCreateInFlight(int postId) =>
      _commentsComponent.isCreateInFlight(postId);

  // ── Ciclo de vida ──────────────────────────────────────────

  Future<void> initialize({
    int page = HubConstants.defaultPage,
    int perPage = HubConstants.defaultPerPage,
    String? tag,
  }) async {
    _postComponent.configure(page: page, perPage: perPage);
    await fetchPosts(tag: tag);
    await _tagsComponent.loadTags();
    notifyListeners();
  }

  Future<void> fetchPosts({String? tag}) async {
    _error = null;
    await _postComponent.fetchPosts(tag: tag);
    _commentsComponent.clear();
    _reactionByPost.clear();

    for (final post in _postComponent.posts) {
      final localId = PostComponent.extractLocalPostId(post);
      if (localId == null) continue;
      final apiKey = _postComponent.apiKeyByLocalId[localId] ?? localId;
      _loadPostMeta(localId, apiKey);
    }

    notifyListeners();
  }

  Future<void> refresh() async {
    await fetchPosts(tag: _tagsComponent.selectedTag?.slug);
    await _tagsComponent.loadTags();
    notifyListeners();
  }

  // ── Crear post ─────────────────────────────────────────────

  Future<bool> createPost({
    required String title,
    required String content,
    HubTag? tag,
    String? mediaUrl,
  }) async {
    final media = (mediaUrl != null && mediaUrl.trim().isNotEmpty)
        ? [
            {
              'type': 'image',
              'url': mediaUrl.trim(),
              'mime_type': 'image/*',
              'file_size': 0,
              'sort_order': 0,
            },
          ]
        : <Map<String, dynamic>>[];

    final ok = await _postComponent.createPost(
      title: title,
      content: content,
      tagId: tag?.id,
      media: media.isEmpty ? null : media,
    );

    if (ok) await refresh();
    _error = _postComponent.error;
    notifyListeners();
    return ok;
  }

  // ── Reacciones a post ──────────────────────────────────────

  Future<bool> reactToPost(int localId, String type) async {
    final apiKey = _postComponent.apiKeyByLocalId[localId] ?? localId;
    final ok = await _reactionByPost.react(localId, type, apiKey);
    if (!ok) _error = normalizeError('No se pudo reaccionar');
    notifyListeners();
    return ok;
  }

  // ── Reacciones a comentarios ───────────────────────────────

  Future<bool> reactToComment(
    int localId,
    dynamic commentId,
    String type,
  ) async {
    final apiKey = _postComponent.apiKeyByLocalId[localId] ?? localId;
    final ok = await _reactionsByComment.react(
      localId: localId,
      commentId: commentId,
      type: type,
      apiKey: apiKey,
      commentsByPost: _commentsComponent.commentsByPost,
    );
    if (!ok) _error = 'No se pudo reaccionar al comentario';
    notifyListeners();
    return ok;
  }

  // ── Comentarios ────────────────────────────────────────────

  Future<bool> addComment(int localId, String content) async {
    final ok = await _commentsComponent.addComment(localId, content);
    if (!ok) _error = 'No se pudo crear el comentario';
    notifyListeners();
    return ok;
  }

  // ── Tags ───────────────────────────────────────────────────

  void selectTag(HubTag? tag) {
    _tagsComponent.selectTag(tag);
    fetchPosts(tag: tag?.slug);
  }

  // ── Carga de metadata por post ─────────────────────────────

  Future<void> _loadPostMeta(int localId, dynamic apiKey) async {
    await _commentsComponent.loadComments(
      localId: localId,
      apiKey: apiKey,
      notify: false,
    );
    await _reactionByPost.loadSummary(localId, apiKey);
    notifyListeners();
  }
}
