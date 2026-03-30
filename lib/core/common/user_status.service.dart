/// Servicio global para gestionar el estado online/offline del usuario.
///
/// El modulo de chat fue retirado de la app, por lo que este servicio
/// conserva una API compatible sin dependencias de presencia en tiempo real.
class UserStatusService {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;
  UserStatusService._internal();

  bool _isOnline = false;

  /// Obtiene el estado actual.
  bool get isOnline => _isOnline;

  /// Marca al usuario como ONLINE.
  Future<void> setOnline() async {
    _isOnline = true;
  }

  /// Marca al usuario como OFFLINE.
  Future<void> setOffline() async {
    _isOnline = false;
  }

  /// Limpia el estado (se llama al cerrar sesion).
  Future<void> clear() async {
    _isOnline = false;
  }
}
