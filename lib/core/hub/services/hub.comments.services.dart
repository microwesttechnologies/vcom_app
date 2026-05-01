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

  /// Misma resolución que en [fetchPostComments]: id numérico o UUID/string.
  dynamic _resolvePostIdForBody(dynamic postId) {
    if (postId is int) return postId;
    final parsed = int.tryParse(postId.toString());
    return parsed ?? postId.toString();
  }

  Exception _exceptionFromResponse(http.Response r) {
    try {
      final dynamic body = jsonDecode(r.body);
      if (body is Map<String, dynamic>) {
        final msg = body['message'];
        if (msg is String && msg.trim().isNotEmpty) {
          return Exception('$msg (${r.statusCode})');
        }
        final errs = body['errors'];
        if (errs is Map<String, dynamic> && errs.isNotEmpty) {
          final firstKey = errs.keys.first;
          final v = errs[firstKey];
          if (v is List && v.isNotEmpty) {
            return Exception('${v.first} (${r.statusCode})');
          }
        }
      }
    } catch (_) {}
    return Exception(
      'No fue posible crear el comentario (${r.statusCode}): ${r.body}',
    );
  }

  /// [postId] suele ser el UUID o clave pública del post; [numericPostId] es el
  /// `id` entero del listado (misma clave que usa [HubPage] al abrir comentarios).
  Future<void> createPostComment(
    dynamic postId,
    String content, {
    required int numericPostId,
  }) async {
    final resolvedId = _resolvePostIdForBody(postId);
    final headers = {'Content-Type': 'application/json', ..._headers()};
    final base = EnvironmentDev.baseUrl;

    Future<http.Response> post(Uri uri, Map<String, dynamic> body) =>
        http.post(uri, headers: headers, body: jsonEncode(body));

    final nestedUri = Uri.parse(
      '$base${EnvironmentDev.hubPostComments(resolvedId.toString())}',
    );
    final flatUri = Uri.parse('$base${EnvironmentDev.hubPostCommentsCreate}');

    final attempts = <Future<http.Response> Function()>[
      // Lo más habitual en Laravel: FK entera hub_posts.id
      () => post(flatUri, {'post_id': numericPostId, 'content': content}),
      () => post(flatUri, {'post_id': numericPostId, 'body': content}),
      () => post(flatUri, {'id_post': numericPostId, 'content': content}),
      () => post(flatUri, {'hub_post_id': numericPostId, 'content': content}),
      () => post(flatUri, {'hub_post_id': numericPostId, 'body': content}),
      // REST anidada con UUID o id en la ruta
      () => post(nestedUri, {'content': content}),
      // Fallback: mismo identificador que en GET ?post_id=
      () => post(flatUri, {'post_id': resolvedId, 'content': content}),
      () => post(flatUri, {'id_post': resolvedId, 'content': content}),
    ];

    http.Response? lastBad;
    for (final attempt in attempts) {
      final response = await attempt();
      if (response.statusCode < 400) return;
      lastBad = response;
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw _exceptionFromResponse(response);
      }
    }
    if (lastBad != null) throw _exceptionFromResponse(lastBad);
    throw Exception('No fue posible crear el comentario');
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
