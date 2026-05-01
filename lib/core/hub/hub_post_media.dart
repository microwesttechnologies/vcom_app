import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';

/// Tipo de recurso en la galería del post.
enum HubMediaKind { image, video }

/// Un archivo de imagen o vídeo asociado al post.
class HubPostMediaItem {
  const HubPostMediaItem({required this.url, required this.kind});

  final String url;
  final HubMediaKind kind;
}

bool hubMediaUrlLooksLikeVideo(String raw) {
  final path = raw.split('?').first.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      path.endsWith('.webm') ||
      path.endsWith('.m4v') ||
      path.endsWith('.avi') ||
      path.endsWith('.mkv');
}

HubMediaKind? _kindFromMediaMap(Map<String, dynamic> m) {
  final t = (m['mime_type'] ??
          m['mimeType'] ??
          m['type'] ??
          m['media_type'] ??
          '')
      .toString()
      .toLowerCase();
  if (t.contains('video')) return HubMediaKind.video;
  if (t.contains('image')) return HubMediaKind.image;
  final url = _firstUrlFromMediaMap(m);
  if (url != null && hubMediaUrlLooksLikeVideo(url)) {
    return HubMediaKind.video;
  }
  return null;
}

void _hubCollectMediaFromDynamic(
  dynamic value,
  void Function(String? url, HubMediaKind? hint) add,
) {
  if (value == null) return;
  if (value is String) {
    add(value, null);
    return;
  }
  if (value is List) {
    _hubCollectMediaFromList(value, add);
    return;
  }
  if (value is Map<String, dynamic>) {
    final inner =
        value['data'] ?? value['items'] ?? value['records'] ?? value['rows'];
    if (inner is List) {
      _hubCollectMediaFromList(inner, add);
      return;
    }
    final hint = _kindFromMediaMap(value);
    add(_firstUrlFromMediaMap(value), hint);
    final rel = value['media'] ?? value['file'] ?? value['attachment'];
    _hubCollectMediaFromDynamic(rel, add);
  }
}

void _hubCollectMediaFromList(
  List<dynamic> list,
  void Function(String? url, HubMediaKind? hint) add,
) {
  for (final e in list) {
    if (e is String) {
      add(e, null);
    } else if (e is Map<String, dynamic>) {
      final hint = _kindFromMediaMap(e);
      add(_firstUrlFromMediaMap(e), hint);
      final rel = e['media'] ?? e['file'] ?? e['attachment'];
      _hubCollectMediaFromDynamic(rel, add);
    }
  }
}

/// Imágenes y vídeos del post con tipo inferido (mime, extensión).
List<HubPostMediaItem> extractPostMediaItems(Map<String, dynamic> post) {
  final root = _effectivePostRoot(post);
  const listKeys = [
    'images',
    'media',
    'photos',
    'attachments',
    'files',
    'medias',
    'gallery',
    'post_media',
    'post_medias',
    'postMedia',
    'postMedias',
    'hub_post_media',
    'hubPostMedia',
    'hub_medias',
    'hubMedias',
  ];
  final items = <HubPostMediaItem>[];
  final seen = <String>{};

  void addResolved(String? s, HubMediaKind? hint) {
    if (s == null) return;
    final u = resolveHubMediaUrl(s.trim());
    if (u.isEmpty || u.startsWith('data:')) return;
    var kind = hint ?? HubMediaKind.image;
    if (hubMediaUrlLooksLikeVideo(u)) kind = HubMediaKind.video;
    if (seen.contains(u)) return;
    seen.add(u);
    items.add(HubPostMediaItem(url: u, kind: kind));
  }

  for (final key in listKeys) {
    _hubCollectMediaFromDynamic(root[key], addResolved);
  }

  if (items.isEmpty) {
    const coverKeys = [
      'cover',
      'image',
      'picture',
      'cover_url',
      'coverUrl',
      'featured_image',
      'featuredImage',
      'image_url',
      'imageUrl',
      'image_path',
      'imagePath',
      'photo',
      'photo_url',
      'photoUrl',
      'thumb_url',
      'thumbUrl',
      'thumbnail',
      'banner',
      'banner_url',
      'url_source',
      'urlSource',
    ];
    for (final key in coverKeys) {
      final v = root[key];
      if (v is String && v.trim().isNotEmpty) {
        addResolved(v, HubMediaKind.image);
        break;
      }
    }
  }

  return items;
}

