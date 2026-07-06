import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:vcom_app/components/shared/pwa_install_guide_sheet.dart';
import 'package:vcom_app/core/pwa/pwa_install.service.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class PwaInstallBanner extends StatefulWidget {
  const PwaInstallBanner({super.key});

  @override
  State<PwaInstallBanner> createState() => _PwaInstallBannerState();
}

class _PwaInstallBannerState extends State<PwaInstallBanner> {
  final _pwa = PwaInstallService.instance;
  bool _visible = false;
  bool _installing = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb || _pwa.isInstalled) return;
    _pwa.addListener(_refresh);
    _refresh();
    unawaited(_pwa.initialize().then((_) {
      if (mounted) _refresh();
    }));
  }

  void _refresh() {
    final show = _pwa.shouldShowInstallBanner;
    if (show != _visible && mounted) {
      setState(() => _visible = show);
    }
  }

  @override
  void dispose() {
    _pwa.removeListener();
    super.dispose();
  }

  Future<void> _install() async {
    setState(() => _installing = true);
    final accepted = await _pwa.install();
    if (!mounted) return;
    setState(() {
      _installing = false;
      if (accepted) _visible = false;
    });
  }

  void _openGuide() {
    showPwaInstallGuide(
      context,
      platform: _pwa.installPlatform,
    );
  }

  String _bannerMessage() {
    if (_pwa.isOnIos) {
      return 'Instala VCOM en tu iPhone para acceso rápido y notificaciones.';
    }
    if (_pwa.isOnAndroid) {
      return 'Chrome mostrará "Instalar VCOM - Gestión de Modelaje" arriba. Toca Instalar.';
    }
    return 'Instala VCOM en tu dispositivo para acceso rápido.';
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: VcomColors.azulOverlayTransparente.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _pwa.isOnIos
                    ? Icons.phone_iphone_rounded
                    : _pwa.isOnAndroid
                        ? Icons.phone_android_rounded
                        : Icons.install_mobile,
                color: VcomColors.oroLujoso,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _bannerMessage(),
                  style: const TextStyle(
                    color: VcomColors.blancoCrema,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
              if (_pwa.canInstall) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _installing ? null : _install,
                  child: _installing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Instalar'),
                ),
              ],
              TextButton(
                onPressed: _openGuide,
                child: Text(_pwa.canInstall ? 'Guía' : 'Ver guía'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
