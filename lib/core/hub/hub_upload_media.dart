import 'dart:typed_data';

/// Archivo listo para multipart (web y nativo).
class HubUploadMedia {
  const HubUploadMedia({
    required this.bytes,
    required this.filename,
    required this.mimeType,
    required this.type,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;

  /// `image` | `video`
  final String type;

  static String guessMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }

  static String resolveFilename(String name, {required String type}) {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) return trimmed;
    final ts = DateTime.now().millisecondsSinceEpoch;
    return type == 'video' ? 'video_$ts.mp4' : 'image_$ts.jpg';
  }
}
