import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/hub/services/hub.reactions.services.dart';

/// Lógica de negocio para reacciones a posts.
class ReactionByPostComponent extends ChangeNotifier {
  final HubReactionsService _reactionsService = HubReactionsService();

  final Map<int, Map<String, int>> _reactionsByPost = {};
  final Map<int, String> _myReactions = {};
  final Set<int> _inFlight = <int>{};

  Map<int, Map<String, int>> get reactionsByPost => _reactionsByPost;

  String? myReaction(int postId) => _myReactions[postId];
  bool isInFlight(int postId) => _inFlight.contains(postId);

  /// Carga resumen de reacciones de un post.
  Future<void> loadSummary(int localId, dynamic apiKey) async {
    try {
      final summary = await _reactionsService.fetchPostReactionsSummary(apiKey);
      if (summary.isNotEmpty) {
        _reactionsByPost[localId] = summary;
      }
    } catch (_) {}
  }

  /// Reacciona (o actualiza reacción) al post.
  Future<bool> react(int localId, String type, dynamic apiKey) async {
    if (_inFlight.contains(localId)) return false;

    final previous = _myReactions[localId];
    _inFlight.add(localId);
    _myReactions[localId] = type;
    notifyListeners();

    try {
      await _reactionsService.reactToPost(localId, type);

      final summary = await _reactionsService.fetchPostReactionsSummary(apiKey);
      if (summary.isNotEmpty) {
        _reactionsByPost[localId] = summary;
      }
      return true;
    } catch (e) {
      _rollback(localId, previous);
      return false;
    } finally {
      _inFlight.remove(localId);
      notifyListeners();
    }
  }

  /// Formatea el total de reacciones para mostrar.
  String formatCount(int postId) {
    final summary = _reactionsByPost[postId];
    if (summary == null || summary.isEmpty) return '0';
    return '${summary.values.fold<int>(0, (a, b) => a + b)}';
  }

  /// Limpia el estado al refrescar.
  void clear() {
    _reactionsByPost.clear();
  }

  void _rollback(int localId, String? previous) {
    if (previous == null) {
      _myReactions.remove(localId);
    } else {
      _myReactions[localId] = previous;
    }
  }
}
