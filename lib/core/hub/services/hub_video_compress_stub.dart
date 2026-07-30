import 'dart:typed_data';

/// Resultado de compresión de video Hub.
class HubCompressedVideo {
  const HubCompressedVideo({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;
}

/// Stub web/PWA: no comprime; devuelve el original.
Future<HubCompressedVideo> compressHubVideo({
  required Uint8List bytes,
  required String filename,
  String? sourcePath,
}) async {
  return HubCompressedVideo(bytes: bytes, filename: filename);
}
