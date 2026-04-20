import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';

class HubReactionsService {
  final TokenService _tokenService = TokenService();

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
    dynamic postId,
    dynamic commentId,
    String type,
  ) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubCommentReactionsCreate}',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: jsonEncode({
        'comment_id': commentId is int
            ? commentId
            : int.parse(commentId.toString()),
        'type': type,
      }),
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
    dynamic postId,
    int commentId,
  ) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubCommentReactions(postId, commentId)}',
    );
    final response = await http.get(url, headers: _headers());
    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar reacciones del comentario (${response.statusCode}): ${response.body}',
      );
    }
    final dynamic body = jsonDecode(response.body);
    return _extractReactionsMap(body);
  }

  Map<String, int> _extractReactionsMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final map = <String, int>{};
      body.forEach((key, value) {
        if (value is num) map[key] = value.toInt();
      });
      if (map.isNotEmpty) return map;
      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final inner = <String, int>{};
        data.forEach((key, value) {
          if (value is num) inner[key] = value.toInt();
        });
        return inner;
      }
    }
    return const {};
  }
}
