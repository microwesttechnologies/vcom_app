import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';

class HubApiService {
  final TokenService _tokenService = TokenService();

  Uri _uri({int page = 1, int perPage = 15, String? tag}) {
    final base = EnvironmentDev.baseUrl;
    final path = EnvironmentDev.hubPostsList;
    final uri = Uri.parse('$base$path');
    final qp = <String, String>{'page': '$page', 'per_page': '$perPage'};
    if (tag != null && tag.trim().isNotEmpty) {
      qp['tag'] = tag.trim();
    }

    return uri.replace(queryParameters: qp);
  }

  Map<String, String> _headers() {
    return {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      ..._tokenService.getAuthHeaders(),
    };
  }

  Future<HubPostsResponse> fetchPosts({
    int page = 1,
    int perPage = 15,
    String? tag,
  }) async {
    final response = await http.get(
      _uri(page: page, perPage: perPage, tag: tag),
      headers: _headers(),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'No fue posible cargar publicaciones (${response.statusCode})',
      );
    }

    final body = jsonDecode(response.body);

    List<dynamic> posts;
    int? total;
    int? currentPage;
    int? lastPage;

    if (body is List) {
      posts = body;
    } else if (body is Map<String, dynamic>) {
      final list = body['data'] ?? body['posts'] ?? body['items'];
      posts = (list is List) ? list : const [];

      final meta = body['meta'] ?? body['pagination'] ?? body['page'];
      if (meta is Map<String, dynamic>) {
        total = (meta['total'] ?? meta['total_items']) as int?;
        currentPage = (meta['current_page'] ?? meta['page']) as int?;
        lastPage = (meta['last_page'] ?? meta['pages']) as int?;
      }
    } else {
      posts = const [];
    }

    return HubPostsResponse(
      posts: posts.whereType<Map<String, dynamic>>().toList(growable: false),
      total: total,
      currentPage: currentPage ?? page,
      lastPage: lastPage,
    );
  }
}

class HubPostsResponse {
  final List<Map<String, dynamic>> posts;
  final int? total;
  final int? currentPage;
  final int? lastPage;

  const HubPostsResponse({
    required this.posts,
    this.total,
    this.currentPage,
    this.lastPage,
  });
}
