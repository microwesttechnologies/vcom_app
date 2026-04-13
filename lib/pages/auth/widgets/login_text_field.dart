import 'package:flutter/material.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final ValueChanged<String>? onSubmitted;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    required this.obscure,
    this.suffix,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: VcomColors.azulOverlayTransparente60,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VcomColors.oroLujoso.withValues(alpha: 0.18)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onSubmitted: onSubmitted,
        style: const TextStyle(color: VcomColors.blanco, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: VcomColors.blancoCrema.withValues(alpha: 0.45),
          ),
          prefixIcon: Icon(
            icon,
            color: VcomColors.oroLujoso.withValues(alpha: 0.8),
          ),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}
