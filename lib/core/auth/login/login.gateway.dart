import 'package:vcom_app/core/models/login.model.dart';

/// Interfaz del repositorio de login (Gateway)
/// Define el contrato para la capa de datos
abstract class LoginGateway {
  /// Realiza el login y retorna la respuesta
  Future<LoginResponse> login(LoginRequest request);

  /// Obtiene los permisos y datos del usuario autenticado
  Future<PermissionsResponse> getPermissions(String token);
}
