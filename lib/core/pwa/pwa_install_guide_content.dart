import 'package:flutter/material.dart';
import 'package:vcom_app/core/pwa/pwa_install_platform.dart';

/// Marca y capturas reales de VCOM para los instructivos PWA.
abstract final class PwaInstallAssets {
  static const String logo = 'assets/image/VCOM_G_PNG.png';
  static const String loginScreen = 'assets/image/pwa/pwa_login_screen.png';
  /// Captura real: banner de Chrome "Instalar VCOM - Gestión de Modelaje".
  static const String androidInstallBanner =
      'assets/image/pwa/pwa_android_install_banner.png';
}

/// Ilustraciones nativas Flutter con marca VCOM (sustituyen PNG genéricos).
enum PwaInstallVisualType {
  iosShareBar,
  iosAddToHome,
  androidChromeMenu,
  androidInstallApp,
  desktopInstall,
}

class PwaInstallStep {
  const PwaInstallStep({
    required this.title,
    required this.description,
    this.imageAsset,
    this.visual,
    this.icon,
  });

  final String title;
  final String description;
  final String? imageAsset;
  final PwaInstallVisualType? visual;
  final IconData? icon;
}

class PwaInstallGuideContent {
  const PwaInstallGuideContent({
    required this.platform,
    required this.title,
    required this.subtitle,
    required this.steps,
  });

  final PwaInstallPlatform platform;
  final String title;
  final String subtitle;
  final List<PwaInstallStep> steps;

  static PwaInstallGuideContent forPlatform(PwaInstallPlatform platform) {
    switch (platform) {
      case PwaInstallPlatform.iosChrome:
        return const PwaInstallGuideContent(
          platform: PwaInstallPlatform.iosChrome,
          title: 'Instalar en iPhone',
          subtitle: 'En Chrome de iPhone no se puede instalar directamente. Usa Safari:',
          steps: [
            PwaInstallStep(
              title: 'Abre VCOM en Safari',
              description:
                  'Copia la URL de esta página y ábrela en Safari (no en Chrome). Verás la pantalla de login de VCOM.',
              imageAsset: PwaInstallAssets.loginScreen,
            ),
            PwaInstallStep(
              title: 'Toca Compartir',
              description:
                  'En la barra inferior de Safari, toca el ícono Compartir (↑ en un cuadrado).',
              visual: PwaInstallVisualType.iosShareBar,
            ),
            PwaInstallStep(
              title: 'Añadir a pantalla de inicio',
              description:
                  'Desliza el menú y elige "Añadir a pantalla de inicio", luego confirma con "Añadir".',
              visual: PwaInstallVisualType.iosAddToHome,
            ),
            PwaInstallStep(
              title: 'Abre desde el icono VCOM',
              description:
                  'Cierra Safari y abre VCOM desde el nuevo icono dorado en tu pantalla de inicio.',
              imageAsset: PwaInstallAssets.logo,
            ),
          ],
        );
      case PwaInstallPlatform.iosSafari:
        return const PwaInstallGuideContent(
          platform: PwaInstallPlatform.iosSafari,
          title: 'Instalar VCOM en iPhone',
          subtitle: 'Sigue estos pasos en Safari para acceso rápido y notificaciones:',
          steps: [
            PwaInstallStep(
              title: 'Pantalla de login VCOM',
              description:
                  'Asegúrate de estar en la app web. Toca "¿Deseas instalar la App?" debajo de Acceder.',
              imageAsset: PwaInstallAssets.loginScreen,
            ),
            PwaInstallStep(
              title: 'Toca Compartir',
              description:
                  'En la barra inferior, toca el botón Compartir (↑ en un cuadrado).',
              visual: PwaInstallVisualType.iosShareBar,
            ),
            PwaInstallStep(
              title: 'Añadir a pantalla de inicio',
              description:
                  'Busca y selecciona "Añadir a pantalla de inicio", luego toca "Añadir".',
              visual: PwaInstallVisualType.iosAddToHome,
            ),
            PwaInstallStep(
              title: 'Abre desde el icono VCOM',
              description:
                  'Abre VCOM desde el icono en tu pantalla de inicio (no desde una pestaña de Safari).',
              imageAsset: PwaInstallAssets.logo,
            ),
          ],
        );
      case PwaInstallPlatform.android:
        return const PwaInstallGuideContent(
          platform: PwaInstallPlatform.android,
          title: 'Instalar VCOM en Android',
          subtitle:
              'Chrome mostrará un aviso arriba para instalar VCOM como aplicación:',
          steps: [
            PwaInstallStep(
              title: 'Pantalla de login VCOM',
              description:
                  'Abre VCOM en Chrome. Puedes tocar "¿Deseas instalar la App?" en el login.',
              imageAsset: PwaInstallAssets.loginScreen,
            ),
            PwaInstallStep(
              title: 'Aviso "Instalar VCOM"',
              description:
                  'Arriba verás: "Instalar VCOM - Gestión de Modelaje". Toca el botón azul Instalar.',
              imageAsset: PwaInstallAssets.androidInstallBanner,
            ),
            PwaInstallStep(
              title: 'Icono VCOM en tu inicio',
              description:
                  'Abre VCOM desde el icono dorado en tu pantalla (no desde una pestaña de Chrome).',
              imageAsset: PwaInstallAssets.logo,
            ),
          ],
        );
      case PwaInstallPlatform.desktop:
        return const PwaInstallGuideContent(
          platform: PwaInstallPlatform.desktop,
          title: 'Instalar VCOM',
          subtitle: 'Instala la aplicación web en tu computador:',
          steps: [
            PwaInstallStep(
              title: 'Pantalla de login VCOM',
              description:
                  'Inicia sesión en la app web desde Chrome o Edge.',
              imageAsset: PwaInstallAssets.loginScreen,
            ),
            PwaInstallStep(
              title: 'Icono de instalar',
              description:
                  'Busca el ícono de instalar (⊕ o monitor) en la barra de direcciones.',
              visual: PwaInstallVisualType.desktopInstall,
            ),
            PwaInstallStep(
              title: 'Icono VCOM instalado',
              description: 'Haz clic en "Instalar". VCOM quedará como app de escritorio.',
              imageAsset: PwaInstallAssets.logo,
            ),
          ],
        );
    }
  }
}
