import 'package:video_player/video_player.dart';
import 'package:vcom_app/core/training/training_video_cache_io.dart';

Future<VideoPlayerController?> openCachedTrainingVideo(String url) async {
  final cached = await TrainingVideoCache.instance.getLocalFileIfCached(url);
  if (cached != null) {
    return VideoPlayerController.file(cached);
  }
  return null;
}

Future<void> precacheTrainingVideo(
  String url, {
  Map<String, String>? headers,
}) async {
  await TrainingVideoCache.instance.ensureCached(url, headers: headers);
}
