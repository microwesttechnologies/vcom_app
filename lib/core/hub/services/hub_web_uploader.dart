// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:vcom_app/core/hub/hub_upload_media.dart';

/// Sube un post usando FormData nativa del browser + XHR.
///
/// Ventajas sobre http.MultipartRequest en Flutter web:
/// - El browser codifica el multipart correctamente (filename en Content-Disposition).
/// - multer en Node.js detecta los archivos en req.files sin problemas.
/// - Progreso real de subida vía XHR upload progress events.
/// - No duplica el blob en memoria.
Future<void> uploadPostWeb({
  required String url,
  required String titlePost,
  required Map<String, String> headers,
  String? content,
  int? tagId,
  List<HubUploadMedia> mediaFiles = const [],
  void Function(int sent, int total)? onProgress,
}) async {
  final formData = html.FormData();
  formData.append('title_post', titlePost);
  if (content != null && content.isNotEmpty) {
    formData.append('content', content);
  }
  if (tagId != null) formData.append('tag_id', tagId.toString());

  for (final media in mediaFiles) {
    final blob = html.Blob(
      <dynamic>[media.bytes],
      media.mimeType,
    );
    formData.appendBlob('media[]', blob, media.filename);
  }

  final completer = Completer<void>();
  final xhr = html.HttpRequest();
  xhr.open('POST', url);

  // Solo headers que el browser permite en XHR (no Content-Type: el browser
  // lo setea automáticamente con el boundary correcto al usar FormData).
  headers.forEach((key, value) {
    final lower = key.toLowerCase();
    if (lower != 'content-type') {
      xhr.setRequestHeader(key, value);
    }
  });

  if (onProgress != null) {
    xhr.upload.onProgress.listen((event) {
      if (event.loaded != null && event.total != null && event.total! > 0) {
        onProgress(event.loaded!, event.total!);
      }
    });
  }

  xhr.onLoad.listen((_) {
    final status = xhr.status ?? 0;
    if (status >= 200 && status < 300) {
      completer.complete();
    } else {
      completer.completeError(
        Exception(
          'No fue posible crear la publicación ($status): ${xhr.responseText}',
        ),
      );
    }
  });

  xhr.onError.listen((_) {
    completer.completeError(
      Exception('Error de red al subir el video. Verifica tu conexión.'),
    );
  });

  xhr.send(formData);

  return completer.future.timeout(
    const Duration(minutes: 10),
    onTimeout: () => throw Exception(
      'Tiempo agotado al subir el video. Intenta con un archivo más liviano.',
    ),
  );
}
