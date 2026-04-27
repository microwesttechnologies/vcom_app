import 'package:flutter_test/flutter_test.dart';
import 'package:vcom_app/pages/hub/reactions_by_comment/reactions_by_comment.component.dart';

void main() {
  group('ReactionsByCommentComponent', () {
    late ReactionsByCommentComponent component;

    setUp(() {
      component = ReactionsByCommentComponent();
    });

    test('myReaction returns null when not reacted', () {
      expect(component.myReaction(1, 10), isNull);
    });

    test('isInFlight returns false by default', () {
      expect(component.isInFlight(1, 10), isFalse);
    });

    test('react rejects null commentId', () async {
      final ok = await component.react(
        localId: 1,
        commentId: null,
        type: 'like',
        apiKey: 1,
        commentsByPost: {},
      );
      expect(ok, isFalse);
    });

    test('react rejects zero commentId', () async {
      final ok = await component.react(
        localId: 1,
        commentId: 0,
        type: 'like',
        apiKey: 1,
        commentsByPost: {},
      );
      expect(ok, isFalse);
    });

    test('react rejects negative commentId', () async {
      final ok = await component.react(
        localId: 1,
        commentId: -5,
        type: 'like',
        apiKey: 1,
        commentsByPost: {},
      );
      expect(ok, isFalse);
    });

    test('react rejects empty string commentId', () async {
      final ok = await component.react(
        localId: 1,
        commentId: '',
        type: 'like',
        apiKey: 1,
        commentsByPost: {},
      );
      expect(ok, isFalse);
    });

    test('react fails gracefully without server', () async {
      final ok = await component.react(
        localId: 1,
        commentId: 10,
        type: 'love',
        apiKey: 1,
        commentsByPost: {},
      );
      expect(ok, isFalse);
    });

    test('react rolls back on failure', () async {
      await component.react(
        localId: 1,
        commentId: 10,
        type: 'wow',
        apiKey: 1,
        commentsByPost: {},
      );
      expect(component.myReaction(1, 10), isNull);
    });
  });
}
