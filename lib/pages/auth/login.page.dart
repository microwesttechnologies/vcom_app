import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import '../dahsboard/dashboard.page.dart';
import 'package:vcom_app/core/common/user_status.service.dart';

/// Página de login - Diseño según imagen de referencia
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  late final LoginComponent _loginComponent;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _loginComponent = LoginComponent();
    _loginComponent.addListener(_onLoginComponentChanged);
    _loginComponent.initialize().then((_) {
      if (mounted) setState(() {});
    });

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  void _onLoginComponentChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _loginComponent.removeListener(_onLoginComponentChanged);
    _animationController.dispose();
    _loginComponent.dispose();
    super.dispose();
  }

  void _handleBiometric() async {
    if (!_loginComponent.biometricEnabled) {
      // Mostrar ayuda si no hay credenciales guardadas
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Primero inicia sesión y activa\n"Recordar credenciales"',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1a2847),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Mostrar diálogo de carga mientras el sistema biométrico responde
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final loggedIn = await _loginComponent.loginWithBiometric();
      if (mounted) {
        Navigator.of(context).pop(); // Cierra loading
        if (!loggedIn) return; // Usuario canceló, no hacer nada
        await UserStatusService().setOnline();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardPage()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        final msg = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.fingerprint, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
              ],
            ),
            backgroundColor: const Color(0xFF6B3D2E),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _handleLogin() async {
    if (!_loginComponent.validateFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingrese un correo y contraseña válidos'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await _loginComponent.performLogin();
      await UserStatusService().setOnline();
      if (mounted) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage, style: const TextStyle(fontSize: 14))),
              ],
            ),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'OK', textColor: Colors.white, onPressed: () {}),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final maxWidth = size.width * 0.9;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        resizeToAvoidBottomInset: false,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.8),
              radius: 1.2,
              colors: [
                Color(0xFF273C67),
                Color(0xFF1a2847),
                Color(0xFF0d1525),
                Color(0xFF000000),
              ],
              stops: [0.0, 0.35, 0.7, 1.0],
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              top: true,
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableHeight = constraints.maxHeight - bottomPadding;
                  return SizedBox(
                    height: availableHeight,
                    width: constraints.maxWidth,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24,
                            bottom: 24 + bottomPadding,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                      // Header: Logo + Gestión de Modelaje (como login.html)
                      Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Column(
                          children: [
                            Image.asset(
                              'assets/image/VCOM_G_PNG.png',
                              height: 100,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Gestión de Modelaje',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                letterSpacing: 4.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Tarjeta de login (glassmorphism)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
                            child: Container(
                              width: maxWidth,
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: VcomColors.glassCardBorder,
                                  width: 1,
                                ),
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
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Campo Usuario/ID
                                  _buildInputField(
                                    controller: _loginComponent.emailController,
                                    hint: 'Ej: MOD-8829',
                                    icon: Icons.badge_outlined,
                                    obscure: false,
                                  ),
                                  const SizedBox(height: 16),

                                  // Campo Contraseña
                                  _buildInputField(
                                    controller: _loginComponent.passwordController,
                                    hint: '••••••••',
                                    icon: Icons.lock_open_outlined,
                                    obscure: _loginComponent.obscurePassword,
                                    suffix: IconButton(
                                      icon: Icon(
                                        _loginComponent.obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: Colors.white.withValues(alpha: 0.3),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() => _loginComponent.togglePasswordVisibility());
                                      },
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Recordar credenciales
                                  GestureDetector(
                                    onTap: () => setState(() => _loginComponent.toggleRememberCredentials()),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: Checkbox(
                                            value: _loginComponent.rememberCredentials,
                                            onChanged: (_) => setState(() => _loginComponent.toggleRememberCredentials()),
                                            activeColor: const Color(0xFFf1bf27),
                                            checkColor: Colors.black,
                                            side: BorderSide(
                                              color: Colors.white.withValues(alpha: 0.35),
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            visualDensity: VisualDensity.compact,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Recordar credenciales',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.white.withValues(alpha: 0.55),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // ¿Olvidaste tu contraseña? - centrado, color #bab29c
                                  Center(
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.only(top: 8),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        '¿Olvidaste tu contraseña?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: const Color(0xFFbab29c),
                                          decoration: TextDecoration.underline,
                                          decorationColor: const Color(0xFFbab29c),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Botón Acceder - glass-gem-button (según login.html)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ClipRect(
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                        child: Container(
                                        decoration: BoxDecoration(
                                          color: Color.fromRGBO(241, 191, 39, 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Color.fromRGBO(241, 191, 39, 0.3),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color.fromRGBO(241, 191, 39, 0.1),
                                              blurRadius: 20,
                                              spreadRadius: 0,
                                              offset: Offset.zero,
                                            ),
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.3),
                                              blurRadius: 30,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _handleLogin,
                                            borderRadius: BorderRadius.circular(12),
                                            splashColor: Color.fromRGBO(241, 191, 39, 0.2),
                                            highlightColor: Color.fromRGBO(241, 191, 39, 0.1),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 16),
                                              alignment: Alignment.center,
                                              child: const Text(
                                                'Acceder',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFf1bf27),
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                  const SizedBox(height: 24),

                                  // ACCESO SEGURO
                                  Row(
                                    children: [
                                      Expanded(child: _buildDivider()),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Text(
                                          'ACCESO SEGURO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withValues(alpha: 0.3),
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ),
                                      Expanded(child: _buildDivider()),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  // Botones biométricos
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _buildBiometricButton(icon: Icons.face, onTap: null),
                                      const SizedBox(width: 24),
                                      _buildBiometricButton(
                                        icon: Icons.fingerprint,
                                        onTap: _handleBiometric,
                                        active: _loginComponent.biometricEnabled,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer: ¿Necesitas una cuenta?
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            Text(
                              '¿Necesitas una cuenta?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GestureDetector(
                              onTap: () {},
                              child: Text(
                                'Solicitar membresía',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: VcomColors.oroPrimario,
                                  decoration: TextDecoration.underline,
                                  decorationColor: VcomColors.oroPrimario,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  ),
  ),
  ),
  );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color.fromRGBO(241, 191, 39, 0.1),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        textInputAction: hint.contains('Contraseña') ? TextInputAction.done : TextInputAction.next,
        onFieldSubmitted: (_) {
          if (hint.contains('Contraseña')) _handleLogin();
        },
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withValues(alpha: 0.2),
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: Color.fromRGBO(241, 191, 39, 0.5), size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildBiometricButton({
    required IconData icon,
    VoidCallback? onTap,
    bool active = false,
  }) {
    final enabled = onTap != null;
    final borderColor = active
        ? const Color(0xFFf1bf27)
        : Color.fromRGBO(241, 191, 39, enabled ? 0.2 : 0.08);
    final iconColor = active
        ? const Color(0xFFf1bf27)
        : Color.fromRGBO(241, 191, 39, enabled ? 0.5 : 0.2);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: active
                  ? Color.fromRGBO(241, 191, 39, 0.12)
                  : Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: active ? 1.5 : 1),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: Color.fromRGBO(241, 191, 39, 0.25),
                        blurRadius: 14,
                        spreadRadius: 0,
                      ),
                    ]
                  : [],
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
        ),
      ),
    );
  }
}
