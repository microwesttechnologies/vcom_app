/// Constantes del módulo Hub.
class HubConstants {
  HubConstants._();

  static const int maxImagesPerPost = 4;
  static const int maxVideosPerPost = 2;
  static const int maxVideoDurationSeconds = 60;
  static const int mediaCompressionQuality = 70;
  static const int defaultPage = 1;
  static const int defaultPerPage = 15;

  /// Peso máximo por video en app nativa (500 MB).
  static const int maxVideoSizeBytes = 500 * 1024 * 1024;

  /// En web/PWA el navegador no puede comprimir; se limita a 100 MB
  /// para que la subida sea tolerable sin compresión previa.
  static const int maxWebVideoSizeBytes = 100 * 1024 * 1024;

  /// Todo video se comprime antes de subir (umbral: 1 byte = siempre).
  static const int videoCompressionThresholdBytes = 1;

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
