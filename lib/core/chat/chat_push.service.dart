import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcom_app/core/chat/chat_api.service.dart';
import 'package:vcom_app/core/chat/chat_socket.service.dart';
import 'package:vcom_app/core/chat/chat_ui_state.service.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/chat/chat_message.model.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';

final FlutterLocalNotificationsPlugin _backgroundLocalNotifications =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _backgroundChatChannel =
    AndroidNotificationChannel(
      'chat_messages',
      'Mensajes de chat',
      description: 'Notificaciones push del modulo de chat',
      importance: Importance.high,
    );

bool _backgroundNotificationsReady = false;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb || Platform.isWindows) return;
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  await _ensureBackgroundNotificationsConfigured();
  await _showBackgroundNotification(message);
}

@pragma('vm:entry-point')
Future<void> _ensureBackgroundNotificationsConfigured() async {
  if (_backgroundNotificationsReady) return;

  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await _backgroundLocalNotifications.initialize(initSettings);

  final androidPlatform = _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlatform?.createNotificationChannel(_backgroundChatChannel);
  await _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>()
      ?.requestPermissions(alert: true, badge: true, sound: true);
  _backgroundNotificationsReady = true;
}

@pragma('vm:entry-point')
Future<void> _showBackgroundNotification(RemoteMessage message) async {
  final data = Map<String, dynamic>.from(message.data);
  final title =
      message.notification?.title ??
      (data['title']?.toString().trim().isNotEmpty == true
          ? data['title'].toString().trim()
          : 'Nuevo mensaje');
  final body =
      message.notification?.body ??
      (data['body']?.toString().trim().isNotEmpty == true
          ? data['body'].toString().trim()
          : (data['content'] ?? 'Tienes un mensaje nuevo').toString());

  await _backgroundLocalNotifications.show(
    _resolveNotificationId(data),
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        _backgroundChatChannel.id,
        _backgroundChatChannel.name,
        channelDescription: _backgroundChatChannel.description,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

int _resolveNotificationId(Map<String, dynamic> data) {
  final conversationId = (data['conversation_id'] ?? '').toString().trim();
  if (conversationId.isEmpty) {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
  return conversationId.hashCode;
}

class ChatPushService {
  static final ChatPushService _instance = ChatPushService._internal();
  factory ChatPushService() => _instance;
  ChatPushService._internal();

  static const AndroidNotificationChannel _chatChannel =
      AndroidNotificationChannel(
        'chat_messages',
        'Mensajes de chat',
        description: 'Notificaciones push del modulo de chat',
        importance: Importance.high,
      );

  static const String _cachedPushTokenKey = 'chat_push_token';
  static const String _cachedPushUserIdKey = 'chat_push_user_id';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final ChatApiService _chatApi = ChatApiService();
  final ChatUiStateService _chatUiStateService = ChatUiStateService();
  final TokenService _tokenService = TokenService();

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketTraySubscription;
  final Map<int, DateTime> _trayDedupeByMessageId = {};

  Future<void> initialize() async {
    if (kIsWeb || Platform.isWindows) return;

    await _tokenService.initialize();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('Push chat deshabilitado temporalmente: $e');
      return;
    }
    final messaging = FirebaseMessaging.instance;

    if (!_initialized) {
      await _configureLocalNotifications();
      ChatSocketService.afterChatUiClosed =
          () => ChatPushService().resumeInboundSocketAfterChatClosed();
      _socketTraySubscription ??=
          ChatSocketService().events.listen(_onChatSocketTrayEvent);
      _onMessageSubscription = FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
      );
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerTokenWithBackend(token)),
      );
      _initialized = true;
    }

    final androidNotifications = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.requestNotificationsPermission();

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint(
        'Push chat: permisos de notificacion denegados por el usuario.',
      );
      return;
    }

    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = _tokenService.getToken();
    if (token == null || token.isEmpty) return;

    unawaited(resumeInboundSocketAfterChatClosed());

    try {
      final fcmToken = await messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('FCM token obtenido: $fcmToken');
        await _registerTokenWithBackend(fcmToken);
      }
    } catch (e) {
      final msg = e.toString();
      debugPrint('Push chat: no se pudo obtener FCM token: $e');
      if (msg.contains('AUTHENTICATION_FAILED')) {
        debugPrint(
          'Push chat: en Firebase Console, app Android com.example.vcom_app — '
          'agrega SHA-1/SHA-256 del keystore debug, descarga google-services.json '
          'y colócalo en android/app/.',
        );
      }
    }

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (kIsWeb || Platform.isWindows) return;

    final prefs = await SharedPreferences.getInstance();
    final cachedToken = prefs.getString(_cachedPushTokenKey);
    try {
      if (cachedToken != null && cachedToken.isNotEmpty) {
        await _chatApi.unregisterPushToken(cachedToken);
      }
    } catch (e) {
      debugPrint('No fue posible eliminar push token remoto: $e');
    } finally {
      await _clearCachedPushState(prefs);
    }
  }

  Future<void> dispose() async {
    ChatSocketService.afterChatUiClosed = null;
    await _socketTraySubscription?.cancel();
    _socketTraySubscription = null;
    await _onMessageSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    _onMessageSubscription = null;
    _tokenRefreshSubscription = null;
    _initialized = false;
  }

  /// Sin `chat.screen.open`: mantiene el WS vivo para `message.new` y avisos locales fuera del chat.
  Future<void> resumeInboundSocketAfterChatClosed() async {
    if (kIsWeb || Platform.isWindows) return;

    await _tokenService.initialize();
    final token = _tokenService.getToken();
    if (token == null || token.isEmpty) return;

    final socket = ChatSocketService();
    if (socket.isConnected) return;

    try {
      await socket.connect(token);
    } catch (e) {
      debugPrint('Chat push: no se reconecto el socket tras salir del chat: $e');
    }
  }

  void _onChatSocketTrayEvent(Map<String, dynamic> payload) {
    if ((payload['event'] ?? '').toString() != 'message.new') return;
    final data = payload['data'];
    if (data is! Map<String, dynamic>) return;
    try {
      final msg = ChatMessageModel.fromJson(data);
      unawaited(_maybeShowTrayForInboundSocketMessage(msg));
    } catch (_) {}
  }

  Future<void> _maybeShowTrayForInboundSocketMessage(ChatMessageModel msg) async {
    final me = (_tokenService.getUserId() ?? '').trim();
    if (me.isEmpty) return;
    if (msg.recipientId.trim() != me) return;
    if (msg.senderId.trim() == me) return;
    if (_chatUiStateService.shouldSuppressTrayForConversation(msg.idConversation)) {
      return;
    }
    if (!_shouldShowTrayForDedupe(msg.idMessage)) return;

    const title = 'Nuevo mensaje';
    final body = _trayBodyForChatMessage(msg);
    final payload = <String, dynamic>{
      'conversation_id': msg.idConversation.toString(),
      'sender_id': msg.senderId,
      'other_user_id': msg.senderId.trim(),
    };

    try {
      await _localNotifications.show(
        _resolveNotificationId(payload),
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _chatChannel.id,
            _chatChannel.name,
            channelDescription: _chatChannel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(payload),
      );
    } catch (e) {
      debugPrint('Chat push: notificación local (socket): $e');
    }
  }

  String _trayBodyForChatMessage(ChatMessageModel msg) {
    switch (msg.messageType) {
      case 'image':
        return 'Imagen';
      case 'video':
        return 'Video';
      default:
        final text = msg.content.trim();
        return text.isEmpty ? 'Tienes un mensaje nuevo' : text;
    }
  }

  bool _shouldShowTrayForDedupe(int messageId) {
    if (messageId <= 0) return true;
    final now = DateTime.now();
    _trayDedupeByMessageId.removeWhere(
      (_, t) => now.difference(t) > const Duration(seconds: 45),
    );
    if (_trayDedupeByMessageId.containsKey(messageId)) return false;
    _trayDedupeByMessageId[messageId] = now;
    return true;
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) {
          _openChatFromPayload(const {});
          return;
        }

        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            _openChatFromPayload(decoded);
            return;
          }
        } catch (_) {}

        _openChatFromPayload(const {});
      },
    );

    final androidPlatform = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlatform?.createNotificationChannel(_chatChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> _registerTokenWithBackend(String pushToken) async {
    final authToken = _tokenService.getToken();
    if (authToken == null || authToken.isEmpty) {
      debugPrint('Push chat: sesion sin token, no se sincroniza FCM.');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedToken = prefs.getString(_cachedPushTokenKey);
      final currentUserId = (_tokenService.getUserId() ?? '').trim();
      final cachedUserId = (prefs.getString(_cachedPushUserIdKey) ?? '').trim();

      if (cachedToken != null &&
          cachedToken.isNotEmpty &&
          cachedToken != pushToken) {
        try {
          await _chatApi.unregisterPushToken(cachedToken);
        } catch (e) {
          debugPrint('No fue posible eliminar push token anterior: $e');
        }
      }

      await _chatApi.registerPushToken(pushToken);
      await prefs.setString(_cachedPushTokenKey, pushToken);
      if (currentUserId.isNotEmpty && currentUserId != cachedUserId) {
        await prefs.setString(_cachedPushUserIdKey, currentUserId);
      }
      debugPrint(
        'Push chat: token FCM sincronizado para usuario ${currentUserId.isEmpty ? 'desconocido' : currentUserId}.',
      );
    } catch (e) {
      debugPrint('No fue posible sincronizar push token con backend: $e');
    }
  }

  Future<void> _clearCachedPushState(SharedPreferences prefs) async {
    await prefs.remove(_cachedPushTokenKey);
    await prefs.remove(_cachedPushUserIdKey);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final data = Map<String, dynamic>.from(message.data);
    final convId = int.tryParse((data['conversation_id'] ?? '').toString());
    if (convId != null &&
        _chatUiStateService.shouldSuppressTrayForConversation(convId)) {
      debugPrint(
        'Push chat: omitido (esa conversación está abierta en pantalla).',
      );
      return;
    }

    final senderId = (data['sender_id'] ?? '').toString().trim();
    final currentUserId = (_tokenService.getUserId() ?? '').trim();
    if (senderId.isNotEmpty && senderId == currentUserId) return;

    final dedupeId =
        int.tryParse((data['id_message'] ?? data['message_id'] ?? '').toString());
    if (dedupeId != null &&
        dedupeId > 0 &&
        !_shouldShowTrayForDedupe(dedupeId)) {
      return;
    }

    final title =
        message.notification?.title ??
        (data['title']?.toString().trim().isNotEmpty == true
            ? data['title'].toString().trim()
            : 'Nuevo mensaje');
    final body =
        message.notification?.body ??
        (data['body']?.toString().trim().isNotEmpty == true
            ? data['body'].toString().trim()
            : (data['content'] ?? 'Tienes un mensaje nuevo').toString());

    await _localNotifications.show(
      _resolveNotificationId(data),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _chatChannel.id,
          _chatChannel.name,
          channelDescription: _chatChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(data),
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    _openChatFromPayload(Map<String, dynamic>.from(message.data));
  }

  void _openChatFromPayload(Map<String, dynamic> data) {
    final navigator = _tokenService.navigatorKey.currentState;
    if (navigator == null) return;

    final otherUserId =
        (data['other_user_id'] ?? data['sender_id'] ?? '').toString().trim();
    final otherUserName = (data['other_user_name'] ?? '').toString().trim();
    final otherUserRole = (data['other_user_role'] ?? '').toString().trim();

    navigator.push(
      MaterialPageRoute(
        builder: (_) => ChatPage(
          initialOtherUserId: otherUserId.isEmpty ? null : otherUserId,
          initialOtherUserName: otherUserName.isEmpty ? null : otherUserName,
          initialOtherUserRole: otherUserRole.isEmpty ? null : otherUserRole,
        ),
      ),
    );
  }
}
