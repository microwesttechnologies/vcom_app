import 'package:vcom_app/pages/hub/hub_constants.dart';

/// Lógica de validación y compresión de multimedia para posts.
class MultimediaByPostComponent {
  /// Valida la lista de medios. Retorna un mensaje de error o `null` si es
  /// válido.
  String? validateMedia(List<Map<String, dynamic>> media) {
    if (media.isEmpty) return null;

    final images = media.where((m) => _isImage(m)).toList();
    final videos = media.where((m) => _isVideo(m)).toList();

    if (images.length > HubConstants.maxImagesPerPost) {
      return 'Máximo ${HubConstants.maxImagesPerPost} imágenes por post';
    }

    if (videos.length > HubConstants.maxVideosPerPost) {
      return 'Máximo ${HubConstants.maxVideosPerPost} videos por post';
    }

    for (final video in videos) {
      final duration = _extractDurationSeconds(video);
      if (duration != null &&
          duration > HubConstants.maxVideoDurationSeconds) {
        return 'Cada video debe durar máximo '
            '${HubConstants.maxVideoDurationSeconds} segundos';
      }
    }

    return null;
  }

  /// Calidad objetivo para compresión (0–100).
  int get compressionQuality => HubConstants.mediaCompressionQuality;

  bool _isImage(Map<String, dynamic> m) {
    final type = (m['type'] ?? '').toString().toLowerCase();
    final mime = (m['mime_type'] ?? '').toString().toLowerCase();
    return type == 'image' || mime.startsWith('image/');
  }

  bool _isVideo(Map<String, dynamic> m) {
    final type = (m['type'] ?? '').toString().toLowerCase();
    final mime = (m['mime_type'] ?? '').toString().toLowerCase();
    return type == 'video' || mime.startsWith('video/');
  }

  int? _extractDurationSeconds(Map<String, dynamic> m) {
    final raw = m['duration'] ?? m['duration_seconds'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}
