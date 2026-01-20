import 'package:flutter/material.dart';
import 'package:vcom_app/core/auth/login/login.services.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/credentials.service.dart';

/// Controlador de lógica para el login
/// Maneja toda la lógica, cálculos y estado relacionado con el login
class LoginComponent extends ChangeNotifier {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final LoginService _loginService = LoginService();
  final TokenService _tokenService = TokenService();
  final CredentialsService _credentialsService = CredentialsService();
  bool _obscurePassword = true;
  bool _rememberCredentials = false;

  /// Constructor
  LoginComponent()
      : emailController = TextEditingController(),
        passwordController = TextEditingController() {
    // Escuchar cambios en los controladores para actualizar el estado
    emailController.addListener(_onEmailChanged);
    passwordController.addListener(_onPasswordChanged);
  }

  void _onEmailChanged() {
    notifyListeners();
  }

  void _onPasswordChanged() {
    notifyListeners();
  }

  /// Inicializa el componente cargando las credenciales guardadas
  Future<void> initialize() async {
    await _loadSavedCredentials();
    notifyListeners(); // Notificar después de cargar
  }

  /// Obtiene si la contraseña está oculta
  bool get obscurePassword => _obscurePassword;

  /// Obtiene si se deben recordar las credenciales
  bool get rememberCredentials => _rememberCredentials;

  /// Alterna la visibilidad de la contraseña
  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  /// Alterna el estado de recordar credenciales
  void toggleRememberCredentials() {
    _rememberCredentials = !_rememberCredentials;
    notifyListeners();
  }

  /// Carga las credenciales guardadas
  Future<void> _loadSavedCredentials() async {
    final credentials = await _credentialsService.loadCredentials();
    
    if (credentials['remember'] == 'true') {
      _rememberCredentials = true;
      if (credentials['email'] != null) {
        emailController.text = credentials['email']!;
      }
      if (credentials['password'] != null) {
        passwordController.text = credentials['password']!;
      }
    }
  }

  /// Obtiene el email limpio (sin espacios)
  String getEmail() {
    return emailController.text.trim();
  }

  /// Obtiene la contraseña
  String getPassword() {
    return passwordController.text;
  }

  /// Valida si el email es válido
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    return email.contains('@') && email.contains('.');
  }

  /// Valida si la contraseña es válida
  bool isValidPassword(String password) {
    return password.length >= 6;
  }

  /// Valida todos los campos del formulario
  bool validateFields() {
    final email = getEmail();
    final password = getPassword();
    return isValidEmail(email) && isValidPassword(password);
  }

  /// Limpia todos los campos
  void clearFields() {
    emailController.clear();
    passwordController.clear();
  }

  /// Realiza el login
  Future<void> performLogin() async {
    if (!validateFields()) {
      throw Exception('Por favor ingrese un correo y contraseña válidos');
    }

    final email = getEmail();
    final password = getPassword();

    try {
      // 1. Realizar login y obtener token
      final loginResponse = await _loginService.executeLogin(email, password);
      
      // Guardar token
      _tokenService.setToken(loginResponse.token);
      
      // 2. Obtener permisos y datos del usuario usando el token
      final permissionsResponse = await _loginService.getPermissions(loginResponse.token);
      
      // Guardar datos del usuario
      _tokenService.setRole(permissionsResponse.user.role ?? '');
      _tokenService.setUserName(permissionsResponse.user.name);
      _tokenService.setUserId(permissionsResponse.user.id);
      
      // Guardar credenciales si el usuario marcó "Recordar credenciales"
      await _credentialsService.saveCredentials(
        remember: _rememberCredentials,
        email: email,
        password: password,
      );

      // NOTA: El estado online/offline se maneja en el módulo de chat
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Libera los recursos
  @override
  void dispose() {
    emailController.removeListener(_onEmailChanged);
    passwordController.removeListener(_onPasswordChanged);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

