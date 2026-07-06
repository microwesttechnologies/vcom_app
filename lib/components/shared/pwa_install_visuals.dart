import 'package:flutter/material.dart';
import 'package:vcom_app/core/pwa/pwa_install_guide_content.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Ilustraciones del instructivo PWA con marca VCOM (sin capturas genéricas).
class PwaInstallVisual extends StatelessWidget {
  const PwaInstallVisual({super.key, required this.type});

  final PwaInstallVisualType type;

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      PwaInstallVisualType.iosShareBar => const _PhoneFrame(
          child: _IosShareBarMock(),
        ),
      PwaInstallVisualType.iosAddToHome => const _PhoneFrame(
          child: _IosAddToHomeMock(),
        ),
      PwaInstallVisualType.androidChromeMenu => const _PhoneFrame(
          child: _AndroidChromeMenuMock(),
        ),
      PwaInstallVisualType.androidInstallApp => const _PhoneFrame(
          child: _AndroidInstallMock(),
        ),
      PwaInstallVisualType.desktopInstall => const _DesktopInstallMock(),
    };
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: const BoxConstraints(maxWidth: 220),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: child,
        ),
      ),
    );
  }
}

class _VcomMiniLogo extends StatelessWidget {
  const _VcomMiniLogo({this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      PwaInstallAssets.logo,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, _, _) => Icon(
        Icons.diamond_rounded,
        size: size,
        color: VcomColors.oroLujoso,
      ),
    );
  }
}

/// Safari inferior con botón Compartir resaltado.
class _IosShareBarMock extends StatelessWidget {
  const _IosShareBarMock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            color: VcomColors.azulZafiroProfundo,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const _VcomMiniLogo(size: 36),
                const SizedBox(height: 6),
                const Text(
                  'VCOM',
                  style: TextStyle(
                    color: VcomColors.oroLujoso,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Gestión de Modelaje',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 9,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: const Color(0xFFF2F2F7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.chevron_left, color: Colors.grey.shade500, size: 18),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
              _HighlightRing(
                child: Icon(
                  Icons.ios_share_rounded,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              Icon(Icons.bookmark_outline, color: Colors.grey.shade600, size: 18),
              Icon(Icons.square_outlined, color: Colors.grey.shade600, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

/// Hoja Compartir de iOS con VCOM y opción resaltada.
class _IosAddToHomeMock extends StatelessWidget {
  const _IosAddToHomeMock();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    color: Colors.black,
                    padding: const EdgeInsets.all(4),
                    child: const _VcomMiniLogo(size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VCOM',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'vcom-app.microwesttechnologies.com',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _IosMenuRow(label: 'Copiar', icon: Icons.copy_rounded),
          _HighlightMenuRow(
            label: 'Añadir a pantalla de inicio',
            icon: Icons.add_box_outlined,
          ),
          _IosMenuRow(label: 'Añadir marcador', icon: Icons.bookmark_add_outlined),
          _IosMenuRow(label: 'Imprimir', icon: Icons.print_outlined),
        ],
      ),
    );
  }
}

class _IosMenuRow extends StatelessWidget {
  const _IosMenuRow({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _HighlightMenuRow extends StatelessWidget {
  const _HighlightMenuRow({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: VcomColors.oroLujoso.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: VcomColors.oroLujoso, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: Colors.black87,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chrome Android con menú ⋮ resaltado.
class _AndroidChromeMenuMock extends StatelessWidget {
  const _AndroidChromeMenuMock();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFF202124),
          padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
          child: Row(
            children: [
              Icon(Icons.home_rounded, color: Colors.grey.shade400, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF303134),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, size: 10, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'vcom-app.microwest...',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _HighlightRing(
                child: Icon(
                  Icons.more_vert,
                  color: Colors.grey.shade200,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: VcomColors.azulZafiroProfundo,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _VcomMiniLogo(size: 40),
                const SizedBox(height: 6),
                const Text(
                  'VCOM',
                  style: TextStyle(
                    color: VcomColors.oroLujoso,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Menú Chrome Android con "Instalar aplicación" resaltado.
class _AndroidInstallMock extends StatelessWidget {
  const _AndroidInstallMock();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: VcomColors.azulZafiroProfundo),
        Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 170,
            margin: const EdgeInsets.only(top: 8, right: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF303134),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AndroidMenuRow('Nueva pestaña'),
                _AndroidMenuRow('Historial'),
                _HighlightAndroidRow('Instalar aplicación'),
                _AndroidMenuRow('Configuración'),
              ],
            ),
          ),
        ),
        const Align(
          alignment: Alignment.center,
          child: _VcomMiniLogo(size: 44),
        ),
      ],
    );
  }
}

class _AndroidMenuRow extends StatelessWidget {
  const _AndroidMenuRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: TextStyle(color: Colors.grey.shade200, fontSize: 11),
      ),
    );
  }
}

class _HighlightAndroidRow extends StatelessWidget {
  const _HighlightAndroidRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: VcomColors.oroLujoso.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: VcomColors.oroLujoso),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DesktopInstallMock extends StatelessWidget {
  const _DesktopInstallMock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF202124),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'vcom-app.microwesttechnologies.com',
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 10),
                ),
                const SizedBox(width: 8),
                _HighlightRing(
                  child: Icon(
                    Icons.install_desktop_rounded,
                    size: 16,
                    color: VcomColors.oroLujoso,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _VcomMiniLogo(size: 48),
        ],
      ),
    );
  }
}

class _HighlightRing extends StatelessWidget {
  const _HighlightRing({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: VcomColors.oroLujoso, width: 2),
        boxShadow: [
          BoxShadow(
            color: VcomColors.oroLujoso.withValues(alpha: 0.35),
            blurRadius: 6,
          ),
        ],
      ),
      child: child,
    );
  }
}
