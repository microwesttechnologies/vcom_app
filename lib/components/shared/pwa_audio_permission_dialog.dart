import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

/// Diálogo de permiso de sonido para PWA (sustituye la API inexistente del navegador).
Future<bool?> showPwaAudioPermissionDialog(
  BuildContext context, {
  VoidCallback? onAllow,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: VcomColors.oroLujoso.withValues(alpha: 0.35),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    VcomColors.azulOverlayTransparente.withValues(alpha: 0.92),
                    VcomColors.azulNocheSombra.withValues(alpha: 0.95),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    size: 44,
                    color: VcomColors.oroLujoso.withValues(alpha: 0.95),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sonido en VCOM',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: VcomColors.blancoCrema,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¿Permitir que VCOM reproduzca sonidos desde la app instalada? '
                    'Incluye el video de bienvenida y otros contenidos con audio.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: VcomColors.blancoCrema.withValues(alpha: 0.82),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        onAllow?.call();
                        Navigator.of(context).pop(true);
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: VcomColors.oroLujoso,
                        foregroundColor: VcomColors.azulMedianocheTexto,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Permitir sonidos',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      'No, gracias',
                      style: TextStyle(
                        color: VcomColors.blancoCrema.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
