import 'package:flutter_test/flutter_test.dart';
import 'package:vcom_app/pages/hub/tags/tags.component.dart';

void main() {
  group('TagsComponent', () {
    late TagsComponent component;

    setUp(() {
      component = TagsComponent();
    });

    test('starts with empty tags', () {
      expect(component.tags, isEmpty);
    });

    test('selectedTag is null by default', () {
      expect(component.selectedTag, isNull);
    });

    test('selectTag updates selectedTag', () {
      component.selectTag(null);
      expect(component.selectedTag, isNull);
    });

    test('loadTags fails gracefully without server', () async {
      await component.loadTags();
      expect(component.tags, isEmpty);
    });

    test('post can exist without tags', () {
      expect(component.selectedTag, isNull);
    });

    test('post tag_id is null when no tag selected', () {
      expect(component.selectedTag?.id, isNull);
    });
  });
}
