import 'package:vcom_app/core/realtime/presence.service.dart';

/// Servicio global para gestionar el estado online/offline del usuario
/// 
/// NOTA: Este servicio ahora usa PresenceService internamente.
/// PresenceService es el servicio principal que maneja la presencia en tiempo real.
/// 
/// UserStatusService mantiene la API compatible con el código existente,
/// pero delega toda la lógica al PresenceService.
class UserStatusService {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;
  UserStatusService._internal();

  final PresenceService _presence = PresenceService();

  /// Obtiene el estado actual
  bool get isOnline => _presence.isActive;

  /// Marca al usuario como ONLINE
  /// Se debe llamar después de un login exitoso
  Future<void> setOnline() async {
    try {
      // Inicializar y activar el servicio de presencia
      await _presence.initialize();
      await _presence.activate();
      print('✅ UserStatusService: Usuario marcado como ONLINE vía PresenceService');
    } catch (e) {
      print('❌ UserStatusService: Error al marcar como online: $e');
    }
  }

  /// Marca al usuario como OFFLINE
  /// Se debe llamar antes de cerrar sesión o al salir de la app
  Future<void> setOffline() async {
    try {
      // Desactivar el servicio de presencia
      await _presence.deactivate();
      print('✅ UserStatusService: Usuario marcado como OFFLINE vía PresenceService');
    } catch (e) {
      print('❌ UserStatusService: Error al marcar como offline: $e');
    }
  }

  /// Limpia el estado (se llama al cerrar sesión)
  Future<void> clear() async {
    await _presence.clear();
  }

  /// Obtiene el servicio de presencia subyacente
  /// Útil para acceso directo a funcionalidades avanzadas
  PresenceService get presenceService => _presence;
}
