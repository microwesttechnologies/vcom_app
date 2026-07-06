import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

Future<bool> validateChatVideoDuration(
  List<int> bytes,
  String filename,
) async {
  final tempDir = await getTemporaryDirectory();
  final safeName = filename.replaceAll(RegExp(r'[^\w.\-]'), '_');
  final file = File('${tempDir.path}/chat_validate_$safeName');
  VideoPlayerController? controller;
  try {
    await file.writeAsBytes(bytes, flush: true);
    controller = VideoPlayerController.file(file);
    await controller.initialize();
    return controller.value.duration.inSeconds <= 60;
  } catch (_) {
    return false;
  } finally {
    await controller?.dispose();
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
  }
}
