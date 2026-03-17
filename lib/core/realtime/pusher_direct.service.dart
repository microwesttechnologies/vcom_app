import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:vcom_app/core/common/envirotment.dev.dart';
import 'package:vcom_app/core/common/token.service.dart';

/// Servicio de Pusher directo (sin backend de Laravel Broadcasting)
/// Basado en la app de prueba que funciona correctamente
class PusherDirectService {
  static final PusherDirectService _instance = PusherDirectService._internal();
  factory PusherDirectService() => _instance;
  PusherDirectService._internal();

  final TokenService _tokenService = TokenService();

  // Credenciales de Pusher
  static const _pusherAppId = '2103188';
  static const _pusherKey = '3c8a9e21ae7de775c159';
  static const _pusherSecret = 'cb6a44d031d292dc8cd9';
  static const _pusherCluster = 'eu';
  static const _authEndpointPath = '/api/v1/broadcasting/auth';
  static const _authEndpointFallbackPath = '/broadcasting/auth';

  final _pusher = PusherChannelsFlutter.getInstance();
  
  bool _initialized = false;
  String? _currentChannel;
  void Function(Map<String, dynamic>)? _onMessageCallback;

  /// Inicializa Pusher
  Future<void> init({
    required void Function(Map<String, dynamic>) onMessage,
  }) async {
    // Permitir actualizar el callback aunque ya esté inicializado
    _onMessageCallback = onMessage;

    if (_initialized) {
      print('⚠️ Pusher ya está inicializado');
      return;
    }

    print('📡 ========================================');
    print('📡 INICIALIZANDO PUSHER DIRECTO');
    print('📡 ========================================');
    print('📡 App ID: $_pusherAppId');
    print('📡 Key: $_pusherKey');
    print('📡 Cluster: $_pusherCluster');

    try {
      await _pusher.init(
        apiKey: _pusherKey,
        cluster: _pusherCluster,
        onAuthorizer: _authorize,
        onConnectionStateChange: (currentState, previousState) {
          print('🔌 Pusher: $previousState → $currentState');
          if (currentState == 'CONNECTED') {
            print('✅ ¡CONECTADO A PUSHER!');
          }
        },
        onEvent: _handleEvent,
        onError: (message, code, error) {
          print('❌ Error Pusher: $message (código: $code)');
        },
      );

      print('⏳ Conectando a Pusher...');
      await _pusher.connect();
      
      _initialized = true;
      
      print('✅ ========================================');
      print('✅ PUSHER INICIALIZADO EXITOSAMENTE');
      print('✅ ========================================');
    } catch (e, stackTrace) {
      print('❌ Error inicializando Pusher: $e');
      print('❌ Stack: $stackTrace');
      rethrow;
    }
  }