/// Cabeceras HTTP para [VideoPlayerController] en URLs del Hub.
Map<String, String> hubVideoRequestHeadersForUrl(
  String url,
  TokenService tokenService,
) {
  final lower = url.toLowerCase();
  if (lower.contains('/api/v1/storage/')) {
    return {
      'Accept': 'video/*,*/*;q=0.8',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }
  return {
    'Accept': 'video/*,*/*;q=0.8',
    'X-Requested-With': 'XMLHttpRequest',
    ...tokenService.getAuthHeaders(),
  };
}

/// Convierte rutas relativas del API en URL absoluta para [Image.network].
String resolveHubMediaUrl(String raw) {
  var s = raw.trim();
  if (s.isEmpty) return s;
  if (s.startsWith('data:')) {
    return s;
  }
  if (s.startsWith('//')) {
    return 'https:$s';
  }
  if (s.startsWith('http://') || s.startsWith('https://')) {
    return s;
  }

  final base = EnvironmentDev.baseUrl.replaceAll(RegExp(r'/$'), '');

  // Legacy: enlace simbólico /storage/... que en hosting suele dar 404 → mismo origen que el backend
  if (s.startsWith('/storage/')) {
    final rest = s.substring('/storage/'.length);
    return '$base/api/v1/storage/$rest';
  }
  if (s.startsWith('storage/')) {
    return '$base/api/v1/storage/${s.substring('storage/'.length)}';
  }

  // Contenido en disco "public" servido por GET /api/v1/storage/{path}
  if (!s.startsWith('/') &&
      (s.startsWith('hub/') ||
          s.startsWith('products/') ||
          s.startsWith('chat/'))) {
    return '$base/api/v1/storage/$s';
  }

  final path = s.startsWith('/') ? s : '/$s';
  return '$base$path';
}

/// Cabeceras alineadas con [HubPostsService] (JWT + cabeceras que algunos backends exigen).
Map<String, String> hubImageRequestHeaders(TokenService tokenService) {
  return {
    'Accept': 'image/*,*/*;q=0.8',
    'X-Requested-With': 'XMLHttpRequest',
    ...tokenService.getAuthHeaders(),
  };
}

/// [Image.network] para URLs del storage API público: sin Bearer para evitar 401 por token en rutas sin auth.
Map<String, String> hubImageRequestHeadersForUrl(String url, TokenService tokenService) {
  final lower = url.toLowerCase();
  if (lower.contains('/api/v1/storage/')) {
    return {
      'Accept': 'image/*,*/*;q=0.8',
      'X-Requested-With': 'XMLHttpRequest',
    };
  }
  return hubImageRequestHeaders(tokenService);
}

/// Aplana JSON tipo JSON:API / Laravel API Resource (`attributes`).
Map<String, dynamic> _effectivePostRoot(Map<String, dynamic> post) {
  final root = Map<String, dynamic>.from(post);
  final attrs = post['attributes'];
  if (attrs is Map<String, dynamic>) {
    attrs.forEach((k, v) {
      root.putIfAbsent(k, () => v);
    });
  }
  return root;
}

/// URLs de medios del post (imagen y vídeo); mismo orden que [extractPostMediaItems].
List<String> extractPostImageUrls(Map<String, dynamic> post) {
  return extractPostMediaItems(post).map((e) => e.url).toList(growable: false);
}

String? _firstUrlFromMediaMap(Map<String, dynamic> m) {
  const keys = [
    'original_url',
    'originalUrl',
    'preview_url',
    'previewUrl',
    'large_url',
    'medium_url',
    'small_url',
    'url',
    'src',
    'href',
    'path',
    'file_path',
    'filePath',
    'file_url',
    'fileUrl',
    'media_url',
    'mediaUrl',
    'image_url',
    'imageUrl',
    'full_url',
    'fullUrl',
    'public_url',
    'publicUrl',
    'thumbnail_url',
    'thumbnailUrl',
    'link',
  ];
  for (final k in keys) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  final fileName = m['file_name'] ?? m['fileName'];
  final sub = m['file_path'] ?? m['filePath'] ?? m['path'];
  if (fileName is String &&
      sub is String &&
      fileName.isNotEmpty &&
      sub.isNotEmpty) {
    final combined = '${sub.replaceAll(RegExp(r'^/+|/+$'), '')}/$fileName';
    return combined;
  }
  return null;
}
