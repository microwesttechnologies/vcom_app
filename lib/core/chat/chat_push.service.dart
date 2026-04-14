import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcom_app/core/chat/chat_api.service.dart';
import 'package:vcom_app/core/chat/chat_ui_state.service.dart';
import 'package:vcom_app/core/common/app_routes.dart';
import 'package:vcom_app/core/common/token.service.dart';

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
  const initSettings = InitializationSettings(android: androidSettings);
  await _backgroundLocalNotifications.initialize(initSettings);

  final androidPlatform = _backgroundLocalNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();
  await androidPlatform?.createNotificationChannel(_backgroundChatChannel);
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

  Future<void> initialize() async {
    if (kIsWeb) return;

    await _tokenService.initialize();

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Push chat deshabilitado temporalmente: $e');
      return;
    }
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;

    if (!_initialized) {
      await _configureLocalNotifications();
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

    final fcmToken = await messaging.getToken();
    if (fcmToken != null && fcmToken.isNotEmpty) {
      debugPrint('FCM token obtenido: $fcmToken');
      await _registerTokenWithBackend(fcmToken);
    }

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  Future<void> unregisterCurrentDevice() async {
    if (kIsWeb) return;

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
    await _onMessageSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    _onMessageSubscription = null;
    _tokenRefreshSubscription = null;
    _initialized = false;
  }

  Future<void> _configureLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
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
    if (_chatUiStateService.isInChatModule) {
      return;
    }

    final data = Map<String, dynamic>.from(message.data);
    final senderId = (data['sender_id'] ?? '').toString().trim();
    final currentUserId = (_tokenService.getUserId() ?? '').trim();
    if (senderId.isNotEmpty && senderId == currentUserId) return;

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

    final otherUserId = (data['other_user_id'] ?? '').toString().trim();
    final otherUserName = (data['other_user_name'] ?? '').toString().trim();
    final otherUserRole = (data['other_user_role'] ?? '').toString().trim();

    navigator.pushNamed(
      AppRoutes.chat,
      arguments: <String, String?>{
        AppRoutes.chatArgOtherUserId: otherUserId.isEmpty ? null : otherUserId,
        AppRoutes.chatArgOtherUserName: otherUserName.isEmpty
            ? null
            : otherUserName,
        AppRoutes.chatArgOtherUserRole: otherUserRole.isEmpty
            ? null
            : otherUserRole,
      },
    );
  }
}
