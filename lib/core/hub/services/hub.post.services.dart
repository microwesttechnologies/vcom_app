import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/hub/hub_upload_media.dart';

int? _readInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.round();
  return int.tryParse(v.toString());
}

/// Timeout generoso para subidas de video grandes (10 min).
const _uploadTimeout = Duration(minutes: 10);

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

  /// Crea un post con archivos multimedia como multipart.
  ///
  /// [onProgress] recibe (bytesSent, totalBytes) en tiempo real mientras
  /// se transmiten los datos al servidor.
  Future<void> createPost({
    required String titlePost,
    String? content,
    int? tagId,
    List<HubUploadMedia> mediaFiles = const [],
    void Function(int sent, int total)? onProgress,
  }) async {
    final url = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostsList}',
    );

    final multipart = http.MultipartRequest('POST', url)
      ..headers.addAll(_headers());

    multipart.fields['title_post'] = titlePost;
    if (content != null && content.isNotEmpty) {
      multipart.fields['content'] = content;
    }
    if (tagId != null) {
      multipart.fields['tag_id'] = tagId.toString();
    }

    for (final media in mediaFiles) {
      multipart.files.add(
        http.MultipartFile.fromBytes(
          'media[]',
          media.bytes,
          filename: media.filename,
          contentType: MediaType.parse(media.mimeType),
        ),
      );
    }

    // Sin progreso: envío directo con timeout.
    if (onProgress == null) {
      final streamed = await multipart.send().timeout(_uploadTimeout);
      final responseBody = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 400) {
        throw Exception(
          'No fue posible crear la publicación (${streamed.statusCode}): $responseBody',
        );
      }
      return;
    }

    // Con progreso: convertir el multipart a StreamedRequest para rastrear
    // los bytes que salen hacia el servidor.
    final byteStream = multipart.finalize();
    final total = multipart.contentLength;

    final tracked = http.StreamedRequest('POST', url);
    tracked.headers.addAll(multipart.headers);
    tracked.contentLength = total;

    var sent = 0;
    final completer = Completer<void>();

    byteStream.listen(
      (chunk) {
        tracked.sink.add(chunk);
        sent += chunk.length;
        onProgress(sent, total);
      },
      onDone: () {
        tracked.sink.close();
        completer.complete();
      },
      onError: (Object e, StackTrace st) {
        tracked.sink.addError(e, st);
        if (!completer.isCompleted) completer.completeError(e, st);
      },
      cancelOnError: true,
    );

    // Lanzar el envío al servidor en paralelo con la escritura del stream.
    final responseFuture = http.Client().send(tracked).timeout(_uploadTimeout);

    // Esperar a que terminen tanto la escritura como la respuesta.
    await Future.wait([completer.future, responseFuture]).then((results) async {
      final streamed = results[1] as http.StreamedResponse;
      final responseBody = await streamed.stream.bytesToString();
      if (streamed.statusCode >= 400) {
        throw Exception(
          'No fue posible crear la publicación (${streamed.statusCode}): $responseBody',
        );
      }
    });
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
