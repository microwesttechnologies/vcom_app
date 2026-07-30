import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:vcom_app/core/hub/hub_upload_media.dart';
import 'package:vcom_app/pages/hub/hub_constants.dart';
import 'package:vcom_app/pages/hub/post/media_picker.widget.dart';

import 'hub_video_compress_platform.dart';

/// Prepara un video de Hub: valida tamaño y comprime si supera el umbral.
class HubVideoCompressService {
  const HubVideoCompressService();

  /// Convierte [media] en [HubUploadMedia] listo para subir.
  ///
  /// - Rechaza si supera [HubConstants.maxVideoSizeBytes].
  /// - En nativo, si ≥ [HubConstants.videoCompressionThresholdBytes],
  ///   comprime apuntando a ~50% del peso con calidad móvil (720p/Medium).
  /// - En web/PWA no comprime (sin API fiable); solo valida el tope.
  Future<HubUploadMedia> prepareVideo(PickedMedia media) async {
    if (media.type != 'video') {
      return HubUploadMedia(
        bytes: media.bytes,
        filename: media.filename,
        mimeType: HubUploadMedia.guessMimeType(media.filename),
        type: media.type,
      );
    }

    if (media.bytes.length > HubConstants.maxVideoSizeBytes) {
      throw Exception(
        'El video supera el máximo de 500 MB',
      );
    }

    if (kIsWeb ||
        media.bytes.length < HubConstants.videoCompressionThresholdBytes) {
      return _asUpload(media.bytes, media.filename);
    }

    final compressed = await compressHubVideo(
      bytes: media.bytes,
      filename: media.filename,
      sourcePath: media.path,
    );

    final outBytes = compressed.bytes;
    final outName = compressed.filename;

    if (outBytes.length > HubConstants.maxVideoSizeBytes) {
      throw Exception(
        'El video sigue superando 500 MB después de comprimir. '
        'Usa un archivo más liviano.',
      );
    }

    debugPrint(
      'Hub video comprimido: '
      '${_kb(media.bytes.length)}KB → ${_kb(outBytes.length)}KB',
    );

    return _asUpload(outBytes, outName);
  }

  HubUploadMedia _asUpload(Uint8List bytes, String filename) {
    return HubUploadMedia(
      bytes: bytes,
      filename: filename,
      mimeType: HubUploadMedia.guessMimeType(filename),
      type: 'video',
    );
  }

  String _kb(int bytes) => (bytes / 1024).toStringAsFixed(0);
}
