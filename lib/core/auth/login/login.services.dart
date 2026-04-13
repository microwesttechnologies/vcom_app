import 'package:vcom_app/core/models/login.model.dart';

import 'login.gateway.dart';
import 'login_http.gateway.dart';

class LoginService {
  final LoginGateway _gateway;

  LoginService({LoginGateway? gateway})
    : _gateway = gateway ?? LoginHttpGateway();

  Future<LoginResponse> executeLogin(String email, String password) async {
    return _gateway.login(LoginRequest(email: email, password: password));
  }

  Future<PermissionsResponse> getPermissions(String token) async {
    return _gateway.getPermissions(token);
  }
}
