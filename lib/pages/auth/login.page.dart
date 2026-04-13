import 'package:flutter/material.dart';
import 'package:vcom_app/core/auth/login/login.controller.dart';
import 'package:vcom_app/core/chat/chat_push.service.dart';
import 'package:vcom_app/core/common/app_routes.dart';
import 'package:vcom_app/core/common/user_status.service.dart';
import 'package:vcom_app/pages/auth/login.component.dart';
import 'package:vcom_app/style/vcom_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LoginController();
    _controller.addListener(_onChanged);
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _handleLogin() async {
    final success = await _runWithLoading(() async {
      await _controller.performLogin();
      await UserStatusService().setOnline();
      await _initializeChatPushSafely();
    });
    if (!success || !mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  Future<void> _handleBiometric() async {
    var authenticated = false;
    final success = await _runWithLoading(() async {
      final loggedIn = await _controller.loginWithBiometric();
      authenticated = loggedIn;
      if (!loggedIn) return;
      await UserStatusService().setOnline();
      await _initializeChatPushSafely();
    });
    if (!success || !authenticated || !mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  Future<bool> _runWithLoading(Future<void> Function() action) async {
    _showLoading();
    try {
      await action();
      return true;
    } catch (e) {
      await _showErrorDialog(_cleanErrorMessage(e.toString()));
      return false;
    } finally {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _initializeChatPushSafely() async {
    try {
      await ChatPushService().initialize();
    } catch (_) {
      // No bloquear login si falla la inicialización de notificaciones push.
    }
  }

  void _showLoading() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: VcomColors.oroLujoso),
      ),
    );
  }

  String _cleanErrorMessage(String raw) {
    var message = raw.trim();
    const prefix = 'Exception: ';
    while (message.startsWith(prefix)) {
      message = message.substring(prefix.length).trimLeft();
    }
    return message;
  }

  Future<void> _showErrorDialog(String message) async {
    final friendly = _buildFriendlyError(message);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: VcomColors.azulZafiroProfundo,
        title: Text(
          friendly.title,
          style: const TextStyle(color: VcomColors.blancoCrema),
        ),
        content: Text(
          friendly.message,
          style: const TextStyle(color: VcomColors.blancoCrema),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cerrar',
              style: TextStyle(color: VcomColors.oroLujoso),
            ),
          ),
        ],
      ),
    );
  }

  _FriendlyError _buildFriendlyError(String technicalMessage) {
    final message = technicalMessage.toLowerCase();

    if (_isInvalidCredentialsError(message)) {
      return const _FriendlyError(
        title: 'No pudimos iniciar sesion',
        message:
            'El usuario o la contrasena no coinciden. Revisa tus datos e '
            'intentalo de nuevo.',
      );
    }

    if (_isPendingAccountError(message)) {
      return const _FriendlyError(
        title: 'Cuenta en revision',
        message:
            'Tu cuenta aun esta en proceso de activacion. Cuando este lista '
            'podras ingresar sin problema.',
      );
    }

    if (_isTimeoutError(message)) {
      return const _FriendlyError(
        title: 'Conexion lenta',
        message:
            'La conexion esta tardando mas de lo esperado. Intentalo de '
            'nuevo en unos minutos.',
      );
    }

    if (_isNetworkError(message)) {
      return const _FriendlyError(
        title: 'Sin conexion',
        message:
            'No pudimos conectarnos en este momento. Verifica tu internet e '
            'intentalo nuevamente.',
      );
    }

    return const _FriendlyError(
      title: 'No pudimos iniciar sesion',
      message:
          'Ocurrio un problema al intentar ingresar. Intentalo nuevamente y, '
          'si persiste, contacta a soporte.',
    );
  }

  bool _isInvalidCredentialsError(String message) {
    return message.contains('credenciales invalidas') ||
        message.contains('http 401') ||
        message.contains('unauthorized');
  }

  bool _isPendingAccountError(String message) {
    return message.contains('no esta activa') ||
        message.contains('no está activa') ||
        message.contains('evaluando tu cuenta');
  }

  bool _isTimeoutError(String message) {
    return message.contains('tiempo de espera') || message.contains('timeout');
  }

  bool _isNetworkError(String message) {
    return message.contains('error de red') ||
        message.contains('error ssl') ||
        message.contains('conexion') ||
        message.contains('socketexception');
  }

  @override
  Widget build(BuildContext context) {
    return LoginComponent(
      userController: _controller.emailController,
      passwordController: _controller.passwordController,
      obscurePassword: _controller.obscurePassword,
      rememberCredentials: _controller.rememberCredentials,
      biometricEnabled: _controller.biometricEnabled,
      onTogglePassword: _controller.togglePasswordVisibility,
      onToggleRemember: _controller.toggleRememberCredentials,
      onSubmit: _handleLogin,
      onBiometric: _handleBiometric,
    );
  }
}

class _FriendlyError {
  final String title;
  final String message;

  const _FriendlyError({required this.title, required this.message});
}
