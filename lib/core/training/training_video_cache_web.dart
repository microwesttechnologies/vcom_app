/// En web/PWA no hay caché en disco; el reproductor usa la URL de red directamente.
class TrainingVideoCache {
  TrainingVideoCache._();

  static final TrainingVideoCache instance = TrainingVideoCache._();

  static bool isStreamUrl(String url) {
    final u = url.toLowerCase().trim();
    return u.contains('.m3u8') || u.contains('.mpd');
  }

  Future<Object?> getLocalFileIfCached(String url) async => null;

  Future<void> ensureCached(
    String url, {
    Map<String, String>? headers,
  }) async {}
}
