import 'package:flutter_test/flutter_test.dart';
import 'package:vcom_app/pages/hub/comments_by_post/comments_by_post.component.dart';

void main() {
  group('CommentsByPostComponent', () {
    late CommentsByPostComponent component;

    setUp(() {
      component = CommentsByPostComponent();
    });

    test('starts with empty comments', () {
      expect(component.commentsByPost, isEmpty);
    });

    test('isCreateInFlight is false by default', () {
      expect(component.isCreateInFlight(1), isFalse);
    });

    test('myCommentReaction returns null when no reaction exists', () {
      expect(component.myCommentReaction(1, 10), isNull);
    });

    test('clear empties the comments map', () {
      component.clear();
      expect(component.commentsByPost, isEmpty);
    });

    test('addComment rejects empty content', () async {
      final ok = await component.addComment(1, '');
      expect(ok, isFalse);
    });

    test('addComment rejects whitespace-only content', () async {
      final ok = await component.addComment(1, '   ');
      expect(ok, isFalse);
    });

    test('addComment fails gracefully without server', () async {
      final ok = await component.addComment(1, 'Hola mundo');
      expect(ok, isFalse);
    });
  });

  group('Comment listing', () {
    test('loadComments fails gracefully without server', () async {
      final component = CommentsByPostComponent();
      await component.loadComments(localId: 1, apiKey: 1);
      expect(component.commentsByPost[1], isNull);
    });
  });
}
