import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/hub_author.model.dart';
import 'package:vcom_app/core/models/hub_media.model.dart';
import 'package:vcom_app/core/models/hub_post.model.dart';
import 'package:vcom_app/core/models/hub_tag.model.dart';

class HubPostsService {
  static final HubPostsService _instance = HubPostsService._internal();
  factory HubPostsService() => _instance;
  HubPostsService._internal();

  final Random _random = Random();
  final TokenService _tokenService = TokenService();

  void _log(String message) {
    debugPrint('[HubPostsService] $message');
  }

  int _nextPostId = 1000;
  List<HubPostModel> _posts = [
    HubPostModel(
      id: 101,
      author: const HubAuthorModel(
        id: 'u-10',
        type: 'model',
        name: 'Laura M',
        role: 'modelo',
      ),
      tag: const HubTagModel(id: 1, name: 'Vivir bien', slug: 'vivir-bien'),
      content:
          'Alguien vio al director creativo saliendo con los nuevos renders exclusivos? '
          'Parece que se viene un lanzamiento fuerte para esta temporada.',
      media: const [],
      reactionsCount: 428,
      commentsCount: 56,
      createdAt: DateTime(2026, 4, 13, 9, 20),
      reactedByMe: false,
    ),
    HubPostModel(
      id: 102,
      author: const HubAuthorModel(
        id: 'u-11',
        type: 'employee',
        name: 'Equipo Creativo',
        role: 'monitor',
      ),
      tag: const HubTagModel(id: 3, name: 'Moda', slug: 'moda'),
      content:
          'Preview del set de producto para esta tarde. '
          'Nos quedamos con la composicion oscura y acento dorado.',
      media: const [
        HubMediaModel(
          id: 'm-102-1',
          type: HubMediaType.image,
          url:
              'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=1200&q=80',
          sortOrder: 1,
        ),
      ],
      reactionsCount: 179,
      commentsCount: 21,
      createdAt: DateTime(2026, 4, 12, 20, 45),
      reactedByMe: true,
    ),
    HubPostModel(
      id: 103,
      author: const HubAuthorModel(
        id: 'u-12',
        type: 'employee',
        name: 'Coordinacion',
        role: 'admin',
      ),
      tag: const HubTagModel(id: 2, name: 'Personal', slug: 'personal'),
      content:
          'Recordatorio: manana cerramos convocatoria para contenido de bienvenida. '
          'Suban propuestas antes de las 6PM.',
      media: const [
        HubMediaModel(
          id: 'm-103-1',
          type: HubMediaType.image,
          url:
              'https://images.unsplash.com/photo-1520607162513-77705c0f0d4a?auto=format&fit=crop&w=1200&q=80',
          sortOrder: 1,
        ),
        HubMediaModel(
          id: 'm-103-2',
          type: HubMediaType.image,
          url:
              'https://images.unsplash.com/photo-1478145046317-39f10e56b5e9?auto=format&fit=crop&w=1200&q=80',
          sortOrder: 2,
        ),
      ],
      reactionsCount: 94,
      commentsCount: 13,
      createdAt: DateTime(2026, 4, 12, 11, 10),
      reactedByMe: false,
    ),
  ];

