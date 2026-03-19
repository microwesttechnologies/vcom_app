import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vcom_app/core/auth/login/login.services.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/common/credentials.service.dart';
import 'package:vcom_app/core/common/biometric.service.dart';
import 'package:vcom_app/core/common/session_cache.service.dart';
import 'package:vcom_app/core/common/session_state_registry.service.dart';

/// Controlador de lógica para el login
/// Maneja toda la lógica, cálculos y estado relacionado con el login
class LoginComponent extends ChangeNotifier {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final LoginService _loginService = LoginService();
  final TokenService _tokenService = TokenService();
  final SessionCacheService _sessionCache = SessionCacheService();
  final SessionStateRegistryService _sessionStateRegistry =
      SessionStateRegistryService();
  final CredentialsService _credentialsService = CredentialsService();
  final BiometricService _biometricService = BiometricService();
  bool _obscurePassword = true;
  bool _rememberCredentials = false;
  bool _biometricAvailable = false;
  bool _hasSavedCredentials = false;

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
    // El botón de huella se muestra activo si el usuario lo activó
    // explícitamente desde el menú, independiente del sensor.
    _hasSavedCredentials = await _credentialsService.isBiometricEnabled();
    // Marcar disponible si tiene credenciales guardadas (el sensor se
    // verificará cuando el usuario realmente intente autenticar).
    _biometricAvailable = _hasSavedCredentials;
    notifyListeners();
  }

  /// Autenticación biométrica → carga credenciales y hace login.
  /// Retorna true si el login se completó, false si el usuario canceló.
  /// Lanza excepción con mensaje claro si hay un error real.
  Future<bool> loginWithBiometric() async {
    if (!_hasSavedCredentials) {
      throw Exception(
        'Primero inicia sesión con usuario y contraseña\ny activa "Recordar credenciales"',
      );
    }

    bool authenticated = false;
    try {
      authenticated = await _biometricService.authenticate();
    } on PlatformException catch (e) {
      throw Exception(BiometricService.errorMessage(e));
    }

    if (!authenticated) return false; // El usuario canceló

    // Cargar credenciales vinculadas a la huella (nunca las del formulario)
    final creds = await _credentialsService.loadBiometricCredentials();
    final email = creds['email'] ?? '';
    final password = creds['password'] ?? '';

    if (email.isEmpty || password.isEmpty) {
      throw Exception('No se encontraron credenciales guardadas');
    }

    emailController.text = email;
    passwordController.text = password;
    await performLogin();
    return true;
  }

  /// Obtiene si la contraseña está oculta
  bool get obscurePassword => _obscurePassword;

  /// Obtiene si se deben recordar las credenciales
  bool get rememberCredentials => _rememberCredentials;

  /// True si el dispositivo soporta biometría Y hay credenciales guardadas
  bool get biometricEnabled => _biometricAvailable && _hasSavedCredentials;

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

  /// Valida si el email o ID de usuario es válido
  /// Acepta formato email (usuario@dominio.com) o ID (ej: MOD-8829)
  bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    if (email.contains('@') && email.contains('.')) return true;
    return email.trim().length >= 4; // ID tipo MOD-8829
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

      await _sessionCache.clearSession();
      _sessionStateRegistry.clearAll();

      // Guardar token
      _tokenService.setToken(loginResponse.token);

      // 2. Obtener permisos y datos del usuario usando el token
      final permissionsResponse = await _loginService.getPermissions(
        loginResponse.token,
      );

      // Guardar permisos del backend y datos de usuario fallback.
      _tokenService.setPermissions(permissionsResponse);
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
