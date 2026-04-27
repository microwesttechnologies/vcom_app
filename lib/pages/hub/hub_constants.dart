/// Constantes del módulo Hub.
class HubConstants {
  HubConstants._();

  static const int maxImagesPerPost = 4;
  static const int maxVideosPerPost = 2;
  static const int maxVideoDurationSeconds = 60;
  static const int mediaCompressionQuality = 70;
  static const int defaultPage = 1;
  static const int defaultPerPage = 15;

  /// Tiempo máximo de caché antes de refrescar automáticamente.
  static const Duration cacheTtl = Duration(minutes: 5);

  static const List<List<String>> reactionOptions = [
    ['\u{1F44D}', 'like'],
    ['\u{2764}\u{FE0F}', 'love'],
    ['\u{1F602}', 'haha'],
    ['\u{1F62E}', 'wow'],
    ['\u{1F622}', 'sad'],
  ];
}
