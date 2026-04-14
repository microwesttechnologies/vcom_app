import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vcom_app/core/hub/hub_comments.service.dart';
import 'package:vcom_app/core/hub/hub_posts.service.dart';
import 'package:vcom_app/core/models/hub_author.model.dart';
import 'package:vcom_app/core/models/hub_media.model.dart';
import 'package:vcom_app/core/models/hub_tag.model.dart';

class _FakeMultipartRequest extends http.MultipartRequest {
  _FakeMultipartRequest(
    super.method,
    super.url, {
    required this.onSend,
  });

  final Future<http.StreamedResponse> Function(http.MultipartRequest request)
  onSend;

  @override
  Future<http.StreamedResponse> send() => onSend(this);
}

void main() {
  group('Hub posts endpoints', () {
    const author = HubAuthorModel(
      id: 'u-1',
      type: 'employee',
      name: 'Tester',
      role: 'admin',
    );
    const tag = HubTagModel(id: 7, name: 'Noticias', slug: 'noticias');

    test('fetchPosts parses GET /api/v1/hub/posts response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/hub/posts');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['per_page'], '20');
        expect(request.url.queryParameters['q'], 'render');
        expect(request.url.queryParameters['tag_id'], '7');

        final body = {
          'data': [
            {
              'id': 11,
              'author': {
                'id': 'u-2',
                'type': 'model',
                'name': 'Laura',
                'role': 'modelo',
              },
              'tag': {'id': 7, 'name': 'Noticias', 'slug': 'noticias'},
              'content': 'Post backend',
              'media': const [],
              'reactions_count': 2,
              'comments_count': 1,
              'created_at': '2026-04-13T10:00:00Z',
              'reacted_by_me': false,
            },
          ],
          'meta': {'current_page': 1, 'per_page': 20, 'has_more': false},
        };
        return http.Response(jsonEncode(body), 200);
      });

      final service = HubPostsService.test(httpClient: client);
      final result = await service.fetchPosts(
        page: 1,
        perPage: 20,
        searchQuery: 'render',
        tagId: 7,
      );

      expect(result.data, hasLength(1));
      expect(result.currentPage, 1);
      expect(result.perPage, 20);
      expect(result.hasMore, isFalse);
      expect(result.data.first.id, 11);
      expect(result.data.first.content, 'Post backend');
    });

    test('fetchPosts uses local fallback when GET fails', () async {
      final service = HubPostsService.test(
        httpClient: MockClient((_) async => throw Exception('network')),
        multipartRequestFactory: (method, uri) => _FakeMultipartRequest(
          method,
          uri,
          onSend: (_) async => http.StreamedResponse(
            Stream.value(utf8.encode('{}')),
            500,
          ),
        ),
      );

      await service.createPost(
        author: author,
        tag: tag,
        content: 'Fallback local post',
        media: const [],
      );

      final result = await service.fetchPosts(page: 1, perPage: 10);
      expect(result.data, hasLength(1));
      expect(result.data.first.content, 'Fallback local post');
    });

    test('createPost parses POST /api/v1/hub/posts on 201', () async {
      http.MultipartRequest? capturedRequest;
      final service = HubPostsService.test(
        httpClient: MockClient((_) async => throw UnimplementedError()),
        multipartRequestFactory: (method, uri) => _FakeMultipartRequest(
          method,
          uri,
          onSend: (request) async {
            capturedRequest = request;
            final body = {
              'data': {
                'id': 88,
                'author': {
                  'id': 'u-1',
                  'type': 'employee',
                  'name': 'Tester',
                  'role': 'admin',
                },
                'tag': {'id': 7, 'name': 'Noticias', 'slug': 'noticias'},
                'content': 'Persistido backend',
                'media': const [],
                'reactions_count': 0,
                'comments_count': 0,
                'created_at': '2026-04-13T12:00:00Z',
                'reacted_by_me': false,
              },
            };
            return http.StreamedResponse(
              Stream.value(utf8.encode(jsonEncode(body))),
              201,
              headers: {'content-type': 'application/json'},
            );
          },
        ),
      );

      final result = await service.createPost(
        author: author,
        tag: tag,
        content: 'Persistido backend',
        media: const [
          HubMediaModel(
            id: 'remote-1',
            type: HubMediaType.image,
            url: 'https://cdn.example.com/media/image.jpg',
            sortOrder: 1,
          ),
        ],
      );

      expect(result.id, 88);
      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.path, '/api/v1/hub/posts');
      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.fields['tag_id'], '7');
      expect(capturedRequest!.fields['content'], 'Persistido backend');
      expect(capturedRequest!.fields.containsKey('media'), isTrue);
    });

    test('createPost uses local fallback on non-201', () async {
      final service = HubPostsService.test(
        httpClient: MockClient((_) async => throw UnimplementedError()),
        multipartRequestFactory: (method, uri) => _FakeMultipartRequest(
          method,
          uri,
          onSend: (_) async => http.StreamedResponse(
            Stream.value(utf8.encode('{}')),
            500,
          ),
        ),
      );

      final result = await service.createPost(
        author: author,
        tag: tag,
        content: 'Solo local',
        media: const [],
      );

      expect(result.id, greaterThanOrEqualTo(1000));
      expect(result.content, 'Solo local');
      expect(result.tag.id, 7);
    });
  });

  group('Hub comments endpoints', () {
    const author = HubAuthorModel(
      id: 'u-9',
      type: 'employee',
      name: 'Commenter',
      role: 'monitor',
    );

    test('fetchComments parses GET /api/v1/hub/posts/{id}/comments', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/v1/hub/posts/55/comments');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['per_page'], '10');

        final body = {
          'data': [
            {
              'id': 301,
              'post_id': 55,
              'author': {
                'id': 'u-2',
                'type': 'model',
                'name': 'Ana',
                'role': 'modelo',
              },
              'content': 'Comentario backend',
              'created_at': '2026-04-13T14:30:00Z',
            },
          ],
          'meta': {'current_page': 1, 'per_page': 10, 'has_more': true},
        };
        return http.Response(jsonEncode(body), 200);
      });

      final service = HubCommentsService.test(httpClient: client);
      final result = await service.fetchComments(postId: 55, page: 1, perPage: 10);

      expect(result.data, hasLength(1));
      expect(result.data.first.id, 301);
      expect(result.data.first.postId, 55);
      expect(result.hasMore, isTrue);
    });

    test('addComment parses POST /api/v1/hub/posts/{id}/comments on 201', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v1/hub/posts/55/comments');
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        expect(payload['content'], 'Texto nuevo');

        final body = {
          'data': {
            'id': 401,
            'post_id': 55,
            'author': {
              'id': 'u-9',
              'type': 'employee',
              'name': 'Commenter',
              'role': 'monitor',
            },
            'content': 'Texto nuevo',
            'created_at': '2026-04-13T15:00:00Z',
          },
        };
        return http.Response(jsonEncode(body), 201);
      });

      final service = HubCommentsService.test(httpClient: client);
      final result = await service.addComment(
        postId: 55,
        author: author,
        content: 'Texto nuevo',
      );

      expect(result.id, 401);
      expect(result.postId, 55);
      expect(result.content, 'Texto nuevo');
    });

    test('addComment uses local fallback when POST fails', () async {
      final service = HubCommentsService.test(
        httpClient: MockClient((_) async => throw Exception('network')),
      );

      final result = await service.addComment(
        postId: 77,
        author: author,
        content: '  fallback comment  ',
      );

      expect(result.id, greaterThanOrEqualTo(5000));
      expect(result.postId, 77);
      expect(result.content, 'fallback comment');
    });
  });
}
