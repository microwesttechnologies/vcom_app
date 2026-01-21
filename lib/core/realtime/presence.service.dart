import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/realtime/pusher_direct.service.dart';

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
  Timer? _heartbeatTimer;

  /// Getter público para saber si está activo
  bool get isActive => _isActive;
  
  // Configuración
  static const _heartbeatInterval = Duration(seconds: 30);
  static const _offlineThreshold = Duration(minutes: 2);

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
    
    // Verificar si el estado es reciente
    final now = DateTime.now();
    final diff = now.difference(state.lastSeen);
    final isOnline = state.isOnline && diff < _offlineThreshold;
    
    print('👤 [PresenceService] isUserOnline($userId): $isOnline (state.isOnline=${state.isOnline}, diff=${diff.inSeconds}s)');
    
    return isOnline;
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
      // NOTA: No inicializamos Pusher aquí porque ChatComponent ya lo hace
      // con un callback unificado que delega a este servicio
      
      // Suscribirse al canal de presencia
      await _pusher.subscribe('users.status');

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

    try {
      // Marcar como online
      await _setOnline();

      // Iniciar heartbeat
      _startHeartbeat();

      _isActive = true;
      print('✅ PresenceService activado');
    } catch (e) {
      print('❌ Error activando PresenceService: $e');
      rethrow;
    }
  }

  /// Desactiva el servicio (marca como offline y detiene heartbeat)
  Future<void> deactivate() async {
    if (!_isActive) {
      print('⚠️ PresenceService ya está inactivo');
      return;
    }

    print('🔴 Desactivando PresenceService...');

    try {
      // Detener heartbeat
      _stopHeartbeat();

      // Marcar como offline
      await _setOffline();

      _isActive = false;
      print('✅ PresenceService desactivado');
    } catch (e) {
      print('❌ Error desactivando PresenceService: $e');
      // No relanzar el error en deactivate
    }
  }

  /// Marca al usuario actual como online
  Future<void> _setOnline() async {
    if (_currentUserId == null) return;

    try {
      print('🟢 ========================================');
      print('🟢 MARCANDO COMO ONLINE');
      print('🟢 🔑 ID Usuario: $_currentUserId');
      print('🟢 📝 Nombre Usuario: $_currentUserName');
      print('🟢 ========================================');

      // 1. Actualizar en el backend
      final url = Uri.parse('${EnvironmentDev.baseUrl}/api/v1/chat/status/online');
      final token = _tokenService.getToken();
      
      print('🟢 Enviando a backend: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout al marcar online en backend');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        print('✅ Backend: Usuario marcado como online');
        print('✅ Response: ${response.body}');
        
        // Verificar que el backend devuelva el usuario correcto
        try {
          final responseData = jsonDecode(response.body);
          if (responseData['user_id'] != null && responseData['user_id'] != _currentUserId) {
            print('🚨 ¡ALERTA! El backend devolvió un ID diferente:');
            print('🚨 ID esperado: $_currentUserId');
            print('🚨 ID recibido: ${responseData['user_id']}');
          }
          if (responseData['user_name'] != null && responseData['user_name'] != _currentUserName) {
            print('🚨 ¡ALERTA! El backend devolvió un nombre diferente:');
            print('🚨 Nombre esperado: $_currentUserName');
            print('🚨 Nombre recibido: ${responseData['user_name']}');
          }
        } catch (e) {
          // Si no hay datos de verificación en la respuesta, continuar
        }
      } else {
        print('❌ Backend error: ${response.statusCode}');
        print('❌ Response: ${response.body}');
      }

      // 2. Actualizar estado local
      _userStates[_currentUserId!] = UserPresenceState(
        userId: _currentUserId!,
        userName: _currentUserName!,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      
      print('✅ Estado local actualizado para: $_currentUserId');

      // 3. Emitir a Pusher
      final pusherData = {
        'type': 'user.status.changed',
        'user_id': _currentUserId,
        'user_name': _currentUserName,
        'is_online': true,
        'last_seen': DateTime.now().toIso8601String(),
      };
      
      print('📤 Emitiendo a Pusher:');
      print('📤 Canal: users.status');
      print('📤 Data: $pusherData');
      
      await _pusher.sendMessage(
        channelName: 'users.status',
        eventName: 'user.status.changed',
        data: pusherData,
      );

      print('✅ Usuario marcado como online');
      notifyListeners();
    } catch (e) {
      print('⚠️ Error marcando como online: $e');
    }
  }

  /// Marca al usuario actual como offline
  Future<void> _setOffline() async {
    if (_currentUserId == null) return;

    try {
      print('🔴 Marcando como offline...');

      // 1. Actualizar en el backend
      final url = Uri.parse('${EnvironmentDev.baseUrl}/api/v1/chat/status/offline');
      final token = _tokenService.getToken();
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Timeout al marcar offline en backend');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode == 200) {
        print('✅ Backend: Usuario marcado como offline');
      }

      // 2. Actualizar estado local
      _userStates[_currentUserId!] = UserPresenceState(
        userId: _currentUserId!,
        userName: _currentUserName!,
        isOnline: false,
        lastSeen: DateTime.now(),
      );

      // 3. Emitir a Pusher
      await _pusher.sendMessage(
        channelName: 'users.status',
        eventName: 'user.status.changed',
        data: {
          'type': 'user.status.changed',
          'user_id': _currentUserId,
          'user_name': _currentUserName,
          'is_online': false,
          'last_seen': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Usuario marcado como offline');
      notifyListeners();
    } catch (e) {
      print('⚠️ Error marcando como offline: $e');
    }
  }

  /// Inicia el heartbeat para mantener el estado online
  void _startHeartbeat() {
    _stopHeartbeat(); // Asegurar que no hay timer anterior
    
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (timer) {
      if (_isActive && _currentUserId != null) {
        print('💓 Heartbeat...');
        _setOnline().catchError((e) {
          print('⚠️ Error en heartbeat: $e');
        });
      }
    });

    print('💓 Heartbeat iniciado (cada $_heartbeatInterval)');
  }

  /// Detiene el heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    print('💓 Heartbeat detenido');
  }

  /// Maneja eventos de presencia de Pusher
  /// NOTA: Este método es público para permitir delegación desde ChatComponent
  void handlePresenceEvent(Map<String, dynamic> data) {
    try {
      print('👤 [PresenceService] handlePresenceEvent llamado');
      print('👤 [PresenceService] Data: $data');
      
      final type = data['type'] as String?;

      // Solo procesar eventos de cambio de estado
      if (type != 'user.status.changed') {
        print('⚠️ [PresenceService] Tipo incorrecto: $type');
        return;
      }

      final userId = data['user_id'] as String?;
      final userName = data['user_name'] as String?;
      final isOnline = data['is_online'] as bool?;
      final lastSeenStr = data['last_seen'] as String?;

      if (userId == null || userName == null || isOnline == null) {
        print('⚠️ [PresenceService] Evento de presencia incompleto');
        return;
      }

      // Ignorar eventos del usuario actual
      if (userId == _currentUserId) {
        print('👤 [PresenceService] Ignorando evento propio');
        return;
      }

      print('👤 [PresenceService] Cambio de estado: $userName ($userId) -> ${isOnline ? "ONLINE" : "OFFLINE"}');

      // Actualizar estado local
      _userStates[userId] = UserPresenceState(
        userId: userId,
        userName: userName,
        isOnline: isOnline,
        lastSeen: lastSeenStr != null 
            ? DateTime.parse(lastSeenStr)
            : DateTime.now(),
      );

      print('👤 [PresenceService] Estado actualizado en memoria');
      print('👤 [PresenceService] Total usuarios en memoria: ${_userStates.length}');
      print('👤 [PresenceService] Llamando notifyListeners()...');
      
      notifyListeners();
      
      print('✅ [PresenceService] notifyListeners() completado');
    } catch (e, stackTrace) {
      print('❌ [PresenceService] Error procesando evento de presencia: $e');
      print('❌ [PresenceService] Stack: $stackTrace');
    }
  }

  /// Sincroniza los estados de usuarios con el backend
  Future<void> syncUserStates(List<String> userIds) async {
    if (userIds.isEmpty) return;

    try {
      print('🔄 Sincronizando estados de ${userIds.length} usuarios...');

      final url = Uri.parse('${EnvironmentDev.baseUrl}/api/v1/chat/users/status');
      final token = _tokenService.getToken();

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_ids': userIds,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> statuses = data['statuses'] ?? [];

        for (var status in statuses) {
          final userId = status['user_id']?.toString();
          final userName = status['user_name'] as String?;
          final isOnline = status['is_online'] as bool? ?? false;
          final lastSeenStr = status['last_seen'] as String?;

          if (userId != null && userName != null) {
            _userStates[userId] = UserPresenceState(
              userId: userId,
              userName: userName,
              isOnline: isOnline,
              lastSeen: lastSeenStr != null
                  ? DateTime.parse(lastSeenStr)
                  : DateTime.now(),
            );
          }
        }

        print('✅ Estados sincronizados');
        notifyListeners();
      }
    } catch (e) {
      print('⚠️ Error sincronizando estados: $e');
    }
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
    _stopHeartbeat();
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
