part of 'login.controller.dart';

extension LoginControllerPerformLogin on LoginController {
  Future<void> performLogin() async {
    if (!validateFields()) {
      throw Exception('Por favor ingrese un correo/ID y contraseña válidos.');
    }

    final email = emailController.text.trim();
    final password = passwordController.text;
    final login = await _loginService.executeLogin(email, password);

    await _sessionCache.clearSession();
    _sessionStateRegistry.clearAll();
    _tokenService.setToken(login.token);

    final loginUser = login.user;
    if (loginUser != null && loginUser.name.trim().isNotEmpty) {
      _tokenService.setUserName(loginUser.name.trim());
    }
    if (loginUser != null && loginUser.id.trim().isNotEmpty) {
      _tokenService.setUserId(loginUser.id.trim());
    }

    final permissions = await _loginService.getPermissions(login.token);
    _tokenService.setPermissions(permissions);
    if (permissions.user.name.trim().isNotEmpty) {
      _tokenService.setUserName(permissions.user.name.trim());
    }
    if (permissions.user.id.trim().isNotEmpty) {
      _tokenService.setUserId(permissions.user.id.trim());
    }

    await _credentialsService.saveCredentials(
      remember: _rememberCredentials,
      email: email,
      password: password,
    );
  }
}
