import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vcom_app/components/commons/button.dart';
import 'package:vcom_app/components/commons/check.component.dart';
import 'package:vcom_app/pages/auth/widgets/login_biometric_button.dart';
import 'package:vcom_app/pages/auth/widgets/login_text_field.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class LoginFormCard extends StatelessWidget {
  final TextEditingController userController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberCredentials;
  final bool biometricEnabled;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRemember;
  final VoidCallback onSubmit;
  final VoidCallback onBiometric;

  const LoginFormCard({
    super.key,
    required this.userController,
    required this.passwordController,
    required this.obscurePassword,
    required this.rememberCredentials,
    required this.biometricEnabled,
    required this.onTogglePassword,
    required this.onToggleRemember,
    required this.onSubmit,
    required this.onBiometric,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: VcomColors.glassCardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: VcomColors.glassCardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Bienvenido',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: VcomColors.blanco,
                ),
              ),
              const SizedBox(height: 24),
              LoginTextField(
                controller: userController,
                hint: 'Ej: MOD-8829',
                icon: Icons.badge_outlined,
                obscure: false,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 14),
              LoginTextField(
                controller: passwordController,
                hint: 'Contraseña',
                icon: Icons.lock_open_outlined,
                obscure: obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: VcomColors.blancoCrema.withValues(alpha: 0.45),
                  ),
                  onPressed: onTogglePassword,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 14),
              CheckComponent(
                label: 'Recordar credenciales',
                isChecked: rememberCredentials,
                onChanged: (_) => onToggleRemember(),
                color: VcomColors.oroLujoso,
                textColor: VcomColors.blancoCrema,
              ),
              const SizedBox(height: 16),
              ButtonComponent(
                label: 'Acceder',
                size: ButtonSize.large,
                color: VcomColors.oroLujoso,
                textColor: VcomColors.azulMedianocheTexto,
                onPressed: onSubmit,
              ),
              const SizedBox(height: 20),
              Text(
                'ACCESO SEGURO',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 2,
                  color: VcomColors.blancoCrema.withValues(alpha: 0.45),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: LoginBiometricButton(
                  onTap: onBiometric,
                  active: biometricEnabled,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
