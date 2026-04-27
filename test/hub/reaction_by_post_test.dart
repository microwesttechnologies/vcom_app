import 'package:flutter_test/flutter_test.dart';
import 'package:vcom_app/pages/hub/reaction_by_post/reaction_by_post.component.dart';

void main() {
  group('ReactionByPostComponent', () {
    late ReactionByPostComponent component;

    setUp(() {
      component = ReactionByPostComponent();
    });

    test('starts with no reactions', () {
      expect(component.reactionsByPost, isEmpty);
    });

    test('myReaction returns null when not reacted', () {
      expect(component.myReaction(1), isNull);
    });

    test('isInFlight returns false by default', () {
      expect(component.isInFlight(1), isFalse);
    });

    test('formatCount returns 0 for unknown post', () {
      expect(component.formatCount(999), '0');
    });

    test('clear empties the reactions map', () {
      component.clear();
      expect(component.reactionsByPost, isEmpty);
    });

    test('react fails gracefully without server', () async {
      final ok = await component.react(1, 'like', 1);
      expect(ok, isFalse);
    });

    test('react rolls back on failure', () async {
      final ok = await component.react(1, 'love', 1);
      expect(ok, isFalse);
      expect(component.myReaction(1), isNull);
    });
  });
}
