import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcom_app/core/chat/chat_api.service.dart';
import 'package:vcom_app/core/chat/chat_socket.service.dart';
import 'package:vcom_app/core/chat/chat_ui_state.service.dart';
import 'package:vcom_app/core/chat/chat_unread_badge.service.dart';
import 'package:vcom_app/core/common/firebase_env.dart';
import 'package:vcom_app/core/common/token.service.dart';
import 'package:vcom_app/core/models/chat/chat_message.model.dart';
import 'package:vcom_app/core/pwa/pwa_platform.dart';
import 'package:vcom_app/firebase_options.dart';
import 'package:vcom_app/pages/chat/chat.page.dart';

int resolveChatNotificationId(Map<String, dynamic> data) {
  final conversationId = (data['conversation_id'] ?? '').toString().trim();
  if (conversationId.isEmpty) {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
  return conversationId.hashCode;
}

bool _isWindowsDesktop() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

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
  final ChatUnreadBadgeService _unreadBadge = ChatUnreadBadgeService();
  final TokenService _tokenService = TokenService();

  bool _initialized = false;
  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<Map<String, dynamic>>? _socketTraySubscription;
  final Map<int, DateTime> _trayDedupeByMessageId = {};
  Map<String, dynamic>? _pendingDeepLink;
  String? _lastTraySignature;
  DateTime? _lastTrayAt;
  bool _appShellReady = false;

  /// El dashboard (u otra pantalla principal) ya está montado.
  void markAppShellReady() {
    _appShellReady = true;
    openPendingDeepLinkIfAny();
  }

  void markAppShellNotReady() {
    _appShellReady = false;
  }

  /// Abre el chat pendiente tras login o arranque desde notificación.
  void openPendingDeepLinkIfAny({int attempt = 0}) {
    final pending = _pendingDeepLink;
    if (pending == null || pending.isEmpty) return;

    if (!_tokenService.hasToken() || !_appShellReady) {
      if (attempt < 24) {
        Future<void>.delayed(const Duration(milliseconds: 300), () {
          openPendingDeepLinkIfAny(attempt: attempt + 1);
        });
      }
      return;
    }

    final snapshot = Map<String, dynamic>.from(pending);
    _pendingDeepLink = null;
    _pushChatRoute(snapshot);
  }

  void captureLaunchDeepLink() {
    if (!kIsWeb) return;

    final merged = <String, dynamic>{};
    for (final source in [Uri.base.queryParameters, _fragmentQueryParameters()]) {
      for (final entry in source.entries) {
        final value = entry.value.trim();
        if (value.isNotEmpty) {
          merged[entry.key] = value;
        }
      }
    }

    final normalized = _normalizeDeepLinkData(merged);
    if (normalized.isEmpty) return;
    _pendingDeepLink = normalized;
  }

  Future<void> initialize() async {
    await _tokenService.initialize();
    unawaited(_unreadBadge.refreshFromApi());

    if (kIsWeb) {
      await _initializeWebPush();
      return;
    }

    if (_isWindowsDesktop()) return;

    await _initializeNativePush();
  }

  Future<void> _initializeWebPush() async {
    captureLaunchDeepLink();

    if (!FirebaseEnv.isWebPushConfigured) {
      debugPrint(
        'Push web: configura FIREBASE_* y FIREBASE_VAPID_KEY con --dart-define.',
      );
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      debugPrint('Push web deshabilitado temporalmente: $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    if (!_initialized) {
      ChatSocketService.afterChatUiClosed =
          () => ChatPushService().resumeInboundSocketAfterChatClosed();
      _socketTraySubscription ??=
          ChatSocketService().events.listen(_onChatSocketTrayEvent);
      _onMessageSubscription = FirebaseMessaging.onMessage.listen(
        _handleWebForegroundMessage,
      );
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) => unawaited(_registerTokenWithBackend(token)),
      );
      listenNotificationClicks(_openChatFromPayload);
      _initialized = true;
    }

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Push web: permisos denegados por el usuario.');
      return;
    }

    await requestWebNotificationPermission();
    await ensureFcmServiceWorkerReady();

    final token = _tokenService.getToken();
    if (token == null || token.isEmpty) return;

    unawaited(resumeInboundSocketAfterChatClosed());

    try {
      final vapidKey = FirebaseEnv.vapidKey;
      if (vapidKey.isEmpty) {
        debugPrint('Push web: FIREBASE_VAPID_KEY vacía.');
        return;
      }

      String? fcmToken;
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          fcmToken = await messaging.getToken(vapidKey: vapidKey);
          break;
        } catch (e) {
          if (attempt >= 3) rethrow;
          debugPrint('Push web: reintento FCM token ($attempt/3): $e');
          await Future<void>.delayed(Duration(seconds: attempt));
        }
      }

      if (fcmToken != null && fcmToken.isNotEmpty) {
        debugPrint('FCM token web obtenido');
        await _registerTokenWithBackend(fcmToken);
      }
    } catch (e) {
      debugPrint('Push web: no se pudo obtener FCM token: $e');
      debugPrint(
        'Push web: revisa API key sin restricciones en Google Cloud '
        '(Credentials) y que VAPID sea del proyecto vcom-chat.',
      );
    }

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _storeDeepLinkFromRemoteMessage(initialMessage);
    }
    openPendingDeepLinkIfAny();
  }

  Future<void> _initializeNativePush() async {
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
    if (_isWindowsDesktop()) return;

    markAppShellNotReady();

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

  Future<void> resumeInboundSocketAfterChatClosed() async {
    if (_isWindowsDesktop()) return;

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
      final me = (_tokenService.getUserId() ?? '').trim();
      if (me.isNotEmpty &&
          msg.recipientId.trim() == me &&
          msg.senderId.trim() != me &&
          !_chatUiStateService.shouldSuppressTrayForConversation(
            msg.idConversation,
          )) {
        unawaited(_unreadBadge.refreshFromApi());
      }
    } catch (_) {}
  }

  Future<void> _maybeShowTrayForInboundSocketMessage(ChatMessageModel msg) async {
    // En web/PWA las notificaciones las envía FCM; el socket duplicaba bandeja.
    if (kIsWeb && FirebaseEnv.isWebPushConfigured) return;

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
      if (kIsWeb) {
        await showWebNotification(title: title, body: body, data: payload);
        return;
      }

      await _localNotifications.show(
        resolveChatNotificationId(payload),
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

  Future<void> _handleWebForegroundMessage(RemoteMessage message) async {
    unawaited(_unreadBadge.refreshFromApi());
    // Con la pestaña en segundo plano el service worker ya muestra la notificación.
    if (!isPageVisible) return;

    final data = Map<String, dynamic>.from(message.data);
    if (!_shouldDisplayTray(message, data)) return;

    final title = _resolveTitle(message, data);
    final body = _resolveBody(message, data);
    final signature = _traySignature(data, body);
    if (!_shouldShowTraySignature(signature)) return;

    await showWebNotification(title: title, body: body, data: data);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    unawaited(_unreadBadge.refreshFromApi());
    final data = Map<String, dynamic>.from(message.data);
    if (!_shouldDisplayTray(message, data)) return;

    final title = _resolveTitle(message, data);
    final body = _resolveBody(message, data);

    await _localNotifications.show(
      resolveChatNotificationId(data),
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

  bool _shouldDisplayTray(RemoteMessage message, Map<String, dynamic> data) {
    final convId = int.tryParse((data['conversation_id'] ?? '').toString());
    if (convId != null &&
        _chatUiStateService.shouldSuppressTrayForConversation(convId)) {
      debugPrint(
        'Push chat: omitido (esa conversación está abierta en pantalla).',
      );
      return false;
    }

    final senderId = (data['sender_id'] ?? '').toString().trim();
    final currentUserId = (_tokenService.getUserId() ?? '').trim();
    if (senderId.isNotEmpty && senderId == currentUserId) return false;

    final dedupeId =
        int.tryParse((data['id_message'] ?? data['message_id'] ?? '').toString());
    if (dedupeId != null &&
        dedupeId > 0 &&
        !_shouldShowTrayForDedupe(dedupeId)) {
      return false;
    }

    return true;
  }

  String _resolveTitle(RemoteMessage message, Map<String, dynamic> data) {
    return message.notification?.title ??
        (data['title']?.toString().trim().isNotEmpty == true
            ? data['title'].toString().trim()
            : 'Nuevo mensaje');
  }

  String _resolveBody(RemoteMessage message, Map<String, dynamic> data) {
    return message.notification?.body ??
        (data['body']?.toString().trim().isNotEmpty == true
            ? data['body']?.toString().trim() ?? ''
            : (data['content'] ?? 'Tienes un mensaje nuevo').toString());
  }

  void _handleMessageTap(RemoteMessage message) {
    _storeDeepLinkFromRemoteMessage(message);
    openPendingDeepLinkIfAny();
  }

  void _storeDeepLinkFromRemoteMessage(RemoteMessage message) {
    final data = Map<String, dynamic>.from(message.data);
    if (message.notification?.title != null && data['title'] == null) {
      data['title'] = message.notification!.title;
    }
    if (message.notification?.body != null && data['body'] == null) {
      data['body'] = message.notification!.body;
    }
    final normalized = _normalizeDeepLinkData(data);
    if (normalized.isEmpty) {
      debugPrint('Push chat: mensaje sin datos de conversación: $data');
      return;
    }
    _pendingDeepLink = normalized;
  }

  Map<String, dynamic> _normalizeDeepLinkData(Map<String, dynamic> raw) {
    final normalized = <String, dynamic>{};

    final conversationId = _firstNonEmptyString(raw, const [
      'conversation_id',
      'id_conversation',
      'conversationId',
    ]);
    if (conversationId != null) {
      normalized['conversation_id'] = conversationId;
    }

    final senderId = _firstNonEmptyString(raw, const [
      'sender_id',
      'senderId',
      'user_id',
      'from_user_id',
    ]);
    if (senderId != null) normalized['sender_id'] = senderId;

    final otherUserId = _firstNonEmptyString(raw, const [
      'other_user_id',
      'otherUserId',
    ]);
    if (otherUserId != null) {
      normalized['other_user_id'] = otherUserId;
    } else if (senderId != null) {
      normalized['other_user_id'] = senderId;
    }

    final otherUserName = _firstNonEmptyString(raw, const [
      'other_user_name',
      'otherUserName',
      'sender_name',
      'user_name',
    ]);
    if (otherUserName != null) {
      normalized['other_user_name'] = otherUserName;
    }

    final otherUserRole = _firstNonEmptyString(raw, const [
      'other_user_role',
      'otherUserRole',
      'sender_role',
      'role_user',
    ]);
    if (otherUserRole != null) {
      normalized['other_user_role'] = otherUserRole;
    }

    return normalized;
  }

  String? _firstNonEmptyString(
    Map<String, dynamic> raw,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = (raw[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  Map<String, String> _fragmentQueryParameters() {
    final fragment = Uri.base.fragment.trim();
    if (fragment.isEmpty) return const {};

    final queryPart = fragment.contains('?')
        ? fragment.split('?').last
        : fragment;
    try {
      return Uri.splitQueryString(queryPart);
    } catch (_) {
      return const {};
    }
  }

  String _traySignature(Map<String, dynamic> data, String body) {
    final conversationId = (data['conversation_id'] ?? '').toString();
    final messageId =
        (data['id_message'] ?? data['message_id'] ?? '').toString();
    return '$conversationId|$messageId|${body.trim()}';
  }

  bool _shouldShowTraySignature(String signature) {
    final now = DateTime.now();
    if (_lastTraySignature == signature &&
        _lastTrayAt != null &&
        now.difference(_lastTrayAt!) < const Duration(seconds: 8)) {
      return false;
    }
    _lastTraySignature = signature;
    _lastTrayAt = now;
    return true;
  }

  void _openChatFromPayload(Map<String, dynamic> data) {
    final normalized = _normalizeDeepLinkData(data);
    if (normalized.isEmpty) {
      debugPrint('Push chat: click sin datos de conversación: $data');
      return;
    }

    if (!_tokenService.hasToken() || !_appShellReady) {
      _pendingDeepLink = normalized;
      openPendingDeepLinkIfAny();
      return;
    }

    _pushChatRoute(normalized);
  }

  void _pushChatRoute(Map<String, dynamic> normalized) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _tokenService.navigatorKey.currentState;
      if (navigator == null) {
        _pendingDeepLink = normalized;
        openPendingDeepLinkIfAny();
        return;
      }

      final conversationId =
          int.tryParse((normalized['conversation_id'] ?? '').toString());
      final otherUserId =
          (normalized['other_user_id'] ?? normalized['sender_id'] ?? '')
              .toString()
              .trim();
      if (conversationId == null && otherUserId.isEmpty) return;

      final otherUserName =
          (normalized['other_user_name'] ?? '').toString().trim();
      final otherUserRole =
          (normalized['other_user_role'] ?? '').toString().trim();

      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            initialConversationId: conversationId,
            initialOtherUserId: otherUserId.isEmpty ? null : otherUserId,
            initialOtherUserName:
                otherUserName.isEmpty ? null : otherUserName,
            initialOtherUserRole:
                otherUserRole.isEmpty ? null : otherUserRole,
          ),
        ),
      );
    });
  }
}