  Future<HubPostPageResult> fetchPosts({
    required int page,
    required int perPage,
    String searchQuery = '',
    int? tagId,
  }) async {
    final queryParameters = <String, String>{
      'page': '$page',
      'per_page': '$perPage',
    };
    if (searchQuery.trim().isNotEmpty) {
      queryParameters['q'] = searchQuery.trim();
    }
    if (tagId != null) {
      queryParameters['tag_id'] = '$tagId';
    }

    final uri = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.hubPosts}')
        .replace(queryParameters: queryParameters);
    _log(
      'fetchPosts -> GET $uri | page=$page perPage=$perPage tagId=${tagId ?? 'null'} q="${searchQuery.trim()}"',
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ..._tokenService.getAuthHeaders(),
            },
          )
          .timeout(const Duration(seconds: 12));
      _log(
        'fetchPosts <- status=${response.statusCode} bodyLength=${response.body.length}',
      );

      _tokenService.handleUnauthorizedStatus(response.statusCode);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawData = body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? const <dynamic>[])
            : const <dynamic>[];
        final parsedPosts = rawData
            .whereType<Map<String, dynamic>>()
            .map(HubPostModel.fromJson)
            .toList(growable: false);

        final meta = body is Map<String, dynamic>
            ? (body['meta'] as Map<String, dynamic>? ?? const {})
            : const <String, dynamic>{};
        final currentPage = (meta['current_page'] as num?)?.toInt() ?? page;
        final currentPerPage = (meta['per_page'] as num?)?.toInt() ?? perPage;
        final hasMore = meta['has_more'] as bool? ?? false;
        _log(
          'fetchPosts parsed -> posts=${parsedPosts.length} currentPage=$currentPage hasMore=$hasMore',
        );

        _syncLocalCache(page: page, incoming: parsedPosts);

        return HubPostPageResult(
          data: parsedPosts,
          currentPage: currentPage,
          perPage: currentPerPage,
          hasMore: hasMore,
        );
      }
    } catch (e) {
      _log('fetchPosts error -> $e');
    }

    _log('fetchPosts -> using fallback local cache');

    return _fetchPostsFallback(
      page: page,
      perPage: perPage,
      searchQuery: searchQuery,
      tagId: tagId,
    );
  }

  HubPostPageResult _fetchPostsFallback({
    required int page,
    required int perPage,
    String searchQuery = '',
    int? tagId,
  }) {
    _log(
      '_fetchPostsFallback -> page=$page perPage=$perPage tagId=${tagId ?? 'null'} q="${searchQuery.trim()}" cacheSize=${_posts.length}',
    );
    final normalizedSearch = searchQuery.trim().toLowerCase();

    final filtered = _posts
        .where((post) {
          final matchTag = tagId == null || post.tag.id == tagId;
          if (!matchTag) return false;

          if (normalizedSearch.isEmpty) return true;

          final content = post.content.toLowerCase();
          final author = post.author.name.toLowerCase();
          final tagName = post.tag.name.toLowerCase();
          return content.contains(normalizedSearch) ||
              author.contains(normalizedSearch) ||
              tagName.contains(normalizedSearch);
        })
        .toList(growable: false)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final start = (page - 1) * perPage;
    if (start >= filtered.length) {
      _log('_fetchPostsFallback result -> empty page (filtered=${filtered.length})');
      return HubPostPageResult(
        data: const [],
        currentPage: page,
        perPage: perPage,
        hasMore: false,
      );
    }

    final end = min(start + perPage, filtered.length);
    final data = filtered.sublist(start, end);
    _log(
      '_fetchPostsFallback result -> returned=${data.length} filtered=${filtered.length} hasMore=${end < filtered.length}',
    );
    return HubPostPageResult(
      data: data,
      currentPage: page,
      perPage: perPage,
      hasMore: end < filtered.length,
    );
  }

  Future<HubPostModel> toggleReaction({required int postId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index < 0) {
      throw StateError('Post no encontrado');
    }

    final current = _posts[index];
    final reacted = !current.reactedByMe;
    final nextCount = reacted
        ? current.reactionsCount + 1
        : (current.reactionsCount > 0 ? current.reactionsCount - 1 : 0);
    final updated = current.copyWith(
      reactedByMe: reacted,
      reactionsCount: nextCount,
    );
    _posts[index] = updated;
    return updated;
  }

  Future<HubPostModel> createPost({
    required HubAuthorModel author,
    required HubTagModel tag,
    required String content,
    required List<HubMediaModel> media,
  }) async {
    final uri = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostsCreate}');
    _log(
      'createPost -> POST $uri | tag=${tag.id} contentLen=${content.trim().length} media=${media.length}',
    );
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll({
      'Accept': 'application/json',
      ..._tokenService.getAuthHeaders(),
    });

    request.fields['tag_id'] = '${tag.id}';
    final normalizedContent = content.trim();
    if (normalizedContent.isNotEmpty) {
      request.fields['content'] = normalizedContent;
    }

    final remoteMediaPayload = <Map<String, dynamic>>[];
    for (final item in media) {
      if (item.isLocal) {
        final file = File(item.url);
        if (!file.existsSync()) {
          _log('createPost media skip -> local file not found: ${item.url}');
          continue;
        }
        request.files.add(
          await http.MultipartFile.fromPath('media_files[]', item.url),
        );
      } else {
        remoteMediaPayload.add({
          'type': item.type.name,
          'file_url': item.url,
          'thumbnail_url': item.thumbnailUrl,
          'mime_type': item.mimeType,
          'file_size': item.fileSize,
          'sort_order': item.sortOrder,
        });
      }
    }

    if (remoteMediaPayload.isNotEmpty) {
      request.fields['media'] = jsonEncode(remoteMediaPayload);
    }
    _log(
      'createPost payload -> fields=${request.fields.keys.toList()} files=${request.files.length} remoteMedia=${remoteMediaPayload.length}',
    );

    try {
      final streamed = await request.send().timeout(const Duration(seconds: 20));
      final response = await http.Response.fromStream(streamed);
      _log(
        'createPost <- status=${response.statusCode} bodyLength=${response.body.length}',
      );
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final raw = body is Map<String, dynamic>
            ? (body['data'] as Map<String, dynamic>? ?? const {})
            : const <String, dynamic>{};

        final created = HubPostModel.fromJson(raw);
        _posts.insert(0, created);
        _log('createPost success -> createdId=${created.id} cacheSize=${_posts.length}');
        return created;
      }
      _log('createPost non-201 response -> fallback local');
    } catch (e) {
      _log('createPost error -> $e');
    }

    // Fallback local si el backend no está disponible.
    _log('createPost -> using fallback local post');
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final now = DateTime.now();
    final sortedMedia = [...media]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    final post = HubPostModel(
      id: _nextPostId++,
      author: author,
      tag: tag,
      content: content,
      media: sortedMedia,
      reactionsCount: _random.nextInt(9),
      commentsCount: 0,
      createdAt: now,
      reactedByMe: false,
    );
    _posts.insert(0, post);
    _log('createPost fallback success -> createdId=${post.id} cacheSize=${_posts.length}');
    return post;
  }

  void incrementCommentsCount(int postId) {
    final index = _posts.indexWhere((post) => post.id == postId);
    if (index < 0) return;

    final current = _posts[index];
    _posts[index] = current.copyWith(commentsCount: current.commentsCount + 1);
  }

  void _syncLocalCache({required int page, required List<HubPostModel> incoming}) {
    if (page <= 1) {
      _posts = [...incoming];
      _log('_syncLocalCache reset -> cacheSize=${_posts.length}');
      return;
    }

    final merged = [..._posts];
    for (final post in incoming) {
      final index = merged.indexWhere((existing) => existing.id == post.id);
      if (index >= 0) {
        merged[index] = post;
      } else {
        merged.add(post);
      }
    }
    merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _posts = merged;
    _log('_syncLocalCache merge -> incoming=${incoming.length} cacheSize=${_posts.length} page=$page');
  }
}
