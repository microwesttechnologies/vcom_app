import 'package:flutter_test/flutter_test.dart';
import 'package:vcom_app/pages/hub/multimedia_by_post/multimedia_by_post.component.dart';

void main() {
  group('MultimediaByPostComponent', () {
    late MultimediaByPostComponent validator;

    setUp(() {
      validator = MultimediaByPostComponent();
    });

    test('empty media list is valid', () {
      expect(validator.validateMedia([]), isNull);
    });

    test('4 images is valid', () {
      final media = List.generate(
        4,
        (i) => {'type': 'image', 'url': 'img$i.jpg', 'mime_type': 'image/jpeg'},
      );
      expect(validator.validateMedia(media), isNull);
    });

    test('5 images is invalid', () {
      final media = List.generate(
        5,
        (i) => {'type': 'image', 'url': 'img$i.jpg', 'mime_type': 'image/jpeg'},
      );
      expect(validator.validateMedia(media), contains('4'));
    });

    test('2 videos is valid', () {
      final media = List.generate(
        2,
        (i) => {
          'type': 'video',
          'url': 'vid$i.mp4',
          'mime_type': 'video/mp4',
          'duration': 30,
        },
      );
      expect(validator.validateMedia(media), isNull);
    });

    test('3 videos is invalid', () {
      final media = List.generate(
        3,
        (i) => {
          'type': 'video',
          'url': 'vid$i.mp4',
          'mime_type': 'video/mp4',
          'duration': 30,
        },
      );
      expect(validator.validateMedia(media), contains('2'));
    });

    test('video longer than 60 seconds is invalid', () {
      final media = [
        {
          'type': 'video',
          'url': 'long.mp4',
          'mime_type': 'video/mp4',
          'duration': 90,
        },
      ];
      expect(validator.validateMedia(media), contains('60'));
    });

    test('video exactly 60 seconds is valid', () {
      final media = [
        {
          'type': 'video',
          'url': 'ok.mp4',
          'mime_type': 'video/mp4',
          'duration': 60,
        },
      ];
      expect(validator.validateMedia(media), isNull);
    });

    test('video without duration is valid', () {
      final media = [
        {
          'type': 'video',
          'url': 'no_dur.mp4',
          'mime_type': 'video/mp4',
        },
      ];
      expect(validator.validateMedia(media), isNull);
    });

    test('compressionQuality is 70', () {
      expect(validator.compressionQuality, 70);
    });

    test('mixed images and videos within limits is valid', () {
      final media = [
        {'type': 'image', 'url': 'a.jpg', 'mime_type': 'image/jpeg'},
        {'type': 'image', 'url': 'b.jpg', 'mime_type': 'image/jpeg'},
        {'type': 'video', 'url': 'c.mp4', 'mime_type': 'video/mp4', 'duration': 45},
      ];
      expect(validator.validateMedia(media), isNull);
    });

    test('mime_type detection for images', () {
      final media = [
        {'type': '', 'url': 'a.jpg', 'mime_type': 'image/png'},
      ];
      expect(validator.validateMedia(media), isNull);
    });

    test('mime_type detection for videos', () {
      final media = [
        {'type': '', 'url': 'a.mp4', 'mime_type': 'video/mp4', 'duration': 10},
      ];
      expect(validator.validateMedia(media), isNull);
    });

    test('duration as string is parsed', () {
      final media = [
        {
          'type': 'video',
          'url': 'str.mp4',
          'mime_type': 'video/mp4',
          'duration': '90',
        },
      ];
      expect(validator.validateMedia(media), contains('60'));
    });
  });
}
