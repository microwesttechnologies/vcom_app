import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/hub/hub_models.dart';
import 'package:vcom_app/core/hub/services/hub.reactions.services.dart';

/// Lógica de negocio para reacciones a comentarios.
class ReactionsByCommentComponent extends ChangeNotifier {
  final HubReactionsService _reactionsService = HubReactionsService();

  final Map<String, String> _myReactions = {};
  final Set<String> _inFlight = <String>{};

  String? myReaction(int postId, dynamic commentId) =>
      _myReactions[_key(postId, commentId)];

  bool isInFlight(int postId, dynamic commentId) =>
      _inFlight.contains(_key(postId, commentId));

  /// Reacciona (o actualiza reacción) al comentario.
  Future<bool> react({
    required int localId,
    required dynamic commentId,
    required String type,
    required dynamic apiKey,
    required Map<int, List<HubCommentModel>> commentsByPost,
  }) async {
    final normalizedId = _normalize(commentId);
    if (normalizedId == null) return false;

    final key = _key(localId, normalizedId);
    if (_inFlight.contains(key)) return false;

    final previous = _myReactions[key];
    _inFlight.add(key);
    _myReactions[key] = type;
    notifyListeners();

    try {
      await _reactionsService.reactToComment(normalizedId, type);

      final summary = await _reactionsService
          .fetchCommentReactionsSummary(normalizedId);

      final numericId = normalizedId is int
          ? normalizedId
          : int.tryParse(normalizedId.toString());

      if (summary.isNotEmpty && numericId != null && numericId > 0) {
        final total =
            summary.values.fold<int>(0, (sum, v) => sum + v);
        _updateCount(
          commentsByPost: commentsByPost,
          localId: localId,
          commentId: numericId,
          count: total,
        );
      }
      return true;
    } catch (_) {
      _rollback(key, previous);
      return false;
    } finally {
      _inFlight.remove(key);
      notifyListeners();
    }
  }

  void _updateCount({
    required Map<int, List<HubCommentModel>> commentsByPost,
    required int localId,
    required int commentId,
    required int count,
  }) {
    final current = commentsByPost[localId];
    if (current == null || current.isEmpty) return;

    commentsByPost[localId] = current
        .map((c) =>
            c.id == commentId ? c.copyWith(reactionsCount: count) : c)
        .toList(growable: false);
  }

  void _rollback(String key, String? previous) {
    if (previous == null) {
      _myReactions.remove(key);
    } else {
      _myReactions[key] = previous;
    }
  }

  dynamic _normalize(dynamic value) {
    if (value == null) return null;
    if (value is int) return value > 0 ? value : null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final asInt = int.tryParse(raw);
    if (asInt != null) return asInt > 0 ? asInt : null;
    return raw;
  }

  String _key(int postId, dynamic commentId) =>
      '$postId:${commentId.toString()}';
}
