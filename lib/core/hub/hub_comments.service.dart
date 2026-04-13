import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/hub_author.model.dart';
import 'package:vcom_app/core/models/hub_comment.model.dart';

class HubCommentPageResult {
  final List<HubCommentModel> data;
  final int currentPage;
  final int perPage;
  final bool hasMore;

  const HubCommentPageResult({
    required this.data,
    required this.currentPage,
    required this.perPage,
    required this.hasMore,
  });
}

class HubCommentsService {
  static final HubCommentsService _instance = HubCommentsService._internal();
  factory HubCommentsService() => _instance;
  HubCommentsService._internal();

  final Random _random = Random();
  final TokenService _tokenService = TokenService();
  int _nextCommentId = 5000;

  final Map<int, List<HubCommentModel>> _commentsByPostId = {
    101: [
      HubCommentModel(
        id: 2001,
        postId: 101,
        author: const HubAuthorModel(
          id: 'u-31',
          type: 'model',
          name: 'Ana C',
          role: 'modelo',
        ),
        content: 'Yo tambien lo vi. Parece que van con una linea premium.',
        createdAt: DateTime(2026, 4, 13, 9, 45),
      ),
      HubCommentModel(
        id: 2002,
        postId: 101,
        author: const HubAuthorModel(
          id: 'u-32',
          type: 'employee',
          name: 'Diego R',
          role: 'monitor',
        ),
        content: 'Confirmado. La presentacion interna es esta semana.',
        createdAt: DateTime(2026, 4, 13, 10, 3),
      ),
    ],
    102: [
      HubCommentModel(
        id: 2010,
        postId: 102,
        author: const HubAuthorModel(
          id: 'u-33',
          type: 'employee',
          name: 'Sofia V',
          role: 'monitor',
        ),
        content: 'La luz lateral quedo increible en esta toma.',
        createdAt: DateTime(2026, 4, 12, 21, 4),
      ),
    ],
  };

  Future<HubCommentPageResult> fetchComments({
    required int postId,
    required int page,
    required int perPage,
  }) async {
    final uri = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostComments(postId)}',
    ).replace(queryParameters: {'page': '$page', 'per_page': '$perPage'});

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

      _tokenService.handleUnauthorizedStatus(response.statusCode);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final rawData = body is Map<String, dynamic>
            ? (body['data'] as List<dynamic>? ?? const <dynamic>[])
            : const <dynamic>[];

        final comments = rawData
            .whereType<Map<String, dynamic>>()
            .map(HubCommentModel.fromJson)
            .toList(growable: false);

        final meta = body is Map<String, dynamic>
            ? (body['meta'] as Map<String, dynamic>? ?? const {})
            : const <String, dynamic>{};

        final currentPage = (meta['current_page'] as num?)?.toInt() ?? page;
        final currentPerPage = (meta['per_page'] as num?)?.toInt() ?? perPage;
        final hasMore = meta['has_more'] as bool? ?? false;

        _syncLocalComments(postId: postId, incoming: comments);

        return HubCommentPageResult(
          data: comments,
          currentPage: currentPage,
          perPage: currentPerPage,
          hasMore: hasMore,
        );
      }
    } catch (_) {}

    await Future<void>.delayed(const Duration(milliseconds: 180));
    final all = [...(_commentsByPostId[postId] ?? const <HubCommentModel>[])]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final start = (page - 1) * perPage;
    if (start >= all.length) {
      return HubCommentPageResult(
        data: const [],
        currentPage: page,
        perPage: perPage,
        hasMore: false,
      );
    }

    final end = min(start + perPage, all.length);
    return HubCommentPageResult(
      data: all.sublist(start, end),
      currentPage: page,
      perPage: perPage,
      hasMore: end < all.length,
    );
  }

  Future<HubCommentModel> addComment({
    required int postId,
    required HubAuthorModel author,
    required String content,
  }) async {
    final normalizedContent = content.trim();
    final uri = Uri.parse(
      '${EnvironmentDev.baseUrl}${EnvironmentDev.hubPostComments(postId)}',
    );

    try {
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              ..._tokenService.getAuthHeaders(),
            },
            body: jsonEncode({'content': normalizedContent}),
          )
          .timeout(const Duration(seconds: 12));

      _tokenService.handleUnauthorizedStatus(response.statusCode);
      if (response.statusCode == 201) {
        final body = jsonDecode(response.body);
        final raw = body is Map<String, dynamic>
            ? (body['data'] as Map<String, dynamic>? ?? const {})
            : const <String, dynamic>{};
        final created = HubCommentModel.fromJson(raw);
        final comments = _commentsByPostId.putIfAbsent(
          postId,
          () => <HubCommentModel>[],
        );
        comments.add(created);
        comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return created;
      }
    } catch (_) {}

    await Future<void>.delayed(const Duration(milliseconds: 120));
    final created = HubCommentModel(
      id: _nextCommentId++,
      postId: postId,
      author: author,
      content: normalizedContent,
      createdAt: DateTime.now().subtract(Duration(seconds: _random.nextInt(5))),
    );

    final comments = _commentsByPostId.putIfAbsent(
      postId,
      () => <HubCommentModel>[],
    );
    comments.add(created);
    return created;
  }

  void _syncLocalComments({
    required int postId,
    required List<HubCommentModel> incoming,
  }) {
    final merged = [
      ...(_commentsByPostId[postId] ?? const <HubCommentModel>[]),
    ];
    for (final comment in incoming) {
      final index = merged.indexWhere((existing) => existing.id == comment.id);
      if (index >= 0) {
        merged[index] = comment;
      } else {
        merged.add(comment);
      }
    }
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _commentsByPostId[postId] = merged;
  }
}
