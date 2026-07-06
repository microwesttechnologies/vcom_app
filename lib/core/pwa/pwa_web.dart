import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

bool _readIosStandalone() {
  try {
    final value =
        (web.window.navigator as JSObject).getProperty('standalone'.toJS);
    return value.dartify() == true;
  } catch (_) {
    return false;
  }
}

bool _isDisplayModeStandalone() {
  const modes = ['standalone', 'fullscreen', 'minimal-ui', 'window-controls-overlay'];
  for (final mode in modes) {
    if (web.window.matchMedia('(display-mode: $mode)').matches) {
      return true;
    }
  }
  return false;
}

bool _isPwaLaunchUrl() {
  final params = Uri.base.queryParameters;
  if (params['source'] == 'pwa') return true;

  // Flutter web con hash: /?source=pwa#/ruta
  final fragment = Uri.base.fragment.trim();
  if (fragment.contains('source=pwa')) return true;

  return false;
}

bool get isStandalonePwa =>
    _isDisplayModeStandalone() ||
    _readIosStandalone() ||
    _isPwaLaunchUrl();

bool get isIosDevice {
  final ua = web.window.navigator.userAgent.toLowerCase();
  if (ua.contains('iphone') || ua.contains('ipod')) return true;
  if (ua.contains('ipad')) return true;
  // iPadOS 13+ puede reportarse como Macintosh con touch.
  if (ua.contains('macintosh') && web.window.navigator.maxTouchPoints > 1) {
    return true;
  }
  return false;
}

bool get isAndroidDevice {
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('android');
}

bool get isIosChrome {
  if (!isIosDevice) return false;
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('crios');
}

bool get isIosSafari {
  if (!isIosDevice) return false;
  final ua = web.window.navigator.userAgent.toLowerCase();
  return ua.contains('safari') &&
      !ua.contains('crios') &&
      !ua.contains('fxios') &&
      !ua.contains('edgios');
}

bool get isPageVisible => web.document.visibilityState.toString() == 'visible';

void listenPageVisibility(void Function(bool visible) onChange) {
  web.document.addEventListener(
    'visibilitychange',
    ((web.Event _) {
      onChange(web.document.visibilityState.toString() == 'visible');
    }).toJS,
  );
}

Future<bool> requestWebNotificationPermission() async {
  if (!web.window.isSecureContext) return false;
  final permission = await web.Notification.requestPermission().toDart;
  return permission.toString() == 'granted';
}

Future<void> showWebNotification({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {
  if (web.Notification.permission != 'granted') return;

  final options = web.NotificationOptions(
    body: body,
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: (data?['conversation_id'] ?? 'vcom-chat').toString(),
    data: data?.jsify(),
  );
  final notification = web.Notification(title, options);
  notification.onclick = ((web.Event event) {
    notification.close();
    web.window.focus();
    if (data != null && data.isNotEmpty) {
      _notificationClickController.add(Map<String, dynamic>.from(data));
    }
  }).toJS;
}

final _notificationClickController =
    StreamController<Map<String, dynamic>>.broadcast();

void listenNotificationClicks(void Function(Map<String, dynamic> data) onClick) {
  _notificationClickController.stream.listen(onClick);

  web.window.navigator.serviceWorker.addEventListener(
    'message',
    ((web.Event event) {
      final messageEvent = event as web.MessageEvent;
      final payload = messageEvent.data?.dartify();
      if (payload is Map && payload['type'] == 'NOTIFICATION_CLICK') {
        final data = payload['data'];
        if (data is Map) {
          onClick(Map<String, dynamic>.from(data));
        }
      }
    }).toJS,
  );
}

Future<void> registerPwaInstallListener(void Function() onPromptAvailable) async {
  web.window.addEventListener(
    'beforeinstallprompt',
    ((web.Event event) {
      event.preventDefault();
      (web.window as JSObject).setProperty('deferredPwaPrompt'.toJS, event);
      onPromptAvailable();
    }).toJS,
  );
}

Future<bool> promptPwaInstall() async {
  final deferred =
      (web.window as JSObject).getProperty('deferredPwaPrompt'.toJS);
  if (deferred == null) return false;

  final prompt = deferred as JSObject;
  prompt.callMethod('prompt'.toJS);
  final result = prompt.callMethod('userChoice'.toJS);
  final choice = await (result as JSPromise).toDart;
  (web.window as JSObject).setProperty('deferredPwaPrompt'.toJS, null);
  final outcome = (choice as JSObject).getProperty('outcome'.toJS);
  return outcome?.toString() == 'accepted';
}

/// Abre la hoja de compartir nativa de iOS/Safari con la URL actual.
/// Desde ahí el usuario puede elegir "Agregar a Inicio".
Future<bool> openNativeShareSheet() async {
  try {
    final shareData = web.ShareData(
      title: 'VCOM',
      text: 'Instalar VCOM',
      url: web.window.location.href,
    );
    await web.window.navigator.share(shareData).toDart;
    return true;
  } catch (_) {
    return false;
  }
}

/// Desbloquea el contexto de audio en el mismo gesto del usuario (requerido en iOS).
void unlockWebAudioFromUserGesture() {
  try {
    final audioContext = web.AudioContext();
    audioContext.resume();
    final buffer = audioContext.createBuffer(1, 1, 22050);
    final source = audioContext.createBufferSource();
    source.buffer = buffer;
    source.connect(audioContext.destination);
    source.start(0);
  } catch (_) {
    try {
      final webkitCtor =
          (web.window as JSObject).getProperty('webkitAudioContext'.toJS);
      if (webkitCtor != null) {
        final ctx = (webkitCtor as JSFunction).callAsConstructor() as JSObject;
        ctx.callMethod('resume'.toJS);
      }
    } catch (_) {}
  }
}

/// Desmutea elementos <video> del DOM en el gesto del usuario (Safari/iOS PWA).
void unmuteHtmlVideosFromUserGesture() {
  try {
    final nodeList = web.document.querySelectorAll('video');
    final length = nodeList.length;
    for (var i = 0; i < length; i++) {
      final node = nodeList.item(i);
      if (node == null) continue;
      final video = node as JSObject;
      video.setProperty('muted'.toJS, false.toJS);
      video.setProperty('volume'.toJS, 1.toJS);
      video.callMethod('play'.toJS);
    }
  } catch (_) {}
}
