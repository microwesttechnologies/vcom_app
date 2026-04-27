import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/hub/hub_models.dart';
import 'package:vcom_app/core/hub/services/hub.comments.services.dart';
import 'package:vcom_app/core/hub/services/hub.reactions.services.dart';

/// Lógica de negocio para comentarios de un post.
class CommentsByPostComponent extends ChangeNotifier {
  final HubCommentsService _commentsService = HubCommentsService();
  final HubReactionsService _reactionsService = HubReactionsService();

  final Map<int, List<HubCommentModel>> _commentsByPost = {};
  final Map<String, String> _myCommentReactions = {};
  final Set<int> _inFlightCreate = <int>{};

  Map<int, List<HubCommentModel>> get commentsByPost => _commentsByPost;

  String? myCommentReaction(int postId, dynamic commentId) =>
      _myCommentReactions[_key(postId, commentId)];

  bool isCreateInFlight(int postId) => _inFlightCreate.contains(postId);

  /// Carga comentarios para un post y sincroniza contadores.
  Future<void> loadComments({
    required int localId,
    required dynamic apiKey,
    bool notify = true,
  }) async {
    try {
      var fetched = await _commentsService.fetchPostComments(apiKey);
      fetched = _mergeWithLocalState(localId, fetched);
      fetched = await _syncCounters(fetched);
      _commentsByPost[localId] = fetched;
    } catch (_) {}

    if (notify) notifyListeners();
  }

  /// Crea un comentario en el post.
  Future<bool> addComment(int localId, String content) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return false;
    if (_inFlightCreate.contains(localId)) return false;

    _inFlightCreate.add(localId);
    notifyListeners();

    try {
      final apiKey = localId;
      await _commentsService.createPostComment(localId, trimmed);
      await loadComments(localId: localId, apiKey: apiKey);
      return true;
    } catch (e) {
      return false;
    } finally {
      _inFlightCreate.remove(localId);
      notifyListeners();
    }
  }

  /// Limpia el estado al refrescar.
  void clear() {
    _commentsByPost.clear();
  }

  // ── Merge ──────────────────────────────────────────────────

  List<HubCommentModel> _mergeWithLocalState(
    int localId,
    List<HubCommentModel> incoming,
  ) {
    final current = _commentsByPost[localId] ?? const [];
    final currentById = <int, HubCommentModel>{
      for (final item in current) item.id: item,
    };

    return incoming
        .map((comment) {
          final key = _key(localId, comment.id);
          final existing = currentById[comment.id];

          var count = comment.reactionsCount;
          if (count <= 0 && existing != null && existing.reactionsCount > 0) {
            count = existing.reactionsCount;
          }
          if (count <= 0 && _myCommentReactions.containsKey(key)) {
            count = 1;
          }

          return comment.copyWith(reactionsCount: count);
        })
        .toList(growable: false);
  }

  Future<List<HubCommentModel>> _syncCounters(
    List<HubCommentModel> comments,
  ) async {
    final candidates = comments.where((c) => c.id > 0).toList(growable: false);
    if (candidates.isEmpty) return comments;

    final fetched = await Future.wait<MapEntry<int, int>?>(
      candidates.map((c) async {
        try {
          final summary = await _reactionsService.fetchCommentReactionsSummary(
            c.id,
          );
          final total = summary.values.fold<int>(0, (sum, v) => sum + v);
          return MapEntry(c.id, total);
        } catch (_) {
          return null;
        }
      }),
    );

    final totals = <int, int>{
      for (final e in fetched.whereType<MapEntry<int, int>>()) e.key: e.value,
    };
    if (totals.isEmpty) return comments;

    return comments
        .map((c) {
          final total = totals[c.id];
          return total != null ? c.copyWith(reactionsCount: total) : c;
        })
        .toList(growable: false);
  }

  String _key(int postId, dynamic commentId) =>
      '$postId:${commentId.toString()}';
}