  Future<dynamic> _authorize(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    try {
      final token = _tokenService.getToken();
      final response = await http.post(
        Uri.parse('${EnvironmentDev.baseUrl}$_authEndpointPath'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: {
          'socket_id': socketId,
          'channel_name': channelName,
        },
      ).timeout(const Duration(seconds: 10));
      _tokenService.handleUnauthorizedStatus(response.statusCode);

      if (response.statusCode == 200) {
        return _sanitizeAuthResponse(response.body);
      }

      if (response.statusCode == 404) {
        final fallbackResponse = await http.post(
          Uri.parse('${EnvironmentDev.baseUrl}$_authEndpointFallbackPath'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
          body: {
            'socket_id': socketId,
            'channel_name': channelName,
          },
        ).timeout(const Duration(seconds: 10));
        _tokenService.handleUnauthorizedStatus(fallbackResponse.statusCode);

        if (fallbackResponse.statusCode == 200) {
          return _sanitizeAuthResponse(fallbackResponse.body);
        }

        print('❌ Error auth Pusher (fallback): ${fallbackResponse.statusCode}');
        print('❌ Body: ${fallbackResponse.body}');
        return {};
      }

      print('❌ Error auth Pusher: ${response.statusCode}');
      print('❌ Body: ${response.body}');
    } catch (e) {
      print('❌ Error en authorizer: $e');
    }

    return {};
  }

  Map<String, dynamic> _sanitizeAuthResponse(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return {};
    }

    final channelDataRaw = decoded['channel_data'];
    if (channelDataRaw is String && channelDataRaw.isNotEmpty) {
      try {
        final channelData = jsonDecode(channelDataRaw);
        if (channelData is Map<String, dynamic>) {
          final userInfo = channelData['user_info'];
          if (userInfo == true || userInfo == null) {
            channelData['user_info'] = {
              'name': _tokenService.getUserName(),
              'id_user': _tokenService.getUserId(),
            };
            decoded['channel_data'] = jsonEncode(channelData);
          }
        }
      } catch (_) {
        // Si channel_data no es JSON válido, mantener la respuesta original.
      }
    }

    return decoded;
  }

  /// Se suscribe a un canal
  Future<void> subscribe(
    String channelName, {
    bool keepExisting = false,
    Function(dynamic data)? onSubscriptionSucceeded,
    Function(PusherMember member)? onMemberAdded,
    Function(PusherMember member)? onMemberRemoved,
    Function(PusherEvent event)? onEvent,
    Function(int subscriptionCount)? onSubscriptionCount,
  }) async {
    if (!_initialized) {
      throw Exception('Pusher no está inicializado. Llama a init() primero.');
    }

    // Si ya estamos suscritos a este canal, no hacer nada
    if (_currentChannel == channelName) {
      print('⚠️ Ya estás suscrito al canal: $channelName');
      return;
    }

    // Desuscribirse del canal anterior si existe
    if (!keepExisting && _currentChannel != null) {
      try {
        await _pusher.unsubscribe(channelName: _currentChannel!);
        print('🔄 Desuscrito de: $_currentChannel');
      } catch (e) {
        print('⚠️ Error al desuscribirse: $e');
      }
    }

    print('📡 ========================================');
    print('📡 SUSCRIBIÉNDOSE AL CANAL');
    print('📡 Canal: $channelName');
    print('📡 ========================================');

    try {
      await _pusher.subscribe(
        channelName: channelName,
        onSubscriptionSucceeded: onSubscriptionSucceeded,
        onMemberAdded: onMemberAdded,
        onMemberRemoved: onMemberRemoved,
        onEvent: onEvent,
        onSubscriptionCount: onSubscriptionCount,
      );
      if (!keepExisting) {
        _currentChannel = channelName;
      }
      
      print('✅ ========================================');
      print('✅ SUSCRITO EXITOSAMENTE');
      print('✅ Canal: $channelName');
      print('✅ ========================================');
    } catch (e) {
      // Si ya está suscrito, ignorar el error
      if (e.toString().contains('Already subscribed')) {
        print('⚠️ Ya estaba suscrito, continuando...');
        if (!keepExisting) {
          _currentChannel = channelName;
        }
      } else {
        print('❌ Error suscribiéndose: $e');
        rethrow;
      }
    }
  }

  /// Envía un mensaje directamente a Pusher usando su REST API
  Future<void> sendMessage({
    required String channelName,
    required String eventName,
    required Map<String, dynamic> data,
  }) async {
    print('📤 ========================================');
    print('📤 ENVIANDO MENSAJE A PUSHER');
    print('📤 Canal: $channelName');
    print('📤 Evento: $eventName');
    print('📤 Datos: $data');

    // 1. Crear el payload
    final payload = {
      'name': eventName,
      'channels': [channelName],
      'data': jsonEncode(data),
    };

    final body = jsonEncode(payload);

    // 2. Calcular el MD5 del body
    final bodyMd5 = md5.convert(utf8.encode(body)).toString();

    // 3. Obtener timestamp actual
    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();

    // 4. Crear el query string
    final query = [
      'auth_key=$_pusherKey',
      'auth_timestamp=$timestamp',
      'auth_version=1.0',
      'body_md5=$bodyMd5',
    ].join('&');

    // 5. Crear la firma HMAC SHA256
    final stringToSign = 'POST\n/apps/$_pusherAppId/events\n$query';
    final signature = Hmac(sha256, utf8.encode(_pusherSecret))
        .convert(utf8.encode(stringToSign))
        .toString();

    // 6. Construir la URL final
    final url = Uri.parse(
      'https://api-$_pusherCluster.pusher.com/apps/$_pusherAppId/events?$query&auth_signature=$signature',
    );

    print('📤 URL: $url');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al enviar mensaje a Pusher');
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ ========================================');
        print('✅ MENSAJE ENVIADO A PUSHER');
        print('✅ Status: ${response.statusCode}');
        print('✅ ========================================');
      } else {
        print('❌ Error Pusher: ${response.statusCode}');
        print('❌ Body: ${response.body}');
        throw Exception('Error al enviar mensaje: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ ========================================');
      print('❌ ERROR ENVIANDO MENSAJE');
      print('❌ Error: $e');
      print('❌ ========================================');
      rethrow;
    }
  }

  /// Maneja los eventos de Pusher
  void _handleEvent(PusherEvent event) {
    final eventName = event.eventName.toLowerCase();

    // Ignorar eventos del sistema de Pusher
    if (eventName.startsWith('pusher:') || eventName.startsWith('pusher_internal:')) {
      print('⏭️ Ignorando evento del sistema: $eventName');
      return;
    }

    print('🔔 ========================================');
    print('🔔 EVENTO RECIBIDO DE PUSHER');
    print('🔔 ========================================');
    print('🔔 Canal: ${event.channelName}');
    print('🔔 Evento: ${event.eventName}');
    print('🔔 Datos raw: ${event.data}');

    // Si no hay callback, ignorar
    if (_onMessageCallback == null) {
      print('⚠️ No hay callback configurado');
      return;
    }

    // Si no hay datos, ignorar
    if (event.data == null || event.data.toString().isEmpty) {
      print('⚠️ No hay datos en el evento');
      return;
    }

    try {
      // Parsear los datos
      final decoded = jsonDecode(event.data);
      
      if (decoded is! Map<String, dynamic>) {
        print('⚠️ Los datos no son un mapa válido');
        return;
      }

      print('✅ Datos parseados: $decoded');
      
      // Llamar al callback con los datos
      _onMessageCallback!(decoded);
      
      print('✅ ========================================');
      print('✅ EVENTO PROCESADO EXITOSAMENTE');
      print('✅ ========================================');
    } catch (e, stackTrace) {
      print('❌ Error procesando evento: $e');
      print('❌ Stack: $stackTrace');
    }
  }

  /// Desconecta de Pusher
  Future<void> disconnect() async {
    try {
      await _pusher.disconnect();
      _initialized = false;
      _currentChannel = null;
      print('✅ Desconectado de Pusher');
    } catch (e) {
      print('⚠️ Error al desconectar: $e');
    }
  }

  /// Desuscribe un canal específico
  Future<void> unsubscribe(String channelName) async {
    try {
      await _pusher.unsubscribe(channelName: channelName);
      if (_currentChannel == channelName) {
        _currentChannel = null;
      }
      print('✅ Desuscrito de: $channelName');
    } catch (e) {
      print('⚠️ Error al desuscribirse de $channelName: $e');
    }
  }
}
