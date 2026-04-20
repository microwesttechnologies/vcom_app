import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/hub/hub_models.dart';

class HubCommentsService {
  final TokenService _tokenService = TokenService();

  Map<String, String> _headers() {
    return {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      ..._tokenService.getAuthHeaders(),
    };
  }

  Future<List<HubCommentModel>> fetchPostComments(
    dynamic postId, {
    int page = 1,
    int perPage = 15,
  }) async {
    final numericId = postId is int
        ? postId
        : int.tryParse(postId.toString()) ?? postId;
    final url =
        Uri.parse(
          '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostCommentsList}',
        ).replace(
          queryParameters: {
            'post_id': numericId.toString(),
            'page': page.toString(),
            'per_page': perPage.toString(),
          },
        );
    final response = await http.get(url, headers: _headers());
    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar comentarios (${response.statusCode}): ${response.body}',
      );
    }
    final dynamic body = jsonDecode(response.body);
    final list = _extractList(body);
    return list
        .whereType<Map<String, dynamic>>()
        .map(HubCommentModel.fromJson)
        .toList(growable: false);
  }

  Future<void> createPostComment(dynamic postId, String content) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostCommentsCreate}',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: jsonEncode({
        'post_id': postId is int ? postId : int.parse(postId.toString()),
        'content': content,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible crear el comentario (${response.statusCode}): ${response.body}',
      );
    }
  }

  List<dynamic> _extractList(dynamic body) {
    if (body is List) return body;
    if (body is Map<String, dynamic>) {
      final data = body['data'] ?? body['items'] ?? body['comments'];
      if (data is List) return data;
      if (data is Map<String, dynamic>) {
        final nested = data['data'] ?? data['comments'] ?? data['items'];
        if (nested is List) return nested;
      }
    }
    return const [];
  }
}
