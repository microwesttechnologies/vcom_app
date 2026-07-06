Future<bool> requestWebNotificationPermission() async => false;

Future<void> showWebNotification({
  required String title,
  required String body,
  Map<String, dynamic>? data,
}) async {}

bool get isStandalonePwa => false;

bool get isIosDevice => false;

bool get isAndroidDevice => false;

bool get isIosSafari => false;

bool get isIosChrome => false;

bool get isPageVisible => true;

void listenPageVisibility(void Function(bool visible) onChange) {}

Future<void> registerPwaInstallListener(void Function() onPromptAvailable) async {}

Future<bool> promptPwaInstall() async => false;

Future<bool> openNativeShareSheet() async => false;

void listenNotificationClicks(void Function(Map<String, dynamic> data) onClick) {}

Future<void> ensureFcmServiceWorkerReady() async {}

/// Sin efecto fuera de web.
void unlockWebAudioFromUserGesture() {}

/// Sin efecto fuera de web.
void unmuteHtmlVideosFromUserGesture() {}
