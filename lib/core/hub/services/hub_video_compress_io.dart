import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

/// Resultado de compresión de video Hub.
class HubCompressedVideo {
  const HubCompressedVideo({
    required this.bytes,
    required this.filename,
  });

  final Uint8List bytes;
  final String filename;
}

/// Comprime video nativo apuntando a ~50% del tamaño con calidad móvil.
Future<HubCompressedVideo> compressHubVideo({
  required Uint8List bytes,
  required String filename,
  String? sourcePath,
}) async {
  File? tempInput;
  String inputPath = sourcePath ?? '';

  try {
    if (inputPath.isEmpty || !File(inputPath).existsSync()) {
      final dir = await getTemporaryDirectory();
      final ext = _extensionOf(filename);
      tempInput = File(
        '${dir.path}/hub_vid_in_${DateTime.now().millisecondsSinceEpoch}$ext',
      );
      await tempInput.writeAsBytes(bytes, flush: true);
      inputPath = tempInput.path;
    }

    final targetBytes = (bytes.length * 0.5).round();

    // Medium + 720p-ish: buena calidad en móviles sin bajar resolución agresiva.
    MediaInfo? info = await VideoCompress.compressVideo(
      inputPath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );

    if (info?.file == null || !info!.file!.existsSync()) {
      debugPrint('Hub video compress: sin resultado, se usa original');
      return HubCompressedVideo(bytes: bytes, filename: filename);
    }

    var outFile = info.file!;
    var outBytes = await outFile.readAsBytes();

    // Si no bajó cerca del 50%, reintentar con Res1280 (apto para celulares).
    if (outBytes.length > targetBytes) {
      final second = await VideoCompress.compressVideo(
        inputPath,
        quality: VideoQuality.Res1280x720Quality,
        deleteOrigin: false,
        includeAudio: true,
      );
      if (second?.file != null && second!.file!.existsSync()) {
        final secondBytes = await second.file!.readAsBytes();
        if (secondBytes.length < outBytes.length) {
          outFile = second.file!;
          outBytes = secondBytes;
        }
      }
    }

    // Si la "compresión" no redució, conservar original.
    if (outBytes.length >= bytes.length) {
      return HubCompressedVideo(bytes: bytes, filename: filename);
    }

    final outName = filename.toLowerCase().endsWith('.mp4')
        ? filename
        : filename.contains('.')
            ? filename.replaceAll(RegExp(r'\.[^.]+$'), '.mp4')
            : '$filename.mp4';

    return HubCompressedVideo(
      bytes: Uint8List.fromList(outBytes),
      filename: outName,
    );
  } catch (e) {
    debugPrint('Hub video compress falló, usando original: $e');
    return HubCompressedVideo(bytes: bytes, filename: filename);
  } finally {
    try {
      await tempInput?.delete();
    } catch (_) {}
    try {
      await VideoCompress.deleteAllCache();
    } catch (_) {}
  }
}

String _extensionOf(String filename) {
  final i = filename.lastIndexOf('.');
  if (i < 0 || i == filename.length - 1) return '.mp4';
  return filename.substring(i);
}
