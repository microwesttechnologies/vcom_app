import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/user_status.service.dart';

/// Resuelve el nombre del autor de un post a partir de su JSON.
String resolvePostAuthorName(
  Map<String, dynamic> post,
  TokenService tokenService,
  UserStatusService userStatusService,
) {
  final directCandidates = <dynamic>[
    post['author_name'],
    post['authorName'],
    post['name_user'],
    post['full_name'],
    post['fullName'],
    post['employee_name'],
    post['model_name'],
    post['creator_name'],
    post['created_by_name'],
    post['name'],
  ];
  for (final value in directCandidates) {
    final normalized = value?.toString().trim() ?? '';
    if (normalized.isNotEmpty) return normalized;
  }

  final nestedCandidates = <Map<String, dynamic>?>[
    _asMap(post['author']),
    _asMap(post['user']),
    _asMap(post['employee']),
    _asMap(post['model']),
    _asMap(post['creator']),
    _asMap(post['created_by']),
  ];
  for (final map in nestedCandidates) {
    if (map == null) continue;
    final name = _firstNonEmpty(map, const [
      'name',
      'full_name',
      'fullName',
      'display_name',
      'displayName',
      'username',
    ]);
    if (name.isNotEmpty) return name;
  }

  final authorId = (post['author_id'] ?? post['authorId'] ?? '')
      .toString()
      .trim();

  if (authorId.isNotEmpty) {
    final resolved = _resolveByPresence(
      authorId,
      tokenService,
      userStatusService,
    );
    if (resolved != null) return resolved;
    return authorId.length > 12 ? authorId.substring(0, 12) : authorId;
  }

  return 'Autor';
}

/// Resuelve el nombre del autor de un comentario.
String resolveCommentAuthorName(
  dynamic comment,
  TokenService tokenService,
  UserStatusService userStatusService,
) {
  final direct = (comment.authorName ?? '').toString().trim();
  if (direct.isNotEmpty && direct.toLowerCase() != 'autor') {
    return direct;
  }

  final rawAuthorId = (comment.authorId ?? '').toString().trim();
  if (rawAuthorId.isNotEmpty) {
    final resolved = _resolveByPresence(
      rawAuthorId,
      tokenService,
      userStatusService,
    );
    if (resolved != null) return resolved;
  }

  return direct.isNotEmpty ? direct : 'Autor';
}

/// Normaliza un error removiendo el prefijo "Exception: ".
String normalizeError(Object e) {
  return e.toString().replaceFirst('Exception: ', '').trim();
}

/// Capitaliza cada palabra de un string.
String toDisplayName(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return value.trim();
  return words
      .map((w) {
        final lower = w.toLowerCase();
        return '${lower[0].toUpperCase()}${lower.substring(1)}';
      })
      .join(' ');
}

/// Genera un texto relativo legible: "Hace un momento", "Hace 5 minutos", etc.
String relativeTime(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Hace un momento';
    if (diff.inMinutes == 1) return 'Hace 1 minuto';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} minutos';
    if (diff.inHours == 1) return 'Hace 1 hora';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} horas';
    if (diff.inDays == 1) return 'Hace 1 día';
    return 'Hace ${diff.inDays} días';
  } catch (_) {
    return raw;
  }
}

// ── Utilidades privadas ──────────────────────────────────────

String? _resolveByPresence(
  String authorId,
  TokenService tokenService,
  UserStatusService userStatusService,
) {
  final currentUserId = tokenService.getUserId()?.trim() ?? '';
  final currentUserName = (tokenService.getUserName() ?? '').trim();
  if (currentUserId.isNotEmpty &&
      currentUserName.isNotEmpty &&
      currentUserId == authorId) {
    return currentUserName;
  }

  final presenceName = (userStatusService.presenceNameById[authorId] ?? '')
      .trim();
  if (presenceName.isNotEmpty) return toDisplayName(presenceName);
  return null;
}

Map<String, dynamic>? _asMap(dynamic value) {
  return value is Map<String, dynamic> ? value : null;
}

String _firstNonEmpty(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }
  return '';
}
