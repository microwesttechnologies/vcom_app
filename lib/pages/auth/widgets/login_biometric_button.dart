import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class LoginBiometricButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool active;

  const LoginBiometricButton({
    super.key,
    required this.onTap,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active
              ? VcomColors.oroLujoso.withValues(alpha: 0.2)
              : VcomColors.azulOverlayTransparente50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active
                ? VcomColors.oroLujoso
                : VcomColors.oroLujoso.withValues(alpha: 0.25),
          ),
        ),
        child: Icon(
          Icons.fingerprint,
          color: active
              ? VcomColors.oroLujoso
              : VcomColors.oroLujoso.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
