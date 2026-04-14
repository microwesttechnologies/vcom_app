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

typedef HubMultipartRequestFactory =
    http.MultipartRequest Function(String method, Uri uri);

class HubPostsService {
  static final HubPostsService _instance = HubPostsService._internal();
  factory HubPostsService() => _instance;
  HubPostsService._internal({
    Random? random,
    TokenService? tokenService,
    http.Client? httpClient,
    HubMultipartRequestFactory? multipartRequestFactory,
  }) : _random = random ?? Random(),
       _tokenService = tokenService ?? TokenService(),
       _httpClient = httpClient ?? http.Client(),
       _multipartRequestFactory =
           multipartRequestFactory ??
           ((method, uri) => http.MultipartRequest(method, uri));

  @visibleForTesting
  HubPostsService.test({
    Random? random,
    TokenService? tokenService,
    http.Client? httpClient,
    HubMultipartRequestFactory? multipartRequestFactory,
  }) : _random = random ?? Random(),
       _tokenService = tokenService ?? TokenService(),
       _httpClient = httpClient ?? http.Client(),
       _multipartRequestFactory =
           multipartRequestFactory ??
           ((method, uri) => http.MultipartRequest(method, uri));

  final Random _random;
  final TokenService _tokenService;
  final http.Client _httpClient;
  final HubMultipartRequestFactory _multipartRequestFactory;

  void _log(String message) {
    debugPrint('[HubPostsService] $message');
  }

  int _nextPostId = 1000;
  List<HubPostModel> _posts = [];

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
      final response = await _httpClient
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
    final request = _multipartRequestFactory('POST', uri);
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
