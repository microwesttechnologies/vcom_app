import 'package:flutter/material.dart';

import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/realtime/pusher_direct.service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

/// Servicio de presencia reutilizable para gestionar el estado online/offline
/// de los usuarios en tiempo real.
/// 
/// Este servicio:
/// - Gestiona el estado del usuario actual (online/offline)
/// - Escucha cambios de estado de otros usuarios vía Pusher
/// - Mantiene un mapa actualizado de estados de usuarios
/// - Es reutilizable en toda la aplicación
/// - Maneja correctamente el ciclo de vida
class PresenceService extends ChangeNotifier {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final TokenService _tokenService = TokenService();
  final PusherDirectService _pusher = PusherDirectService();

  // Mapa de estados de usuarios: userId -> estado
  final Map<String, UserPresenceState> _userStates = {};
  
  // Estado del servicio
  bool _isInitialized = false;
  bool _isActive = false;
  String? _currentUserId;
  String? _currentUserName;

  /// Getter público para saber si está activo
  bool get isActive => _isActive;
  
  // Configuración
  static const _presenceChannel = 'presence-users.status';

  /// Obtiene el estado de un usuario específico
  UserPresenceState? getUserState(String userId) {
    return _userStates[userId];
  }

  /// Verifica si un usuario está online
  bool isUserOnline(String userId) {
    final state = _userStates[userId];
    if (state == null) {
      print('⚠️ [PresenceService] isUserOnline($userId): No hay estado en memoria');
      return false;
    }

    return state.isOnline;
  }

  /// Obtiene el texto del estado de un usuario
  String getUserStatusText(String userId) {
    if (isUserOnline(userId)) {
      return 'En línea';
    }
    
    final state = _userStates[userId];
    if (state == null) return 'Desconectado';
    
    final diff = DateTime.now().difference(state.lastSeen);
    
    if (diff.inMinutes < 5) {
      return 'Hace un momento';
    } else if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours}h';
    } else {
      return 'Hace ${diff.inDays}d';
    }
  }

  /// Inicializa el servicio de presencia
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ PresenceService ya está inicializado');
      return;
    }

    _currentUserId = _tokenService.getUserId();
    _currentUserName = _tokenService.getUserName();

    if (_currentUserId == null || _currentUserName == null) {
      throw Exception('No hay usuario autenticado');
    }

    print('👤 ========================================');
    print('👤 INICIALIZANDO PRESENCE SERVICE');
    print('👤 🔑 ID Usuario: $_currentUserId');
    print('👤 📝 Nombre Usuario: $_currentUserName');
    print('👤 ========================================');

    try {
      // Inicializar Pusher con un callback vacío si aún no está listo.
      // El ChatComponent podrá reemplazar el callback luego.
      await _pusher.init(onMessage: (_) {});

      // Suscribirse al canal de presencia
      await _pusher.subscribe(
        _presenceChannel,
        keepExisting: true,
        onSubscriptionSucceeded: _handleSubscriptionSucceeded,
        onMemberAdded: _handleMemberAdded,
        onMemberRemoved: _handleMemberRemoved,
      );

      _isInitialized = true;
      print('✅ PresenceService inicializado correctamente');
    } catch (e) {
      print('❌ Error inicializando PresenceService: $e');
      rethrow;
    }
  }

  /// Activa el servicio (marca como online y comienza heartbeat)
  Future<void> activate() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isActive) {
      print('⚠️ PresenceService ya está activo');
      return;
    }

    print('🟢 Activando PresenceService...');
    _isActive = true;
    print('✅ PresenceService activado');
  }

  /// Desactiva el servicio (marca como offline y detiene heartbeat)
  Future<void> deactivate() async {
    if (!_isActive) {
      print('⚠️ PresenceService ya está inactivo');
      return;
    }

    print('🔴 Desactivando PresenceService...');

    try {
      await _pusher.unsubscribe(_presenceChannel);

      _isActive = false;
      print('✅ PresenceService desactivado');
    } catch (e) {
      print('❌ Error desactivando PresenceService: $e');
      // No relanzar el error en deactivate
    }
  }

  void _handleSubscriptionSucceeded(dynamic data) {
    try {
      final decoded = data is Map ? data : {};
      final presence = decoded['presence'] as Map?;
      final hash = presence?['hash'] as Map?;

      if (hash == null) return;

      hash.forEach((userId, userInfo) {
        _upsertUserState(
          userId: userId.toString(),
          userInfo: userInfo,
          isOnline: true,
        );
      });

      notifyListeners();
    } catch (e) {
      print('⚠️ Error procesando subscription_succeeded: $e');
    }
  }

  void _handleMemberAdded(PusherMember member) {
    if (member.userId == _currentUserId) return;
    _upsertUserState(
      userId: member.userId,
      userInfo: member.userInfo,
      isOnline: true,
    );
    notifyListeners();
  }

  void _handleMemberRemoved(PusherMember member) {
    if (member.userId == _currentUserId) return;
    _upsertUserState(
      userId: member.userId,
      userInfo: member.userInfo,
      isOnline: false,
    );
    notifyListeners();
  }

  void _upsertUserState({
    required String userId,
    required dynamic userInfo,
    required bool isOnline,
  }) {
    final userName = _extractUserName(userInfo);
    _userStates[userId] = UserPresenceState(
      userId: userId,
      userName: userName ?? userId,
      isOnline: isOnline,
      lastSeen: DateTime.now(),
    );

    // Si el backend envía el UUID dentro de userInfo, mapearlo también.
    final altId = _extractUserId(userInfo);
    if (altId != null && altId != userId) {
      _userStates[altId] = UserPresenceState(
        userId: altId,
        userName: userName ?? altId,
        isOnline: isOnline,
        lastSeen: DateTime.now(),
      );
    }
  }

  String? _extractUserName(dynamic userInfo) {
    if (userInfo is Map) {
      final name = userInfo['name'] ?? userInfo['user_name'] ?? userInfo['name_user'];
      if (name is String && name.isNotEmpty) {
        return name;
      }
    }
    if (userInfo is String && userInfo.isNotEmpty) {
      return userInfo;
    }
    return null;
  }

  String? _extractUserId(dynamic userInfo) {
    if (userInfo is Map) {
      final id = userInfo['id_user'] ?? userInfo['id'] ?? userInfo['uuid'];
      if (id != null) {
        return id.toString();
      }
    }
    return null;
  }

  /// Limpia el servicio
  Future<void> clear() async {
    await deactivate();
    _userStates.clear();
    _isInitialized = false;
    _currentUserId = null;
    _currentUserName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _userStates.clear();
    super.dispose();
  }
}

/// Clase para representar el estado de presencia de un usuario
class UserPresenceState {
  final String userId;
  final String userName;
  final bool isOnline;
  final DateTime lastSeen;

  UserPresenceState({
    required this.userId,
    required this.userName,
    required this.isOnline,
    required this.lastSeen,
  });

  @override
  String toString() {
    return 'UserPresenceState{userId: $userId, userName: $userName, isOnline: $isOnline, lastSeen: $lastSeen}';
  }
}
