import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Descarga cada URL de vídeo progresivo a disco una sola vez; reutiliza el archivo local.
/// No aplica a HLS/DASH (.m3u8, .mpd): el reproductor sigue en red.
class TrainingVideoCache {
  TrainingVideoCache._();

  static final TrainingVideoCache instance = TrainingVideoCache._();

  static const int _minValidBytes = 1024;
  static const Duration _downloadTimeout = Duration(minutes: 8);

  final Map<String, Future<File>> _inFlight = {};

  /// URLs que no conviene tratar como un único archivo descargable.
  static bool isStreamUrl(String url) {
    final u = url.toLowerCase().trim();
    return u.contains('.m3u8') || u.contains('.mpd');
  }

  static String _suffixFromUrl(String url) {
    try {
      final path = Uri.parse(url).path.toLowerCase();
      if (path.endsWith('.mp4')) return 'mp4';
      if (path.endsWith('.mov')) return 'mov';
      if (path.endsWith('.webm')) return 'webm';
      if (path.endsWith('.m4v')) return 'm4v';
    } catch (_) {}
    return 'video';
  }

  Future<Directory> _ensureDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/training_videos');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _targetFile(String url) async {
    final hash = sha256.convert(utf8.encode(url)).toString();
    final dir = await _ensureDir();
    return File('${dir.path}/$hash.${_suffixFromUrl(url)}');
  }

  /// Devuelve el archivo ya descargado sin iniciar red. [null] si no hay caché válida.
  Future<File?> getLocalFileIfCached(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || isStreamUrl(trimmed)) return null;
    final target = await _targetFile(trimmed);
    if (!await target.exists()) return null;
    final len = await target.length();
    if (len < _minValidBytes) return null;
    return target;
  }

  /// Garantiza un archivo local; si ya existe y tiene tamaño válido, no vuelve a descargar.
  Future<File> ensureCached(
    String url, {
    Map<String, String>? headers,
  }) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('video url vacía');
    }
    if (isStreamUrl(trimmed)) {
      throw UnsupportedError('streaming no se cachea como archivo único');
    }

    final target = await _targetFile(trimmed);
    if (await target.exists()) {
      final len = await target.length();
      if (len >= _minValidBytes) return target;
      try {
        await target.delete();
      } catch (_) {}
    }

    return _inFlight.putIfAbsent(
      trimmed,
      () => _downloadToFile(trimmed, headers, target),
    );
  }

  Future<File> _downloadToFile(
    String url,
    Map<String, String>? headers,
    File target,
  ) async {
    final tmp = File('${target.path}.part');
    try {
      if (await tmp.exists()) {
        try {
          await tmp.delete();
        } catch (_) {}
      }

      final response = await http
          .get(Uri.parse(url), headers: headers)
          .timeout(_downloadTimeout);

      if (response.statusCode != 200) {
        throw HttpException(
          'HTTP ${response.statusCode}',
          uri: Uri.parse(url),
        );
      }
      if (response.bodyBytes.length < _minValidBytes) {
        throw HttpException('respuesta demasiado pequeña', uri: Uri.parse(url));
      }

      await tmp.writeAsBytes(response.bodyBytes, flush: true);

      if (await target.exists()) {
        try {
          await target.delete();
        } catch (_) {}
      }
      await tmp.rename(target.path);

      return target;
    } catch (e, st) {
      debugPrint('[TrainingVideoCache] download failed: $e\n$st');
      try {
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
      try {
        if (await target.exists()) await target.delete();
      } catch (_) {}
      rethrow;
    } finally {
      _inFlight.remove(url);
    }
  }
}
