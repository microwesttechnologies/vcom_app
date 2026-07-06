import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

web.HTMLVideoElement? findPrimaryHtmlVideoElement() {
  final nodeList = web.document.querySelectorAll('video');
  web.HTMLVideoElement? best;
  var bestArea = 0.0;
  for (var i = 0; i < nodeList.length; i++) {
    final node = nodeList.item(i);
    if (node == null) continue;
    final rect = (node as web.Element).getBoundingClientRect();
    final area = rect.width * rect.height;
    if (area > bestArea && rect.width > 0 && rect.height > 0) {
      bestArea = area;
      best = node as web.HTMLVideoElement;
    }
  }
  return best;
}

Future<void> _waitForCanPlay(web.HTMLVideoElement video) async {
  if (video.readyState >= web.HTMLMediaElement.HAVE_FUTURE_DATA) return;

  final completer = Completer<void>();
  late JSFunction listener;
  listener = ((web.Event _) {
    if (video.readyState >= web.HTMLMediaElement.HAVE_FUTURE_DATA) {
      video.removeEventListener('canplay', listener);
      if (!completer.isCompleted) completer.complete();
    }
  }).toJS;

  video.addEventListener('canplay', listener);
  try {
    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => video.removeEventListener('canplay', listener),
    );
  } catch (_) {
    video.removeEventListener('canplay', listener);
  }
}

Future<void> _seekHtmlVideoElement(
  web.HTMLVideoElement video,
  double targetSeconds,
) async {
  if ((video.currentTime - targetSeconds).abs() < 0.25) {
    video.currentTime = targetSeconds;
    return;
  }

  final completer = Completer<void>();
  late JSFunction listener;
  listener = ((web.Event _) {
    video.removeEventListener('seeked', listener);
    if (!completer.isCompleted) completer.complete();
  }).toJS;

  video.addEventListener('seeked', listener);
  video.currentTime = targetSeconds;

  try {
    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () => video.removeEventListener('seeked', listener),
    );
  } catch (_) {
    video.removeEventListener('seeked', listener);
  }

  await _waitForCanPlay(video);
}

Future<bool> seekTrainingHtmlVideo(
  Duration position, {
  required bool playAfter,
}) async {
  final video = findPrimaryHtmlVideoElement();
  if (video == null) return false;

  final targetSeconds = position.inMilliseconds / 1000.0;
  video.pause();

  try {
    await _seekHtmlVideoElement(video, targetSeconds);
  } catch (_) {
    return false;
  }

  if (!playAfter) return true;

  try {
    await video.play().toDart;
  } catch (_) {
    return false;
  }
  return !video.paused;
}

Future<bool> playTrainingHtmlVideo() async {
  final video = findPrimaryHtmlVideoElement();
  if (video == null) return false;
  try {
    await _waitForCanPlay(video);
    await video.play().toDart;
    return !video.paused;
  } catch (_) {
    return false;
  }
}
