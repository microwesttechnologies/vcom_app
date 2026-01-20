import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'envirotment.dev.dart';
import 'token.service.dart';

/// Servicio global para gestionar el estado online/offline del usuario
/// Este servicio se encarga de:
/// 1. Marcar al usuario como online al iniciar sesión
/// 2. Marcar al usuario como offline al cerrar sesión
/// 3. Emitir eventos a Pusher para notificar cambios en tiempo real
class UserStatusService {
  static final UserStatusService _instance = UserStatusService._internal();
  factory UserStatusService() => _instance;
  UserStatusService._internal();

  final TokenService _tokenService = TokenService();
  
  // Configuración de Pusher
  static const String _pusherAppId = '1916206';
  static const String _pusherKey = '0f37c0c7d5d4c6e60c6e';
  static const String _pusherSecret = 'c8f3f1a1b5c8e0b8e8f8';
  static const String _pusherCluster = 'us2';

  bool _isOnline = false;

  /// Obtiene el estado actual
  bool get isOnline => _isOnline;

  /// Marca al usuario como ONLINE
  /// Se debe llamar después de un login exitoso
  Future<void> setOnline() async {
    final userId = _tokenService.getUserId();
    final userName = _tokenService.getUserName();
    final token = _tokenService.getToken();

    if (userId == null || userName == null || token == null) {
      print('⚠️ No se puede marcar como online: faltan datos del usuario');
      return;
    }

    try {
      // 1. Actualizar en el backend (para persistencia)
      final backendUrl = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatStatusOnline}');
      final backendResponse = await http.post(
        backendUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 2), // Timeout reducido a 2 segundos
        onTimeout: () {
          print('⚠️ Timeout al actualizar estado online en backend');
          return http.Response('Timeout', 408);
        },
      );

      if (backendResponse.statusCode == 200) {
        print('✅ Backend: Usuario $userName marcado como ONLINE');
      }

      // 2. Emitir a Pusher (para tiempo real) - sin esperar
      _sendToPusher(
        userId: userId,
        userName: userName,
        isOnline: true,
      ).catchError((e) {
        print('⚠️ Error al enviar a Pusher (online): $e');
      });

      _isOnline = true;
      print('✅ UserStatusService: Usuario $userName marcado como ONLINE');
    } catch (e) {
      print('❌ Error al marcar como online: $e');
    }
  }

  /// Marca al usuario como OFFLINE
  /// Se debe llamar antes de cerrar sesión o al salir de la app
  Future<void> setOffline() async {
    final userId = _tokenService.getUserId();
    final userName = _tokenService.getUserName();
    final token = _tokenService.getToken();

    if (userId == null || userName == null) {
      print('⚠️ No se puede marcar como offline: faltan datos del usuario');
      return;
    }

    try {
      // 1. Actualizar en el backend (para persistencia)
      if (token != null) {
        final backendUrl = Uri.parse('${EnvironmentDev.baseUrl}${EnvironmentDev.chatStatusOffline}');
        final backendResponse = await http.post(
          backendUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(
          const Duration(seconds: 2), // Timeout reducido a 2 segundos
          onTimeout: () {
            print('⚠️ Timeout al actualizar estado offline en backend');
            return http.Response('Timeout', 408);
          },
        );

        if (backendResponse.statusCode == 200) {
          print('✅ Backend: Usuario $userName marcado como OFFLINE');
        }
      }

      // 2. Emitir a Pusher (para tiempo real) - sin esperar
      _sendToPusher(
        userId: userId,
        userName: userName,
        isOnline: false,
      ).catchError((e) {
        print('⚠️ Error al enviar a Pusher (offline): $e');
      });

      _isOnline = false;
      print('✅ UserStatusService: Usuario $userName marcado como OFFLINE');
    } catch (e) {
      print('❌ Error al marcar como offline: $e');
    }
  }

  /// Envía el evento de cambio de estado directamente a Pusher
  Future<void> _sendToPusher({
    required String userId,
    required String userName,
    required bool isOnline,
  }) async {
    try {
      final channelName = 'users.status';
      final eventName = 'user.status.changed';
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor().toString();

      // Datos del evento
      final eventData = {
        'user_id': userId,
        'user_name': userName,
        'is_online': isOnline,
      };

      final body = jsonEncode({
        'name': eventName,
        'channel': channelName,
        'data': jsonEncode(eventData),
      });

      // Calcular MD5 del body
      final bodyBytes = utf8.encode(body);
      final bodyMd5 = md5.convert(bodyBytes).toString();

      // Calcular firma HMAC
      final authString = 'POST\n/apps/$_pusherAppId/events\nauth_key=$_pusherKey&auth_timestamp=$timestamp&auth_version=1.0&body_md5=$bodyMd5';
      final hmac = Hmac(sha256, utf8.encode(_pusherSecret));
      final digest = hmac.convert(utf8.encode(authString));
      final signature = digest.toString();

      // Construir URL con query params
      final query = 'auth_key=$_pusherKey&auth_timestamp=$timestamp&auth_version=1.0&body_md5=$bodyMd5';
      final url = Uri.parse(
        'https://api-$_pusherCluster.pusher.com/apps/$_pusherAppId/events?$query&auth_signature=$signature',
      );

      // Enviar a Pusher
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 2), // Timeout reducido a 2 segundos
        onTimeout: () {
          print('⚠️ Timeout al enviar a Pusher');
          return http.Response('Timeout', 408);
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Pusher: Evento user.status.changed (${isOnline ? 'ONLINE' : 'OFFLINE'}) emitido para $userName');
      } else {
        print('⚠️ Error al enviar a Pusher: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error al enviar evento a Pusher: $e');
    }
  }

  /// Limpia el estado (se llama al cerrar sesión)
  void clear() {
    _isOnline = false;
  }
}
