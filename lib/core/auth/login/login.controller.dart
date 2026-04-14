import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vcom_app/core/auth/login/login.services.dart';
import 'package:vcom_app/core/common/biometric.service.dart';
import 'package:vcom_app/core/common/credentials.service.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/session_state_registry.service.dart';
import 'package:vcom_app/core/common/token.service.dart';

part 'login.controller.perform_login.dart';

class LoginController extends ChangeNotifier {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final LoginService _loginService;
  final TokenService _tokenService;
  final SessionCacheService _sessionCache;
  final SessionStateRegistryService _sessionStateRegistry;
  final CredentialsService _credentialsService;
  final BiometricService _biometricService;
  bool _obscurePassword = true;
  bool _rememberCredentials = false;
  bool _biometricAvailable = false;
  bool _hasSavedCredentials = false;

  LoginController({
    LoginService? loginService,
    TokenService? tokenService,
    SessionCacheService? sessionCache,
    SessionStateRegistryService? sessionStateRegistry,
    CredentialsService? credentialsService,
    BiometricService? biometricService,
  }) : _loginService = loginService ?? LoginService(),
       _tokenService = tokenService ?? TokenService(),
       _sessionCache = sessionCache ?? SessionCacheService(),
       _sessionStateRegistry =
           sessionStateRegistry ?? SessionStateRegistryService(),
       _credentialsService = credentialsService ?? CredentialsService(),
       _biometricService = biometricService ?? BiometricService() {
    emailController.addListener(notifyListeners);
    passwordController.addListener(notifyListeners);
  }

  bool get obscurePassword => _obscurePassword;
  bool get rememberCredentials => _rememberCredentials;
  bool get biometricEnabled => _biometricAvailable && _hasSavedCredentials;

  Future<void> initialize() async {
    final credentials = await _credentialsService.loadCredentials();
    if (credentials['remember'] == 'true') {
      _rememberCredentials = true;
      emailController.text = credentials['email'] ?? '';
      passwordController.text = credentials['password'] ?? '';
    }
    _hasSavedCredentials = await _credentialsService.isBiometricEnabled();
    _biometricAvailable = _hasSavedCredentials;
    notifyListeners();
  }

  Future<bool> loginWithBiometric() async {
    if (!_hasSavedCredentials) {
      throw Exception(
        'Primero inicia sesión y activa "Recordar credenciales".',
      );
    }
    try {
      final authenticated = await _biometricService.authenticate();
      if (!authenticated) return false;
    } on PlatformException catch (e) {
      throw Exception(BiometricService.errorMessage(e));
    }

    final creds = await _credentialsService.loadBiometricCredentials();
    final email = creds['email'] ?? '';
    final password = creds['password'] ?? '';
    if (email.isEmpty || password.isEmpty) {
      throw Exception('No se encontraron credenciales guardadas.');
    }

    emailController.text = email;
    passwordController.text = password;
    await performLogin();
    return true;
  }

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleRememberCredentials() {
    _rememberCredentials = !_rememberCredentials;
    notifyListeners();
  }

  bool validateFields() {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final validUser =
        email.isNotEmpty && (email.contains('@') || email.length >= 4);
    return validUser && password.length >= 6;
  }

  @override
  void dispose() {
    emailController.removeListener(notifyListeners);
    passwordController.removeListener(notifyListeners);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
