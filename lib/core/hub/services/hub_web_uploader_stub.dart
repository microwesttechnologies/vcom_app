import 'package:vcom_app/core/hub/hub_upload_media.dart';

/// Stub para plataformas nativas: esta función nunca se llama en nativo.
Future<void> uploadPostWeb({
  required String url,
  required String titlePost,
  required Map<String, String> headers,
  String? content,
  int? tagId,
  List<HubUploadMedia> mediaFiles = const [],
  void Function(int sent, int total)? onProgress,
}) async {
  throw UnsupportedError('uploadPostWeb solo está disponible en Flutter web.');
}
