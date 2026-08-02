/// Constantes del módulo Hub.
class HubConstants {
  HubConstants._();

  static const int maxImagesPerPost = 4;
  static const int maxVideosPerPost = 2;
  static const int maxVideoDurationSeconds = 60;
  static const int mediaCompressionQuality = 70;
  static const int defaultPage = 1;
  static const int defaultPerPage = 15;

  /// Peso máximo final por video (100 MB) — después de compresión.
  static const int maxVideoSizeBytes = 100 * 1024 * 1024;

  /// Peso máximo al seleccionar (200 MB) — se comprime antes de subir.
  static const int maxVideoPickSizeBytes = 200 * 1024 * 1024;

  /// Alias para PWA — mismo límite de selección.
  static const int maxWebVideoSizeBytes = maxVideoPickSizeBytes;

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
