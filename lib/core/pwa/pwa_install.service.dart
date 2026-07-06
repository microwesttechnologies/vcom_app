import 'package:flutter/foundation.dart';
import 'package:vcom_app/core/pwa/pwa_install_platform.dart';
import 'package:vcom_app/core/pwa/pwa_platform.dart';

class PwaInstallService {
  PwaInstallService._();
  static final PwaInstallService instance = PwaInstallService._();

  bool _installPromptAvailable = false;
  VoidCallback? _listener;

  bool get canInstall => kIsWeb && _installPromptAvailable && !isStandalonePwa;
  bool get isInstalled => kIsWeb && isStandalonePwa;

  /// True si estamos en un navegador web y NO es la PWA instalada.
  bool get shouldShowInstallButton => kIsWeb && !isStandalonePwa;

  /// True si estamos en iOS pero con Chrome (no se puede instalar PWA desde Chrome en iOS).
  bool get isOnIosChrome => kIsWeb && isIosChrome;

  /// True si estamos en iOS Safari (se puede instalar).
  bool get isOnIosSafari => kIsWeb && isIosSafari;

  /// True si estamos en un dispositivo iOS.
  bool get isOnIos => kIsWeb && isIosDevice;

  /// True si estamos en Android.
  bool get isOnAndroid => kIsWeb && isAndroidDevice;

  /// Muestra guía manual en iOS (Safari/Chrome) cuando no hay prompt nativo.
  bool get showIosInstructions => isOnIos && !isInstalled;

  /// Muestra guía en Android (banner nativo o menú manual).
  bool get showAndroidInstructions => isOnAndroid && !isInstalled;

  /// Plataforma para elegir capturas y pasos del instructivo.
  PwaInstallPlatform get installPlatform {
    if (!kIsWeb || isInstalled) return PwaInstallPlatform.desktop;
    if (isOnIosChrome) return PwaInstallPlatform.iosChrome;
    if (isOnIos) return PwaInstallPlatform.iosSafari;
    if (isOnAndroid) return PwaInstallPlatform.android;
    return PwaInstallPlatform.desktop;
  }

  bool get shouldShowInstallBanner {
    if (!kIsWeb || isInstalled) return false;
    return canInstall || showIosInstructions || showAndroidInstructions;
  }

  Future<void> initialize() async {
    if (!kIsWeb) return;
    await registerPwaInstallListener(() {
      _installPromptAvailable = true;
      _listener?.call();
    });
  }

  void addListener(VoidCallback listener) {
    _listener = listener;
  }

  void removeListener() {
    _listener = null;
  }

  Future<bool> install() => promptPwaInstall();

  /// En iOS abre la hoja de compartir nativa (donde está "Agregar a Inicio").
  Future<bool> openShareSheet() => openNativeShareSheet();
}
