import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/hub/hub_upload_media.dart';

int? _readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}

class HubPostsService {
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
        total = _readInt(meta['total'] ?? meta['total_items']);
        currentPage = _readInt(meta['current_page'] ?? meta['page']);
        lastPage = _readInt(meta['last_page'] ?? meta['pages']);
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

  Future<Map<String, dynamic>> postRaw(
    Uri url,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json', ..._headers()},
      body: jsonEncode(body),
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  /// Crea un post con archivos multimedia.
  ///
  /// - Si hay videos → usa el proxy Node (comprime con FFmpeg en VPS).
  /// - Si es solo texto/imágenes → va directo a Laravel (más rápido).
  ///
  /// Usa [dio] para multipart con progreso real de subida.
  /// [onProgress] recibe (bytesSent, totalBytes).
  Future<void> createPost({
    required String titlePost,
    String? content,
    int? tagId,
    List<HubUploadMedia> mediaFiles = const [],
    void Function(int sent, int total)? onProgress,
  }) async {
    final hasVideo = mediaFiles.any((f) => f.type == 'video');

    // Posts con video → proxy Node (compresión FFmpeg en VPS)
    // Posts sin video → directo a Laravel
    final url = hasVideo
        ? '${EnvironmentDev.hubProxyBaseUrl}/api/hub/posts'
        : '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostsList}';

    final formData = FormData();
    formData.fields.add(MapEntry('title_post', titlePost));
    if (content != null && content.isNotEmpty) {
      formData.fields.add(MapEntry('content', content));
    }
    if (tagId != null) {
      formData.fields.add(MapEntry('tag_id', tagId.toString()));
    }

    for (final media in mediaFiles) {
      formData.files.add(
        MapEntry(
          'media[]',
          MultipartFile.fromBytes(
            media.bytes,
            filename: media.filename,
            contentType: DioMediaType.parse(media.mimeType),
          ),
        ),
      );
    }

    final dio = Dio(BaseOptions(
      headers: _headers(),
      sendTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(minutes: 10),
    ));

    final response = await dio.post<dynamic>(
      url,
      data: formData,
      onSendProgress: onProgress != null
          ? (sent, total) => onProgress(sent, total)
          : null,
    );

    if (response.statusCode != null && response.statusCode! >= 400) {
      throw Exception(
        'No fue posible crear la publicación (${response.statusCode})',
      );
    }
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
