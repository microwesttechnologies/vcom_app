import 'package:flutter_test/flutter_test.dart';
import 'package:vcom_app/pages/hub/post/post.component.dart';

void main() {
  group('PostComponent', () {
    test('extractLocalPostId returns int from int id', () {
      final post = {'id': 42};
      expect(PostComponent.extractLocalPostId(post), 42);
    });

    test('extractLocalPostId returns int from string id', () {
      final post = {'id': '99'};
      expect(PostComponent.extractLocalPostId(post), 99);
    });

    test('extractLocalPostId returns null when no id present', () {
      final post = <String, dynamic>{};
      expect(PostComponent.extractLocalPostId(post), isNull);
    });

    test('extractLocalPostId prefers id over id_post', () {
      final post = {'id': 1, 'id_post': 2};
      expect(PostComponent.extractLocalPostId(post), 1);
    });

    test('resolvePostApiKey returns id_post if present', () {
      final post = {'id': 1, 'id_post': 'abc-uuid'};
      expect(PostComponent.resolvePostApiKey(1, post), 'abc-uuid');
    });

    test('resolvePostApiKey falls back to localId', () {
      final post = <String, dynamic>{'id': 5};
      expect(PostComponent.resolvePostApiKey(5, post), 5);
    });

    test('createPost requires title and content', () async {
      final component = PostComponent();
      final ok = await component.createPost(
        title: '',
        content: 'test content',
      );
      expect(component, isNotNull);
      expect(ok, isFalse);
    });
  });

  group('Post listing', () {
    test('PostComponent starts with empty posts', () {
      final component = PostComponent();
      expect(component.posts, isEmpty);
      expect(component.isLoading, isFalse);
      expect(component.error, isNull);
    });

    test('configure sets page and perPage', () {
      final component = PostComponent();
      component.configure(page: 3, perPage: 25);
      expect(component.page, 3);
      expect(component.perPage, 25);
    });
  });

  group('Post creation without tags', () {
    test('createPost accepts null tagId', () async {
      final component = PostComponent();
      final ok = await component.createPost(
        title: 'Sin tag',
        content: 'Post sin tag',
        tagId: null,
      );
      expect(ok, isFalse);
      expect(component.error, isNotNull);
    });
  });
}
