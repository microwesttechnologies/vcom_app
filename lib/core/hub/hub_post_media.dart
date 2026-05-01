import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';

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

void _hubCollectFromDynamic(
  dynamic value,
  void Function(String?) addResolved,
) {
  if (value == null) return;
  if (value is String) {
    addResolved(value);
    return;
  }
  if (value is List) {
    _hubCollectFromList(value, addResolved);
    return;
  }
  if (value is Map<String, dynamic>) {
    final inner =
        value['data'] ?? value['items'] ?? value['records'] ?? value['rows'];
    if (inner is List) {
      _hubCollectFromList(inner, addResolved);
    } else {
      addResolved(_firstUrlFromMediaMap(value));
    }
  }
}

void _hubCollectFromList(
  List<dynamic> list,
  void Function(String?) addResolved,
) {
  for (final e in list) {
    if (e is String) {
      addResolved(e);
    } else if (e is Map<String, dynamic>) {
      addResolved(_firstUrlFromMediaMap(e));
      final rel = e['media'] ?? e['file'] ?? e['attachment'];
      _hubCollectFromDynamic(rel, addResolved);
    }
  }
}

/// URLs de imágenes del post según el JSON del listado (resueltas contra [EnvironmentDev.baseUrl]).
List<String> extractPostImageUrls(Map<String, dynamic> post) {
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
  final urls = <String>[];

  void addResolved(String? s) {
    if (s == null) return;
    final u = resolveHubMediaUrl(s);
    if (u.isNotEmpty && !u.startsWith('data:')) urls.add(u);
  }

  for (final key in listKeys) {
    _hubCollectFromDynamic(root[key], addResolved);
  }

  if (urls.isEmpty) {
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
        addResolved(v);
        break;
      }
    }
  }

  return urls;
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
