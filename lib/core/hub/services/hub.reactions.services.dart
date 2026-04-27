import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';

class HubReactionsService {
  final TokenService _tokenService = TokenService();
  static const Set<String> _knownReactionTypes = {
    'like',
    'love',
    'haha',
    'wow',
    'sad',
  };

  Map<String, String> _headers() {
    return {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      ..._tokenService.getAuthHeaders(),
    };
  }

  Future<void> reactToPost(dynamic postId, String type) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostReactionsCreate}',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: jsonEncode({
        'post_id': postId is int ? postId : int.parse(postId.toString()),
        'type': type,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible reaccionar al post (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<void> reactToComment(
    dynamic commentId,
    String type,
  ) async {
    final normalizedId = _normalizeIdentifier(commentId);
    if (normalizedId == null) {
      throw Exception('comment_id inválido');
    }

    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubCommentReactionsCreate}',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: jsonEncode({'comment_id': normalizedId, 'type': type}),
    );
    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible reaccionar al comentario (${response.statusCode}): ${response.body}',
      );
    }
  }

  Future<Map<String, int>> fetchPostReactionsSummary(dynamic postId) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostReactions(postId)}',
    );
    final response = await http.get(url, headers: _headers());
    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar reacciones del post (${response.statusCode}): ${response.body}',
      );
    }
    if (response.statusCode >= 500) {
      throw Exception(
        'Error del servidor al cargar reacciones del post (${response.statusCode}): ${response.body}',
      );
    }
    final dynamic body = jsonDecode(response.body);
    return _extractReactionsMap(body);
  }

  Future<Map<String, int>> fetchCommentReactionsSummary(
    dynamic commentId,
  ) async {
    final normalizedId = _normalizeIdentifier(commentId);
    if (normalizedId == null) {
      return const <String, int>{};
    }

    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubCommentReactions(normalizedId)}',
    );
    final response = await http.get(url, headers: _headers());
    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar reacciones del comentario (${response.statusCode}): ${response.body}',
      );
    }
    final dynamic body = jsonDecode(response.body);
    final parsed = _extractReactionsMap(body);
    if (parsed.isNotEmpty) return parsed;

    // Algunos backends devuelven solo `total` sin detalle por tipo.
    final total = _extractTotalCount(body);
    if (total != null && total >= 0) {
      return <String, int>{'like': total};
    }

    return const <String, int>{};
  }

  Map<String, int> _extractReactionsMap(dynamic body) {
    final fromBody = _extractMapCandidate(body);
    if (fromBody.isNotEmpty) return fromBody;

    if (body is Map<String, dynamic>) {
      final nestedCandidates = <dynamic>[
        body['data'],
        body['summary'],
        body['counts'],
        body['reactions'],
        body['reaction_summary'],
        body['stats'],
      ];

      for (final candidate in nestedCandidates) {
        final parsed = _extractMapCandidate(candidate);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    return const <String, int>{};
  }

  Map<String, int> _extractMapCandidate(dynamic candidate) {
    if (candidate is Map<String, dynamic>) {
      final direct = <String, int>{};
      candidate.forEach((key, value) {
        final normalizedKey = key.trim().toLowerCase();
        if (!_knownReactionTypes.contains(normalizedKey)) return;
        if (value is num) {
          direct[normalizedKey] = value.toInt();
        } else if (value is String) {
          final parsed = int.tryParse(value.trim());
          if (parsed != null) {
            direct[normalizedKey] = parsed;
          }
        }
      });
      if (direct.isNotEmpty) return direct;

      // Backends con estructura: { like: { count: 2 }, ... }
      final objectStyle = <String, int>{};
      candidate.forEach((key, value) {
        final normalizedKey = key.trim().toLowerCase();
        if (!_knownReactionTypes.contains(normalizedKey)) return;
        if (value is Map<String, dynamic>) {
          final count = value['count'] ?? value['total'] ?? value['value'];
          if (count is num) {
            objectStyle[normalizedKey] = count.toInt();
          } else if (count is String) {
            final parsed = int.tryParse(count.trim());
            if (parsed != null) {
              objectStyle[normalizedKey] = parsed;
            }
          }
        }
      });
      if (objectStyle.isNotEmpty) return objectStyle;
    }

    if (candidate is List) {
      // Backends con estructura: [{type: 'like', count: 2}, ...]
      final fromList = <String, int>{};
      for (final row in candidate.whereType<Map<String, dynamic>>()) {
        final type = (row['type'] ?? row['reaction'] ?? row['name'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (!_knownReactionTypes.contains(type)) continue;

        final rawCount = row['count'] ?? row['total'] ?? row['value'];
        if (rawCount is num) {
          fromList[type] = rawCount.toInt();
          continue;
        }
        if (rawCount is String) {
          final parsed = int.tryParse(rawCount.trim());
          if (parsed != null) {
            fromList[type] = parsed;
          }
        }
      }
      if (fromList.isNotEmpty) return fromList;
    }

    return const <String, int>{};
  }

  int? _extractTotalCount(dynamic body) {
    if (body is Map<String, dynamic>) {
      final directTotal = _toInt(body['total']);
      if (directTotal != null) return directTotal;

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final nestedTotal = _toInt(data['total']);
        if (nestedTotal != null) return nestedTotal;
      }
    }
    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  dynamic _normalizeIdentifier(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;

    final raw = value.toString().trim();
    if (raw.isEmpty) return null;

    final numeric = int.tryParse(raw);
    return numeric ?? raw;
  }
}
