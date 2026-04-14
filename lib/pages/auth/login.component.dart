import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vcom_app/pages/auth/register_model.page.dart';
import 'package:vcom_app/pages/auth/widgets/login_form_card.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class LoginComponent extends StatelessWidget {
  final TextEditingController userController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool rememberCredentials;
  final bool biometricEnabled;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleRemember;
  final VoidCallback onSubmit;
  final VoidCallback onBiometric;

  const LoginComponent({
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: VcomColors.velvetDark,
        body: Container(
          decoration: const BoxDecoration(gradient: VcomColors.gradienteVelvet),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    children: [
                      Image.asset('assets/image/VCOM_G_PNG.png', height: 92),
                      const SizedBox(height: 8),
                      const Text(
                        'Gestión de Modelaje',
                        style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 4.2,
                          color: VcomColors.blanco,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LoginFormCard(
                        userController: userController,
                        passwordController: passwordController,
                        obscurePassword: obscurePassword,
                        rememberCredentials: rememberCredentials,
                        biometricEnabled: biometricEnabled,
                        onTogglePassword: onTogglePassword,
                        onToggleRemember: onToggleRemember,
                        onSubmit: onSubmit,
                        onBiometric: onBiometric,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        '¿Necesitas una cuenta?',
                        style: TextStyle(
                          color: VcomColors.blancoCrema.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterModelPage(),
                            ),
                          );
                        },
                        child: const Text(
                          'Solicitar membresía',
                          style: TextStyle(
                            color: VcomColors.oroPrimario,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
