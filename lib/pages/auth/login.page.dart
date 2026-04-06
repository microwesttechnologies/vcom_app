import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'login.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';
import '../dahsboard/dashboard.page.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'register_model.page.dart';

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
        await ChatPushService().initialize();
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
        final msg = _cleanErrorMessage(e);
        _showServerResponseDialog(
          title: _resolveDialogTitle(msg),
          message: msg,
          icon: _resolveDialogIcon(msg, fallback: Icons.fingerprint),
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
      await ChatPushService().initialize();
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
        final errorMessage = _cleanErrorMessage(e);
        _showServerResponseDialog(
          title: _resolveDialogTitle(errorMessage),
          message: errorMessage,
          icon: _resolveDialogIcon(errorMessage),
        );
      }
    }
  }

  String _resolveDialogTitle(String message) {
    if (_isPendingAccountMessage(message)) {
      return 'Cuenta en revision';
    }
    return 'Respuesta del servidor';
  }

  IconData _resolveDialogIcon(String message, {IconData fallback = Icons.error_outline}) {
    if (_isPendingAccountMessage(message)) {
      return Icons.verified_user_outlined;
    }
    return fallback;
  }

  bool _isPendingAccountMessage(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('nuestros expertos estan evaluando tu cuenta');
  }

  String _cleanErrorMessage(Object error) {
    var message = error.toString().trim();
    const prefix = 'Exception: ';
    while (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trimLeft();
    }
    return message;
  }

  Future<void> _showServerResponseDialog({
    required String title,
    required String message,
    IconData icon = Icons.error_outline,
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.78),
      builder: (context) {
        final isPendingAccount = _isPendingAccountMessage(message);

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
                    color: VcomColors.oroBrillante.withValues(alpha: 0.24),
                    width: 1,
                  ),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF19152B),
                      Color(0xFF121224),
                      Color(0xFF0A0E17),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.55),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: VcomColors.oroLujoso.withValues(alpha: 0.08),
                      blurRadius: 28,
                      spreadRadius: -8,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -48,
                      right: -28,
                      child: IgnorePointer(
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                VcomColors.oroBrillante.withValues(alpha: 0.12),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 420,
                          maxHeight: MediaQuery.of(context).size.height * 0.72,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    VcomColors.oroBrillante.withValues(alpha: 0.0),
                                    VcomColors.oroBrillante.withValues(alpha: 0.72),
                                    VcomColors.bronceDorado.withValues(alpha: 0.18),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: VcomColors.oroBrillante.withValues(alpha: 0.22),
                                    ),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        VcomColors.oroBrillante.withValues(alpha: 0.16),
                                        VcomColors.bronceDorado.withValues(alpha: 0.08),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: VcomColors.oroPrimario,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPendingAccount
                                            ? 'VERIFICACION DE MEMBRESIA'
                                            : 'RESPUESTA DEL SERVIDOR',
                                        style: TextStyle(
                                          color: VcomColors.oroBrillante.withValues(alpha: 0.86),
                                          fontSize: 10,
                                          letterSpacing: 2.2,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w600,
                                          height: 1.05,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                            const SizedBox(height: 18),
                            Flexible(
                              child: SingleChildScrollView(
                                child: isPendingAccount
                                    ? _buildLuxuryPendingAccountContent(message)
                                    : _buildLuxuryGenericDialogContent(message),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  backgroundColor: VcomColors.oroPrimario.withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: VcomColors.oroPrimario.withValues(alpha: 0.28),
                                    ),
                                  ),
                                ),
                                child: Text(
                                  'Cerrar',
                                  style: TextStyle(
                                    color: VcomColors.oroPrimario,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget _buildLuxuryPendingAccountContent(String message) {
    final name = _extractLabeledValue(message, 'Nombre:');
    final email = _extractLabeledValue(message, 'Correo:');
    final username = _extractLabeledValue(message, 'Username:');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, ${name.isNotEmpty ? name : 'Modelo'}.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.98),
            fontSize: 19,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Nos agrada tu interes en pertenecer a nuestra comunidad. Nuestros expertos estan evaluando tu cuenta identificada con esta informacion.',
          style: TextStyle(
            color: VcomColors.blancoCrema.withValues(alpha: 0.88),
            fontSize: 15,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'CUENTA IDENTIFICADA',
          style: TextStyle(
            color: VcomColors.oroBrillante.withValues(alpha: 0.9),
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: VcomColors.oroBrillante.withValues(alpha: 0.16),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.035),
                VcomColors.oroBrillante.withValues(alpha: 0.02),
              ],
            ),
          ),
          child: Column(
            children: [
              _buildLuxuryInfoRow('Nombre', name),
              const SizedBox(height: 12),
              _buildLuxuryInfoRow('Correo', email),
              const SizedBox(height: 12),
              _buildLuxuryInfoRow('Username', username),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'En breve uno de nuestros expertos activara tu cuenta. Si hay inconsistencias, comunicate por medio del correo Admin@vcom.com.',
          style: TextStyle(
            color: VcomColors.blancoCrema.withValues(alpha: 0.82),
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLuxuryGenericDialogContent(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        color: Colors.white.withValues(alpha: 0.025),
      ),
      child: SelectableText(
        message,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 14,
          height: 1.52,
        ),
      ),
    );
  }

  Widget _buildLuxuryInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: VcomColors.oroBrillante.withValues(alpha: 0.78),
              fontSize: 10,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : 'No disponible',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  String _extractLabeledValue(String message, String label) {
    final match = RegExp(
      '^${RegExp.escape(label)}\\s*(.+)\$',
      multiLine: true,
    ).firstMatch(message);
    return match?.group(1)?.trim() ?? '';
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
                                color: Colors.black.withValues(alpha: 0.4),
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
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const RegisterModelPage(),
                                  ),
                                );
                              },
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
